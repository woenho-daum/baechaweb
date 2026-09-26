import os

from flask import Flask, make_response, render_template  # type: ignore

from baechaweb import admin_auth, auth, entry, survey, survey_admin

app = Flask(__name__)

# 관리자 로그인 세션(쿠키 서명)에 사용됩니다.
# 운영 환경에서는 반드시 환경변수로 안전하게 관리하세요.
app.secret_key = os.environ.get("BAECHAWEB_FLASK_SECRET", "change-this-flask-secret")


@app.route("/")
def intro():
    response = make_response(
        render_template("baecha_intro.html")
    )

    # 기존 JWT 삭제
    response.delete_cookie("access_token")

    return response

@app.route("/baechaweb", methods=["GET"])
def baechaweb():
    response = make_response(entry())
    # 기존 JWT 삭제
    response.delete_cookie("access_token")

    return response

@app.route("/baechaweb/auth", methods=["POST"])
def baechaweb_auth():
    return auth()

@app.route("/baechaweb/survey", methods=["GET","POST"])
def baechaweb_survey():
    return survey()


# ---------------------------------------------------------------------------
# 관리자 - 로그인 / 로그아웃
# ---------------------------------------------------------------------------

@app.route("/admin/login", methods=["GET", "POST"])
def admin_login():
    return admin_auth.login()


@app.route("/admin/logout")
def admin_logout():
    return admin_auth.logout()


# ---------------------------------------------------------------------------
# 관리자 - 설문 목록 / 기본정보 CRUD
# ---------------------------------------------------------------------------

@app.route("/admin/surveys")
@admin_auth.login_required
def admin_survey_list():
    return survey_admin.survey_list()


@app.route("/admin/surveys/new", methods=["GET"])
@admin_auth.login_required
def admin_survey_new_form():
    return survey_admin.survey_new_form()


@app.route("/admin/surveys", methods=["POST"])
@admin_auth.login_required
def admin_survey_create():
    return survey_admin.survey_create()


@app.route("/admin/surveys/<int:survey_id>/edit", methods=["GET"])
@admin_auth.login_required
def admin_survey_edit_form(survey_id):
    return survey_admin.survey_edit_form(survey_id)


@app.route("/admin/surveys/<int:survey_id>", methods=["POST"])
@admin_auth.login_required
def admin_survey_update(survey_id):
    return survey_admin.survey_update(survey_id)


@app.route("/admin/surveys/<int:survey_id>/delete", methods=["POST"])
@admin_auth.login_required
def admin_survey_delete(survey_id):
    return survey_admin.survey_delete(survey_id)


# ---------------------------------------------------------------------------
# 관리자 - 문항 관리
# ---------------------------------------------------------------------------

@app.route("/admin/surveys/<int:survey_id>/questions", methods=["GET"])
@admin_auth.login_required
def admin_survey_questions(survey_id):
    return survey_admin.question_list(survey_id)


@app.route("/admin/surveys/<int:survey_id>/questions", methods=["POST"])
@admin_auth.login_required
def admin_question_create(survey_id):
    return survey_admin.question_create(survey_id)


@app.route("/admin/surveys/<int:survey_id>/questions/<int:question_no>", methods=["POST"])
@admin_auth.login_required
def admin_question_update(survey_id, question_no):
    return survey_admin.question_update(survey_id, question_no)


@app.route("/admin/surveys/<int:survey_id>/questions/<int:question_no>/delete", methods=["POST"])
@admin_auth.login_required
def admin_question_delete(survey_id, question_no):
    return survey_admin.question_delete(survey_id, question_no)


@app.route("/admin/surveys/<int:survey_id>/questions/reorder", methods=["POST"])
@admin_auth.login_required
def admin_question_reorder(survey_id):
    return survey_admin.question_reorder(survey_id)


# ---------------------------------------------------------------------------
# 관리자 - 선택지 관리
# ---------------------------------------------------------------------------

@app.route(
    "/admin/surveys/<int:survey_id>/questions/<int:question_no>/options",
    methods=["POST"],
)
@admin_auth.login_required
def admin_option_create(survey_id, question_no):
    return survey_admin.option_create(survey_id, question_no)


@app.route(
    "/admin/surveys/<int:survey_id>/questions/<int:question_no>/options/<int:option_no>",
    methods=["POST"],
)
@admin_auth.login_required
def admin_option_update(survey_id, question_no, option_no):
    return survey_admin.option_update(survey_id, question_no, option_no)


@app.route(
    "/admin/surveys/<int:survey_id>/questions/<int:question_no>/options/<int:option_no>/delete",
    methods=["POST"],
)
@admin_auth.login_required
def admin_option_delete(survey_id, question_no, option_no):
    return survey_admin.option_delete(survey_id, question_no, option_no)


@app.route(
    "/admin/surveys/<int:survey_id>/questions/<int:question_no>/options/reorder",
    methods=["POST"],
)
@admin_auth.login_required
def admin_option_reorder(survey_id, question_no):
    return survey_admin.option_reorder(survey_id, question_no)


# ---------------------------------------------------------------------------
# 관리자 - 미리보기 / 응답 조회
# ---------------------------------------------------------------------------

@app.route("/admin/surveys/<int:survey_id>/preview")
@admin_auth.login_required
def admin_survey_preview(survey_id):
    return survey_admin.survey_preview(survey_id)


@app.route("/admin/surveys/<int:survey_id>/responses")
@admin_auth.login_required
def admin_survey_responses(survey_id):
    return survey_admin.survey_responses(survey_id)


if __name__ == "__main__":
    app.run(debug=True)
