import json
import pandas as pd
from utils import sql_engine, sql_conn

from flask import Flask, abort
app = Flask(__name__)

@app.route("/")
def index():
    with open("/root/osrs-stocks/index.html") as f:
        return f.read()

    #return app.send_static_file("/root/osrs-stocks/index.html")

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

if __name__ == "__main__":
    app.run(host='0.0.0.0', port=8080)
