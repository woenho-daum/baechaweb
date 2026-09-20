from flask import Flask, render_template  # type: ignore

from baechaweb import auth, entry, survey

app = Flask(__name__)


@app.route("/")
def intro():
    return render_template("baecha_intro.html")


@app.route("/baechaweb", methods=["GET"])
def baechaweb():
    return entry()


@app.route("/baechaweb/auth", methods=["POST"])
def baechaweb_auth():
    return auth()

@app.route("/baechaweb/survey", methods=["GET","POST"])
def baechaweb_survey():
    return survey()


if __name__ == "__main__":
    app.run(debug=True)