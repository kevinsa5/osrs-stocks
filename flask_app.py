import json
import pandas as pd
from utils import sql_engine, sql_conn

from flask import Flask, abort, send_file, Response
app = Flask(__name__)

@app.route("/")
def index():
    with open("/root/osrs-stocks/index.html") as f:
        return f.read()

@app.route("/static/<path:fpath>")
def staticfile(fpath):
    return send_from_directory("/root/osrs-stocks/static", fpath)


@app.route("/api/lookup/id/<int:item_id>")
def lookup(item_id):
    cur = sql_conn.execute("SELECT item_id, name, price, examine FROM public.items WHERE item_id = %s", (item_id,))
    data = dict(zip(cur.keys(), cur.fetchone()))
    return json.dumps(data)

@app.route("/api/lookup/name/<name>")
def lookup2(name):
    name = name.lower()
    query = "SELECT item_id, name, price, examine FROM public.items WHERE LOWER(name) = %s"
    args = (name,)
    cur = sql_conn.execute(query, args)
    result = cur.fetchone()
    if result is None:
        abort(404)
    data = dict(zip(cur.keys(), result))
    return json.dumps(data)

@app.route("/api/icons/<int:item_id>")
def geticon(item_id):
    query = "SELECT icon FROM public.items WHERE item_id = %s"
    args = (item_id,)
    cur = sql_conn.execute(query, args)
    result = cur.fetchone()
    if result is None:
        return send_file("/root/osrs-stocks/static/error.png", mimetype="image/png")
    return Response(str(result[0]), mimetype="image/gif")

@app.route("/api/search/<name>")
def search(name):
    name = name.lower()
    query = "SELECT name FROM public.items WHERE LOWER(name) LIKE %s LIMIT 10"
    args = ("%" + name + "%")
    cur = sql_conn.execute(query, args)
    results = cur.fetchall()
    results = [i[0] for i in results]
    return json.dumps(results)

if __name__ == "__main__":
    app.run(host='0.0.0.0', port=8080)
