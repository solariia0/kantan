import psycopg2
import pykakasi

kks = pykakasi.kakasi()

# Connect to the School database
conn = psycopg2.connect(
    dbname="jmdict",
    user="jmdict",
    password="jmdict",
    host="localhost"
)


def findKanji(txt, reading):
    cur = conn.cursor()
    reading = kks.convert(reading)[0]['hira']
    query = f"""
        SELECT
            entr.id, kanj.txt, rdng.txt
        FROM entr
            JOIN kanj ON kanj.entr = entr.id
            JOIN rdng ON rdng.entr = entr.id
        WHERE
            kanj.txt = '{txt}' AND rdng.txt = '{reading}';
            """
    cur.execute(query)
    print(query)
    print(cur.fetchone())
    cur.close()
    conn.close()
    

def query_compounds():
    cur = conn.cursor()
    cur.execute(
    "SELECT * from kanj where kanj.txt = '心臓';"
    )
    print(cur.fetchone())
    conn.close()