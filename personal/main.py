import sqlite3
from flask import Flask, render_template, request, redirect, url_for, make_response

app = Flask(__name__)

# 1. 인트로 화면
@app.route('/')
def index():
    return render_template('intro.html')

# 3. 로그인 화면 (GET) 및 로그인 처리 (POST)
@app.route('/login', methods=['GET', 'POST'])
def login():
    if request.method == 'POST':
        phone = request.form.get('phone', '').strip().replace('-', '')
        driver_name = get_driver_name(phone)
        
        if driver_name:
            # 전화번호가 등록되어 있으면 성명 확인 화면으로 이동
            return render_template('confirm.html', phone=phone, name=driver_name)
        else:
            # 등록되지 않은 경우 경고 메시지와 함께 로그인 화면 재호출
            return render_template('login.html', error_msg="등록되지 않은 전화번호입니다. 다시 입력해주세요.")
            
    return render_template('login.html')

# 5. 본인 확인 완료 후 쿠키 저장 및 설문 1로 이동
@app.route('/confirm_user', methods=['POST'])
def confirm_user():
    phone = request.form.get('phone')
    name = request.form.get('name')
    
    # 다음 단계인 /Survey_01 로 리다이렉트 (쿠키 설정)
    resp = make_response(redirect(url_for('survey_01')))
    resp.set_cookie('user_phone', phone)
    resp.set_cookie('user_name', name)
    return resp


# 설문 1 화면 
@app.route('/survey_01')
def survey_01():
    user_name = request.cookies.get('user_name')
    if not user_name:
        return redirect(url_for('login'))
    return f"<h1>안녕하세요 {user_name} 기사님!</h1><p style='font-size:24px;'>설문지 1번 화면입니다. (추후 구현)</p>"


# SQLite에서 전화번호로 성명 조회하는 함수
def get_driver_name(phone):
    conn = sqlite3.connect('drivers.db')
    cursor = conn.cursor()
    cursor.execute("SELECT name FROM drivers WHERE phone = ?", (phone,))
    result = cursor.fetchone()
    conn.close()
    return result[0] if result else None


# DB 초기화 함수 (테스트용 데이터 생성)
def init_db():
    conn = sqlite3.connect('drivers.db')
    cursor = conn.cursor()
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS drivers (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            phone TEXT UNIQUE NOT NULL,
            name TEXT NOT NULL
        )
    ''')
    # 테스트용 샘플 데이터 입력 (필요시 수정)
    cursor.execute("INSERT OR IGNORE INTO drivers (phone, name) VALUES ('01012345678', '홍길동')")
    cursor.execute("INSERT OR IGNORE INTO drivers (phone, name) VALUES ('01053905604', '박원호')")
    cursor.execute("INSERT OR IGNORE INTO drivers (phone, name) VALUES ('01098765432', '김철수')")
    conn.commit()
    conn.close()

if __name__ == '__main__':
    
    init_db()


    app.run(host='0.0.0.0', port=5000, debug=True)