import flask
import psycopg2
import socket
import os

app = flask.Flask(__name__)
app.config["DEBUG"] = True


@app.route('/', methods=['GET'])
def home():
    #con = psycopg2.connect(database="postgres", user="postgres", password="Kaliakakya", host="database", port="5432")
    print("Database opened successfully", flush=True)

    cur = con.cursor()
    cur.execute("select * from pg_catalog.pg_user;")
    rows = cur.fetchall()
    db_name = ""

    for row in rows:
        print("username =", row[0], "\n", flush=True)
        db_name = row[0]

    print("Operation done successfully", flush=True)
    con.close()

    dns_test = socket.gethostbyname('bananas.com')
    return "Success Part 3: " + db_name + " " + dns_test

@app.route('/health', methods=['GET'])
def health():
    return "OK"

@app.route('/env', methods=['GET'])
def getenv():
    return str(os.environ)

app.run(host='0.0.0.0', port=80)