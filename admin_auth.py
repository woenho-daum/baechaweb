"""
관리자 화면 접근을 위한 간단한 비밀번호 + 세션 인증.

운영 환경에서는 반드시 아래 두 값을 환경변수로 교체하세요.
    - BAECHAWEB_ADMIN_PASSWORD (관리자 비밀번호)
    - BAECHAWEB_FLASK_SECRET   (Flask 세션 서명 키, main.py 의 app.secret_key)
"""
import functools
import os

from flask import redirect, render_template, request, session, url_for

ADMIN_PASSWORD = os.environ.get("BAECHAWEB_ADMIN_PASSWORD", "change-this-password")


def login():
    if request.method == "POST":
        password = request.form.get("password", "")
        if password == ADMIN_PASSWORD:
            session["is_admin"] = True
            next_url = request.args.get("next") or url_for("admin_survey_list")
            return redirect(next_url)
        return render_template(
            "admin/login.html", error="비밀번호가 올바르지 않습니다."
        )

    return render_template("admin/login.html", error=None)


def logout():
    session.pop("is_admin", None)
    return redirect(url_for("admin_login"))


def login_required(view_func):
    @functools.wraps(view_func)
    def wrapped(*args, **kwargs):
        if not session.get("is_admin"):
            return redirect(url_for("admin_login", next=request.path))
        return view_func(*args, **kwargs)

    return wrapped
