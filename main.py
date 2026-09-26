from flask import Flask, make_response, render_template  # type: ignore

from baechaweb import auth, entry, survey

app = Flask(__name__)

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


if __name__ == "__main__":
    app.run(debug=True)