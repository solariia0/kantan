from fastapi import FastAPI, HTTPException, Query, Body
from sqlalchemy.exc import SQLAlchemyError
from sqlalchemy import text, create_engine

DATABASE_URL = "postgresql+psycopg2://jmdictdb:jmdict@localhost:5432/jmnew"
engine = create_engine(DATABASE_URL, echo=True) 

app = FastAPI()


@app.get("/")
def read_root():
    return {"Hello": "World"}

# get kanji values for managing kanji
@app.get("/jlpt/{level}/{page_number}")
def get_kanji(level: int, page_number: int):
    offset = 35 * (page_number - 1)
    sql = text('select k.literal from kanjidic2 as k where jlptLevel = :level LIMIT 35 OFFSET :offset ')
    with engine.connect() as conn:
        result = conn.execute(sql, {'offset': offset, 'level': level}).all()
        result_dicts = [dict(row._mapping) for row in result]
    return result_dicts

@app.get("/grade/{level}/{page_number}")
def get_kanji(level: int, page_number: int):
    offset = 35 * (page_number - 1)
    sql = text('select k.literal from kanjidic2 as k where grade = :level LIMIT 35 OFFSET :offset ')
    with engine.connect() as conn:
        result = conn.execute(sql, {'offset': offset, 'level': level}).all()
        result_dicts = [dict(row._mapping) for row in result]
    return result_dicts

# get the id of selected kanji
@app.get("/kanji_id")
def get_kanji(kanji: list[str] = Query(...)):
    sql = text("""
        SELECT k.id 
        FROM kanjidic2 AS k 
        WHERE k.literal IN :kanji_list
    """)

    with engine.connect() as conn:
        result = conn.execute(sql, {"kanji_list": tuple(kanji)})
        rows = result.fetchall()
    
    results = [dict(row._mapping) for row in rows]
    return results

# addding kanji to user_kanji
@app.post("/user_kanji/{user_id}")
def get_kanji(user_id: int, kanji_list: dict = Body(...)):
    insert_sql = text(
        """
        INSERT INTO user_kanji (user_id, kanji_id)
        VALUES (:user_id, :kanji_id)
        ON CONFLICT DO NOTHING
        """)
    
    data = [
        {"user_id": user_id, "kanji_id": kanji_id}
        for kanji_id in kanji_list["id"]
    ]

    with engine.connect() as connection:
        connection.execute(insert_sql, data)
        connection.commit()

# re write this with user login
@app.get("/{user_id}/{level}/{mode}/new")
def get_kanji(level: int, mode: int, user_id: int):
    #get
    pass