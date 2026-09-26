"""
설문 관리자 기능: 설문 기본정보 / 문항 / 선택지 / 대상자 / 응답조회.

기사(driver) 대상 응답 화면 로직은 기존대로 baechaweb.py 에 남겨두고,
이 파일은 "관리자가 설문을 만들고 관리하는" 기능만 담당합니다.
"""
from flask import redirect, render_template, request, url_for

from .baechaweb import get_db

STATUS_LABELS = {0: "개발중", 1: "진행중", 2: "관리중(마감)", 3: "종료"}


# ---------------------------------------------------------------------------
# 설문 목록 / 기본정보 CRUD
# ---------------------------------------------------------------------------

def survey_list():
    conn = get_db()
    try:
        surveys = conn.execute(
            """
            SELECT survey_id, survey_title, survey_subtitle, status,
                   created_at, updated_at
            FROM survey_master
            ORDER BY survey_id DESC
            """
        ).fetchall()
    finally:
        conn.close()

    return render_template(
        "admin/survey_list.html", surveys=surveys, status_labels=STATUS_LABELS
    )


def survey_new_form():
    return render_template(
        "admin/survey_form.html", survey=None, status_labels=STATUS_LABELS, error=None
    )


def survey_create():
    title = request.form.get("survey_title", "").strip()
    subtitle = request.form.get("survey_subtitle", "").strip()
    description = request.form.get("description", "")
    status = int(request.form.get("status", 0))

    if not title:
        return render_template(
            "admin/survey_form.html",
            survey=None,
            status_labels=STATUS_LABELS,
            error="설문 제목은 필수입니다.",
        ), 400

    conn = get_db()
    try:
        conn.execute("BEGIN")
        if status == 1:
            # 활성 설문은 동시에 1개만 가능하므로 기존 활성 설문을 먼저 내린다
            conn.execute("UPDATE survey_master SET status = 2 WHERE status = 1")

        cur = conn.execute(
            """
            INSERT INTO survey_master
                (survey_title, survey_subtitle, description, status, created_at)
            VALUES (?, ?, ?, ?, CURRENT_TIMESTAMP)
            """,
            (title, subtitle, description, status),
        )
        new_id = cur.lastrowid

        if status == 1:
            _link_all_drivers(conn, new_id)

        conn.commit()
    except Exception:
        conn.rollback()
        raise
    finally:
        conn.close()

    return redirect(url_for("admin_survey_questions", survey_id=new_id))


def survey_edit_form(survey_id):
    conn = get_db()
    try:
        survey = conn.execute(
            "SELECT * FROM survey_master WHERE survey_id = ?", (survey_id,)
        ).fetchone()
    finally:
        conn.close()

    if survey is None:
        return "설문을 찾을 수 없습니다.", 404

    return render_template(
        "admin/survey_form.html", survey=survey, status_labels=STATUS_LABELS, error=None
    )


def survey_update(survey_id):
    title = request.form.get("survey_title", "").strip()
    subtitle = request.form.get("survey_subtitle", "").strip()
    description = request.form.get("description", "")
    status = int(request.form.get("status", 0))

    if not title:
        return "설문 제목은 필수입니다.", 400

    conn = get_db()
    try:
        conn.execute("BEGIN")

        if status == 1:
            conn.execute(
                "UPDATE survey_master SET status = 2 WHERE status = 1 AND survey_id != ?",
                (survey_id,),
            )

        conn.execute(
            """
            UPDATE survey_master
            SET survey_title = ?, survey_subtitle = ?, description = ?,
                status = ?, updated_at = CURRENT_TIMESTAMP
            WHERE survey_id = ?
            """,
            (title, subtitle, description, status, survey_id),
        )

        if status == 1:
            _link_all_drivers(conn, survey_id)

        conn.commit()
    except Exception:
        conn.rollback()
        raise
    finally:
        conn.close()

    return redirect(url_for("admin_survey_list"))


def survey_delete(survey_id):
    # 삭제 확인창은 화면(JS confirm)에서 이미 거쳤다는 전제입니다.
    # get_db() 에서 PRAGMA foreign_keys = ON 이 설정되어 있으므로
    # 질문/선택지/대상자연결/응답이 함께 CASCADE 삭제됩니다.
    conn = get_db()
    try:
        conn.execute("DELETE FROM survey_master WHERE survey_id = ?", (survey_id,))
        conn.commit()
    finally:
        conn.close()

    return redirect(url_for("admin_survey_list"))


def _link_all_drivers(conn, survey_id):
    """설문이 활성화될 때 현재 등록된 모든 기사를 대상자로 연결한다.
    이미 연결된 기사는 건너뛴다 (기존 응답 데이터 보존)."""
    conn.execute(
        """
        INSERT INTO drivers_survey_link (driver_name, survey_id, completed)
        SELECT name, ?, 0
        FROM drivers
        WHERE name NOT IN (
            SELECT driver_name FROM drivers_survey_link WHERE survey_id = ?
        )
        """,
        (survey_id, survey_id),
    )


