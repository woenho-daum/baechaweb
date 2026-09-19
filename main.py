from flask import Flask, render_template

from baechaweb import entry, login, survey

app = Flask(__name__)


@app.route("/")
def intro():
    return render_template("baecha_intro.html")


@app.route("/baechaweb", methods=["GET"])
def baechaweb():
    return entry()


@app.route("/baechaweb/login", methods=["POST"])
def baechaweb_login():
    return login()

@app.route("/baechaweb/survey", methods=["POST"])
def baechaweb_survey():
    return survey()


if __name__ == "__main__":
    app.run(debug=True)