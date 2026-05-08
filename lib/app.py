from fastapi import FastAPI, HTTPException, Query, Body
from sqlalchemy.exc import SQLAlchemyError
from sqlalchemy import text, create_engine
from fastapi.middleware.cors import CORSMiddleware

DATABASE_URL = "postgresql+psycopg2://jmdictdb:jmdict@localhost:5432/jmdict"
engine = create_engine(DATABASE_URL, echo=True) 

app = FastAPI()

origins = [
    "http://localhost:44903",  # your frontend
]

app.add_middleware(
    CORSMiddleware,
    allow_origins='*',
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


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


# get kanji info for selected kanji
@app.get("/kanji/info/{kanji}")
def get_kanji(kanji: str):
    sql = text("""
          SELECT k.id, k.onreadings
        FROM kanjidic2 AS k
        WHERE k.literal like :kanji
    """)

    with engine.connect() as conn:
        result = conn.execute(sql, {'kanji': kanji}).all()
        result_dicts = [dict(row._mapping) for row in result]
    return result_dicts

# get the id of selected kanji
@app.get("/kanji_id")
def get_kanji(kanji: list[str] = Query(...)):
    sql = text("""
        SELECT k.id, k.meanings
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
        INSERT INTO user_kanji (user_id, kanji_id,manually_added)
        VALUES (:user_id, :kanji_id, 'T')
        ON CONFLICT DO NOTHING
        """)
    
    data = [
        {"user_id": user_id, "kanji_id": kanji_id}
        for kanji_id in kanji_list["id"]
    ]

    with engine.connect() as connection:
        connection.execute(insert_sql, data)
        connection.commit()

@app.post("/mode/{user_id}")
def get_kanji(user_id: int):
    insert_sql = text(
        """
        INSERT INTO users (id, mode)
        VALUES (:user_id, :mode)
        ON CONFLICT DO NOTHING
        """)

    with engine.connect() as connection:
        connection.execute(insert_sql,  {"user_id": user_id, "mode": mode})
        connection.commit()



# turn this into one function with url query?
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

# known kanji and onyomi accuracy
@app.get('/total/{user_id}')
def get_total(user_id: int):
    sql = text(
        """
        select 
        count(u.kanji_id) as "learned kanji",
        count(u.on_accuracy) * 100 / NULLIF(count(u.kanji_id), 0)  as "on_accuracy",
        (select count(k.id) as "level count" from kanjidic2 as k left join users as u on u.id = :user_id where k.jlptLevel = u.level)
        from user_kanji u
        join kanjidic2 k on k.id = u.kanji_id
        where u.user_id = 1 and k.jlptLevel = (
            select u.level from users u where u.id = :user_id
        );
        """
    )

    with engine.connect() as conn:
        result = conn.execute(sql, {"user_id": user_id}).all()
        result_dicts = [dict(row._mapping) for row in result]
    return result_dicts

# total kanji known to user
@app.get('/user_kanji/{user_id}/total')
def get_total(user_id: int):
    sql = text("""
            select count(u.kanji_id)
            from user_kanji as u
            where u.user_id = :user_id
            """)
    with engine.connect() as conn:
        result = conn.execute(sql, {"user_id": user_id}).all()
        result_dicts = [dict(row._mapping) for row in result]
    return result_dicts

# get streak info
@app.post('/streak/{user_id}')
def update_streak():
    sql = text("""
INSERT INTO user_streaks (user_id, practiced_date, practiced)
VALUES (:user_id, CURRENT_DATE, TRUE)
ON CONFLICT (user_id, practiced_date)
DO UPDATE SET practiced = TRUE;
               
               """)


@app.get('/streak/{user_id}')
def get_streak(user_id: int):
    sql = text("""
        SELECT s.practiced_at, s.practiced
        FROM user_streaks s
        WHERE s.user_id = :user_id
        AND s.practiced_at::date >= CURRENT_TIMESTAMP - INTERVAL '6 days' ORDER BY s.practiced_at ASC
        """)
    
    with engine.connect() as conn:
        result = conn.execute(sql, {"user_id": user_id}).all()
        result_dicts = [dict(row._mapping) for row in result]
    return result_dicts

# quiz queries


# get new kanji
@app.get("/quiz/jlpt/onyomi/{user_id}")
def get_new_kanji(user_id: int):
    sql = text(
        """
        WITH filtered_radicals AS (
        SELECT
            krad.krad_literal AS kanji,
            filtered.user_radicals
        FROM kradfile krad
        LEFT JOIN LATERAL (
            SELECT array_agg(k.literal) AS user_radicals
            FROM kanjidic2 k
            JOIN user_kanji u ON u.kanji_id = k.id
            WHERE u.user_id = 1
            AND k.literal = ANY(krad.radicals)
        ) AS filtered ON TRUE
        ) SELECT 
            k.id,
            k.literal,
            k.onreadings,
            k.kunreadings,
            k.meanings,
            krad.radicals,
            f.user_radicals
        FROM kanjidic2 k
        JOIN kradfile krad ON krad.krad_literal = k.literal
        JOIN filtered_radicals f ON f.kanji = krad.krad_literal
        LEFT JOIN user_kanji u ON u.kanji_id = k.id AND u.user_id = 1
        WHERE k.jlptLevel = (
            SELECT level FROM users WHERE id = 1
        ) AND u.kanji_id IS NULL 
        ORDER BY RANDOM()
        LIMIT 3
        """
    )
    
    with engine.connect() as conn:
        result = conn.execute(sql, {"user_id": user_id}).all()
        result_dicts = [dict(row._mapping) for row in result]
    return result_dicts

@app.get("/quiz/grade/onyomi/{user_id}")
def get_new_kanji(user_id: int):
    sql = text(
        """
        WITH filtered_radicals AS (
        SELECT
            krad.krad_literal AS kanji,
            filtered.user_radicals
        FROM kradfile krad
        LEFT JOIN LATERAL (
            SELECT array_agg(k.literal) AS user_radicals
            FROM kanjidic2 k
            JOIN user_kanji u ON u.kanji_id = k.id
            WHERE u.user_id = 1
            AND k.literal = ANY(krad.radicals)
        ) AS filtered ON TRUE
        ) SELECT 
            k.id,
            k.literal,
            k.onreadings,
            k.kunreadings,
            k.meanings,
            krad.radicals,
            f.user_radicals
        FROM kanjidic2 k
        JOIN kradfile krad ON krad.krad_literal = k.literal
        JOIN filtered_radicals f ON f.kanji = krad.krad_literal
        LEFT JOIN user_kanji u ON u.kanji_id = k.id AND u.user_id = 1
        WHERE k.grade = (
            SELECT level FROM users WHERE id = 1
        ) AND u.kanji_id IS NULL 
        ORDER BY RANDOM()
        LIMIT 3
        """
    )
    
    with engine.connect() as conn:
        result = conn.execute(sql, {"user_id": user_id}).all()
        result_dicts = [dict(row._mapping) for row in result]
    return result_dicts

@app.get("/quiz/grade/kunyomi/{user_id}")
def get_new_kanji(user_id: int):
    sql = text(
        """
WITH filtered_radicals AS (
    SELECT
        krad.krad_literal AS kanji,
        filtered.user_radicals
    FROM kradfile krad
    LEFT JOIN LATERAL (
        SELECT array_agg(k.literal) AS user_radicals
        FROM kanjidic2 k
        JOIN user_kanji u ON u.kanji_id = k.id
        WHERE u.user_id = :user_id
        AND k.literal = ANY(krad.radicals)
    ) AS filtered ON TRUE
) SELECT 
    k.id,
    k.literal,
    k.onreadings,
    k.kunreadings,
    k.meanings,
    krad.radicals,
    f.user_radicals
FROM kanjidic2 k
JOIN kradfile krad ON krad.krad_literal = k.literal
JOIN filtered_radicals f ON f.kanji = krad.krad_literal
LEFT JOIN user_kanji u ON u.kanji_id = k.id AND u.user_id = :user_id
WHERE k.grade = (
    SELECT level FROM users WHERE id = :user_id
) AND u.kun_attempts = 0
order by random()
limit 3
        """
    )

    with engine.connect() as conn:
        result = conn.execute(sql, {"user_id": user_id}).all()
        result_dicts = [dict(row._mapping) for row in result]
    return result_dicts

# get not practiced kunyomi
@app.get("/quiz/jlpt/kunyomi/{user_id}")
def get_new_kanji(user_id: int):
    sql = text(
        """
WITH filtered_radicals AS (
    SELECT
        krad.krad_literal AS kanji,
        filtered.user_radicals
    FROM kradfile krad
    LEFT JOIN LATERAL (
        SELECT array_agg(k.literal) AS user_radicals
        FROM kanjidic2 k
        JOIN user_kanji u ON u.kanji_id = k.id
        WHERE u.user_id = :user_id
        AND k.literal = ANY(krad.radicals)
    ) AS filtered ON TRUE
) SELECT 
    k.id,
    k.literal,
    k.onreadings,
    k.kunreadings,
    k.meanings,
    krad.radicals,
    f.user_radicals
FROM kanjidic2 k
JOIN kradfile krad ON krad.krad_literal = k.literal
JOIN filtered_radicals f ON f.kanji = krad.krad_literal
LEFT JOIN user_kanji u ON u.kanji_id = k.id AND u.user_id = :user_id
WHERE k.jlptLevel = (
    SELECT level FROM users WHERE id = :user_id
) AND u.kun_attempts = 0
order by random()
limit 3
        """
    )

    with engine.connect() as conn:
        result = conn.execute(sql, {"user_id": user_id}).all()
        result_dicts = [dict(row._mapping) for row in result]
    return result_dicts

@app.get('/quiz/vocab/{user_id}')
def get_vocab(user_id: int):
    sql = text("""

select * from (
SELECT 
  * from vocab where NOT EXISTS (
  SELECT 1
  FROM unnest(string_to_array(vocab.kanji, NULL)) AS ch
  LEFT JOIN kanjidic2 k ON k.literal = ch
  LEFT JOIN user_kanji uk 
    ON uk.kanji_id = k.id AND uk.user_id = :user_id
  WHERE uk.kanji_id IS NULL
)
) vocab order by random() limit 3
""")
    with engine.connect() as conn:
        result = conn.execute(sql, {"user_id": user_id}).all()
        result_dicts = [dict(row._mapping) for row in result]
    return result_dicts

@app.get('/test')
def test():
    sql = text("""
SELECT distinct k.txt AS kanji, r.txt AS reading
FROM kanj k
JOIN rdng r ON k.entr = r.entr
               where length(k.txt) = 2;
""")
    
    with engine.connect() as conn:
        result = conn.execute(sql).all()
        result_dicts = [dict(row._mapping) for row in result]
    return result_dicts