# ---------------------------------------------------------------------------
# 문항 관리
# ---------------------------------------------------------------------------

def question_list(survey_id):
    conn = get_db()
    try:
        survey = conn.execute(
            "SELECT * FROM survey_master WHERE survey_id = ?", (survey_id,)
        ).fetchone()

        if survey is None:
            return "설문을 찾을 수 없습니다.", 404

        questions = conn.execute(
            """
            SELECT question_no, question_text, question_type, is_required, sort_order
            FROM survey_questions
            WHERE survey_id = ?
            ORDER BY sort_order, question_no
            """,
            (survey_id,),
        ).fetchall()

        options_by_question = {}
        for q in questions:
            opts = conn.execute(
                """
                SELECT option_no, option_text, sort_order
                FROM survey_options
                WHERE survey_id = ? AND question_no = ?
                ORDER BY sort_order, option_no
                """,
                (survey_id, q["question_no"]),
            ).fetchall()
            options_by_question[q["question_no"]] = opts
    finally:
        conn.close()

    return render_template(
        "admin/survey_questions.html",
        survey=survey,
        questions=questions,
        options_by_question=options_by_question,
    )


def question_create(survey_id):
    text = request.form.get("question_text", "").strip()
    qtype = request.form.get("question_type", "single")
    is_required = 1 if request.form.get("is_required") else 0

    if not text:
        return "질문 내용은 필수입니다.", 400
    if qtype not in ("single", "multi", "text"):
        return "질문 유형이 올바르지 않습니다.", 400

    conn = get_db()
    try:
        row = conn.execute(
            """
            SELECT COALESCE(MAX(question_no), 0) AS max_no,
                   COALESCE(MAX(sort_order), 0) AS max_sort
            FROM survey_questions WHERE survey_id = ?
            """,
            (survey_id,),
        ).fetchone()
        next_no = row["max_no"] + 1
        next_sort = row["max_sort"] + 10

        conn.execute(
            """
            INSERT INTO survey_questions
                (survey_id, question_no, question_text, question_type, is_required, sort_order)
            VALUES (?, ?, ?, ?, ?, ?)
            """,
            (survey_id, next_no, text, qtype, is_required, next_sort),
        )
        conn.commit()
    finally:
        conn.close()

    return redirect(url_for("admin_survey_questions", survey_id=survey_id))


def question_update(survey_id, question_no):
    text = request.form.get("question_text", "").strip()
    qtype = request.form.get("question_type", "single")
    is_required = 1 if request.form.get("is_required") else 0

    if not text:
        return "질문 내용은 필수입니다.", 400

    conn = get_db()
    try:
        conn.execute(
            """
            UPDATE survey_questions
            SET question_text = ?, question_type = ?, is_required = ?
            WHERE survey_id = ? AND question_no = ?
            """,
            (text, qtype, is_required, survey_id, question_no),
        )
        conn.commit()
    finally:
        conn.close()

    return redirect(url_for("admin_survey_questions", survey_id=survey_id))


def question_delete(survey_id, question_no):
    conn = get_db()
    try:
        conn.execute(
            "DELETE FROM survey_questions WHERE survey_id = ? AND question_no = ?",
            (survey_id, question_no),
        )
        conn.commit()
    finally:
        conn.close()

    return redirect(url_for("admin_survey_questions", survey_id=survey_id))


def question_reorder(survey_id):
    """화면에서 넘어온 (question_no, sort_order) 쌍을 일괄 반영."""
    question_nos = request.form.getlist("question_no")
    sort_orders = request.form.getlist("sort_order")

    conn = get_db()
    try:
        conn.execute("BEGIN")
        for qno, order in zip(question_nos, sort_orders):
            conn.execute(
                """
                UPDATE survey_questions SET sort_order = ?
                WHERE survey_id = ? AND question_no = ?
                """,
                (int(order), survey_id, int(qno)),
            )
        conn.commit()
    except Exception:
        conn.rollback()
        raise
    finally:
        conn.close()

    return redirect(url_for("admin_survey_questions", survey_id=survey_id))


# ---------------------------------------------------------------------------
# 선택지 관리
# ---------------------------------------------------------------------------

