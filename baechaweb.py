import sqlite3

from flask import render_template, request, jsonify


DB_PATH = "./sqlite/survey.db"


def get_db():
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    return conn


def entry():
    """
    /baechaweb 진입 화면

    survey_master에서 survey_id=1인 설문을 읽어서
    화면에 표시한다.
    """

    conn = get_db()

    try:
        survey = conn.execute("""
            SELECT
                survey_id,
                survey_title,
                description,
                is_active
            FROM survey_master
            WHERE survey_id = 1
        """).fetchone()

    finally:
        conn.close()

    if survey is None:
        return "설문 정보를 찾을 수 없습니다.", 404

    return render_template(
        "baechaweb.html",
        survey=survey
    )


def login():
    """
    /baechaweb/login

    POST JSON:
    {
        "phone": "01012345678"
    }
    """

    data = request.get_json(silent=True) or {}

    phone = data.get("phone", "").strip()

    # 숫자 이외의 문자가 들어와도 서버에서는 제거
    phone = "".join(ch for ch in phone if ch.isdigit())

    if not phone:
        return jsonify({
            "success": False,
            "message": "전화번호를 입력해 주세요."
        }), 400

    conn = get_db()

    try:
        driver = conn.execute("""
            SELECT
                name,
                phone,
                shift_day,
                off_day,
                childcare_day
            FROM drivers
            WHERE phone = ?
        """, (phone,)).fetchone()

    finally:
        conn.close()

    if driver is None:
        return jsonify({
            "success": False,
            "message": "등록된 전화번호를 찾을 수 없습니다."
        }), 404

    return jsonify({
        "success": True,
        "name": driver["name"],
        "phone": driver["phone"]
    })

def survey():
    """
    /baechaweb/survey

    POST JSON:
    {
        "phone": "01012345678"
    }
    """

    data = request.get_json(silent=True) or {}

    phone = data.get("phone", "").strip()

    # 숫자 이외의 문자가 들어와도 서버에서는 제거
    phone = "".join(ch for ch in phone if ch.isdigit())

    if not phone:
        return jsonify({
            "success": False,
            "message": "전화번호를 입력해 주세요."
        }), 400

    conn = get_db()

    try:
        # 설문 응답 저장 로직 추가
        pass
    finally:
        conn.close()

    return jsonify({
        "success": True,
        "message": "설문이 성공적으로 제출되었습니다."
    })
