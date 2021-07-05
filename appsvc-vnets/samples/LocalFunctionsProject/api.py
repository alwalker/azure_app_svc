import flask
import os

from flask import Response

app = flask.Flask(__name__)
app.config["DEBUG"] = True


@app.route('/HttpExample', methods=['GET', 'POST'])
def home():
    print("Hello", flush=True)
    return { "Outputs": { "res": { "body": "Called Timer" }}}, 200, {'Content-Type': 'application/jso'}

port = os.getenv('FUNCTIONS_CUSTOMHANDLER_PORT') or '80'
app.run(host='0.0.0.0', port=port, use_reloader=False)