def option_create(survey_id, question_no):
    text = request.form.get("option_text", "").strip()
    if not text:
        return "선택지 내용은 필수입니다.", 400

    conn = get_db()
    try:
        row = conn.execute(
            """
            SELECT COALESCE(MAX(option_no), 0) AS max_no,
                   COALESCE(MAX(sort_order), 0) AS max_sort
            FROM survey_options WHERE survey_id = ? AND question_no = ?
            """,
            (survey_id, question_no),
        ).fetchone()
        next_no = row["max_no"] + 1
        next_sort = row["max_sort"] + 10

        conn.execute(
            """
            INSERT INTO survey_options (survey_id, question_no, option_no, option_text, sort_order)
            VALUES (?, ?, ?, ?, ?)
            """,
            (survey_id, question_no, next_no, text, next_sort),
        )
        conn.commit()
    finally:
        conn.close()

    return redirect(url_for("admin_survey_questions", survey_id=survey_id))


def option_update(survey_id, question_no, option_no):
    text = request.form.get("option_text", "").strip()
    if not text:
        return "선택지 내용은 필수입니다.", 400

    conn = get_db()
    try:
        conn.execute(
            """
            UPDATE survey_options SET option_text = ?
            WHERE survey_id = ? AND question_no = ? AND option_no = ?
            """,
            (text, survey_id, question_no, option_no),
        )
        conn.commit()
    finally:
        conn.close()

    return redirect(url_for("admin_survey_questions", survey_id=survey_id))


def option_delete(survey_id, question_no, option_no):
    conn = get_db()
    try:
        conn.execute(
            """
            DELETE FROM survey_options
            WHERE survey_id = ? AND question_no = ? AND option_no = ?
            """,
            (survey_id, question_no, option_no),
        )
        conn.commit()
    finally:
        conn.close()

    return redirect(url_for("admin_survey_questions", survey_id=survey_id))


def option_reorder(survey_id, question_no):
    option_nos = request.form.getlist("option_no")
    sort_orders = request.form.getlist("sort_order")

    conn = get_db()
    try:
        conn.execute("BEGIN")
        for ono, order in zip(option_nos, sort_orders):
            conn.execute(
                """
                UPDATE survey_options SET sort_order = ?
                WHERE survey_id = ? AND question_no = ? AND option_no = ?
                """,
                (int(order), survey_id, question_no, int(ono)),
            )
        conn.commit()
    except Exception:
        conn.rollback()
        raise
    finally:
        conn.close()

    return redirect(url_for("admin_survey_questions", survey_id=survey_id))


# ---------------------------------------------------------------------------
# 미리보기 / 응답 조회
# ---------------------------------------------------------------------------

def survey_preview(survey_id):
    conn = get_db()
    try:
        survey = conn.execute(
            "SELECT * FROM survey_master WHERE survey_id = ?", (survey_id,)
        ).fetchone()

        if survey is None:
            return "설문을 찾을 수 없습니다.", 404

        questions = conn.execute(
            """
            SELECT question_no, question_text, question_type, is_required
            FROM survey_questions
            WHERE survey_id = ?
            ORDER BY sort_order, question_no
            """,
            (survey_id,),
        ).fetchall()

        options_by_question = {}
        for q in questions:
            opts = conn.execute(
                """
                SELECT option_no, option_text
                FROM survey_options
                WHERE survey_id = ? AND question_no = ?
                ORDER BY sort_order, option_no
                """,
                (survey_id, q["question_no"]),
            ).fetchall()
            options_by_question[q["question_no"]] = opts
    finally:
        conn.close()

    return render_template(
        "admin/survey_preview.html",
        survey=survey,
        questions=questions,
        options_by_question=options_by_question,
    )


def survey_responses(survey_id):
    conn = get_db()
    try:
        survey = conn.execute(
            "SELECT * FROM survey_master WHERE survey_id = ?", (survey_id,)
        ).fetchone()

        if survey is None:
            return "설문을 찾을 수 없습니다.", 404

        rows = conn.execute(
            """
            SELECT
                d.name AS driver_name,
                dsl.completed,
                dsl.answer_date,
                sq.question_no,
                sq.question_text,
                sq.question_type,
                sa.option_no,
                so.option_text,
                sa.answer_text
            FROM drivers_survey_link dsl
            JOIN drivers d ON d.name = dsl.driver_name
            JOIN survey_questions sq ON sq.survey_id = dsl.survey_id
            LEFT JOIN survey_answers sa
                ON sa.driver_name = d.name
                AND sa.survey_id = dsl.survey_id
                AND sa.question_no = sq.question_no
            LEFT JOIN survey_options so
                ON so.survey_id = sa.survey_id
                AND so.question_no = sa.question_no
                AND so.option_no = sa.option_no
            WHERE dsl.survey_id = ?
            ORDER BY d.name, sq.sort_order, sq.question_no
            """,
            (survey_id,),
        ).fetchall()
    finally:
        conn.close()

    responses = {}
    for r in rows:
        responses.setdefault(r["driver_name"], []).append(r)

    return render_template("admin/survey_responses.html", survey=survey, responses=responses)
