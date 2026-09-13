from flask import Flask, abort, request  # <-- 기존 Flask 임포트에 request, abort 추가

app = Flask(__name__)

# --- [추가] 불필요한 스캔 경로 차단 로직 ---
BLOCKED_PATHS = ['.git', '.env', 'config.json', 'config.js', 'env.js','robots.txt' ]

@app.before_request
def block_scanners():
    path = request.path.lower()
    if any(bad in path for bad in BLOCKED_PATHS) or '.git' in path:
        abort(403)
# ---------------------------------------------
    
@app.route("/")
def index():
    return "Survey App is running!"


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=True)

