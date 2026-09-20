import datetime
import sqlite3

import jwt  # type: ignore # 추가 필요: pip install PyJWT
from flask import jsonify, make_response, render_template, request  # type: ignore

DB_PATH = "./sqlite/survey.db"
SECRET_KEY = "your-very-secret-key-change-this"  # 안전한 비밀키로 변경하세요


def get_db():
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    return conn


def entry():
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

    return render_template("baechaweb.html", survey=survey)


def auth():
    data = request.get_json(silent=True) or {}
    phone = data.get("phone", "").strip()
    phone = "".join(ch for ch in phone if ch.isdigit())

    if not phone:
        return jsonify({"success": False, "message": "전화번호를 입력해 주세요."}), 400

    conn = get_db()
    try:
        driver = conn.execute(
            """
            SELECT 
                name, 
                phone, 
                dsl.completed, 
                dsl.answer_date 
            FROM drivers  
            inner JOIN drivers_survey_link dsl 
            ON name = dsl.driver_name 
            WHERE phone = ?
            """,
            (phone,),
        ).fetchone()
    finally:
        conn.close()

    if driver is None:
        return jsonify(
            {"success": False, "message": "등록된 전화번호를 찾을 수 없습니다."}
        ), 404

    # 1. 인증 성공 시 JWT 토큰 생성 (유효기간: 2시간)
    payload = {
        "phone": driver["phone"],
        "name": driver["name"],
        "exp": datetime.datetime.utcnow() + datetime.timedelta(hours=2),  # noqa: DTZ003
    }
    token = jwt.encode(payload, SECRET_KEY, algorithm="HS256")

    # 2. JSON 응답 생성
    response_data = {
        "success": True,
        "name": driver["name"],
        "phone": driver["phone"],
        "completed": driver["completed"],
        "answer_date": driver["answer_date"],
    }

    resp = make_response(jsonify(response_data))

    # 3. 브라우저 쿠키에 JWT 토큰 설정 (HttpOnly로 보안 강화)
    resp.set_cookie(
        "access_token", token, httponly=True, secure=False
    )  # HTTPS 환경인 경우 secure=True로 설정

    return resp


def survey():
    """/baechaweb/survey

    세션/쿠키에 담긴 JWT 토큰을 검증하여 인증된 사용자만 접근 허용
    """
    # 쿠키에서 JWT 토큰 가져오기
    token = request.cookies.get("access_token")

    if not token:
        return jsonify(
            {
                "success": False,
                "message": "인증 정보가 없습니다. 다시 로그인해 주세요.",
            }
        ), 401

    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=["HS256"])
        phone = payload["phone"]
    except (jwt.ExpiredSignatureError, jwt.InvalidTokenError):
        return "유효하지 않거나 만료된 인증 정보입니다. 다시 로그인해 주세요.", 401

    # 필요하다면 DB에서 설문 데이터 조회
    conn = get_db()
    try:
        driver = conn.execute(
            """
            SELECT 
                name, 
                phone, 
                dsl.completed, 
                dsl.answer_date 
            FROM drivers  
            inner JOIN drivers_survey_link dsl 
            ON name = dsl.driver_name 
            WHERE phone = ?
            """,
            (phone,),
        ).fetchone()
    finally:
        conn.close()

    if driver is None:
        return "사용자 정보를 찾을 수 없습니다.", 404

    if driver["completed"] == "1":
        return "이미 설문을 완료하였습니다.", 405
    
    # JSON 대신 실제 설문조사 HTML 페이지를 렌더링하여 반환
    # return render_template("survey_form.html", driver=driver)

    # 검증된 전화번호를 바탕으로 DB 조회 수행
    conn = get_db()
    try:
        driver = conn.execute(
            """
            SELECT 
                name, 
                phone, 
                shift_day, 
                off_day, 
                childcare_day 
            FROM drivers 
            WHERE phone = ?
        """,
            (phone,),
        ).fetchone()
    finally:
        conn.close()

    if driver is None:
        return jsonify(
            {"success": False, "message": "등록된 전화번호를 찾을 수 없습니다."}
        ), 404

    return jsonify({"success": True, "name": driver["name"], "phone": driver["phone"]})
