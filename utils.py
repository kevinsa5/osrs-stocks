from sqlalchemy import create_engine

sql_engine = create_engine("postgresql+psycopg2:///osrs")
sql_conn = sql_engine.connect()
