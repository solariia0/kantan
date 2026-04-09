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
    sql = text('select k.literal from kanjidic2 as k where jlptLevel = :level OFFSET :offset ')
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
@app.get("/quiz/new")
def get_new_kanji():
    sql = text(
        """
            SELECT 
                krad.radicals, 
                k.literal, 
                k.onreadings,
                k.meanings,
                k.id
            FROM kradfile AS krad
            JOIN (
                SELECT 
                    k.literal, 
                    k.id,
                    krm.onreadings,
                    krm.meanings
                FROM kanjidic2 k
                JOIN kanjidic2ReadingMeaning krm 
                    ON krm.kanji_id = k.id
                LEFT JOIN user_kanji u 
                    ON k.id = u.kanji_id 
                    AND u.user_id = 1
                WHERE u.kanji_id IS NULL
                AND k.jlptLevel = (
                    SELECT level FROM users WHERE id = 1
                )
            ) AS k 
                ON k.literal = krad.krad_literal
            WHERE EXISTS (
                SELECT 1
                FROM kanjidic2 k2
                JOIN user_kanji u2 
                    ON k2.id = u2.kanji_id
                WHERE u2.user_id = 1
                AND k2.literal = ANY(krad.radicals)
            )
            ORDER BY RANDOM()
        """
    )
    
    with engine.connect() as conn:
        result = conn.execute(sql).all()
        result_dicts = [dict(row._mapping) for row in result]
    return result_dicts

@app.post("/user_kanji/{user_id}/onyomi")
def get_kanji(user_id: int, body: dict = Body(...)):
    insert_sql = text(
        """
        INSERT INTO user_kanji (user_id, kanji_id, on_attempts, on_correct, on_wrong)
        VALUES (:user_id, :kanji_id, 1, :on_correct, :on_wrong)
        ON CONFLICT (user_id, kanji_id) DO UPDATE 
        SET
            on_attempts = user_kanji.on_attempts + 1,
            on_correct = user_kanji.on_correct + :on_correct,
            on_wrong = user_kanji.on_wrong + :on_wrong
        WHERE user_kanji.user_id = :user_id AND user_kanji.kanji_id = :kanji_id;
        """)
    
    data = {"user_id": user_id, "kanji_id": body['kanji_id'], "on_correct": body["correct"], "on_wrong": body["wrong"]}

    with engine.connect() as connection:
        connection.execute(insert_sql, data)
        connection.commit()

@app.post("/user_kanji/{user_id}/kunyomi")
def get_kanji(user_id: int, body: dict = Body(...)):
    insert_sql = text(
        """
        INSERT INTO user_kanji (user_id, kanji_id, kun_attempts, kun_correct, kun_wrong)
        VALUES (:user_id, :kanji_id, 1, :kun_correct, :kun_wrong)
        ON CONFLICT (user_id, kanji_id) DO UPDATE 
        SET
            kun_attempts = user_kanji.kun_attempts + 1,
            kun_correct = user_kanji.kun_correct + :kun_correct,
            kun_wrong = user_kanji.kun_wrong + :kun_wrong
        WHERE user_kanji.user_id = :user_id AND user_kanji.kanji_id = :kanji_id;
        """)
    
    data = {"user_id": user_id, "kanji_id": body['kanji_id'], "kun_correct": body["correct"], "kun_wrong": body["wrong"]}

    with engine.connect() as connection:
        connection.execute(insert_sql, data)
        connection.commit()

@app.get('/user_kanji/{user_id}/total')
def get_total(user_id: int):
    sql = text(
        """
        SELECT count(u.kanji_id) from user_kanji as u where u.user_id = :id
        """
    )

    with engine.connect() as conn:
        result = conn.execute(sql, {"id": user_id}).all()
        result_dicts = [dict(row._mapping) for row in result]
    return result_dicts