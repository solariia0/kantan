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
    reading = kks.convert(reading)[0]['hira']

    query2 = f"""
        SELECT
            entr.id, kanj.txt, rdng.txt
        FROM entr
            JOIN kanj ON kanj.entr = entr.id
            JOIN rdng ON rdng.entr = entr.id
        WHERE
            kanj.txt = '{txt}' AND rdng.txt = '{reading}';
            """

    query = """
        SELECT
            entr.id, kanj.txt, rdng.txt
        FROM entr
            JOIN kanj ON kanj.entr = entr.id
            JOIN rdng ON rdng.entr = entr.id
        WHERE
            kanj.txt = %s AND rdng.txt = %s;
    """
    print(query2)

    with conn.cursor() as cur:
        cur.execute(query, (txt, reading))
        print(cur.fetchone())
        return cur.fetchone()

    conn.close()
    
def checkExists(txt):
    reading = kks.convert(reading)[0]['hira']

    query2 = f"""
        SELECT
            entr.id, kanj.txt, rdng.txt
        FROM entr
            JOIN kanj ON kanj.entr = entr.id
            JOIN rdng ON rdng.entr = entr.id
        WHERE
            kanj.txt = '{txt}' AND rdng.txt = '{reading}';
            """

    query = """
        SELECT
            entr.id, kanj.txt, rdng.txt
        FROM entr
            JOIN kanj ON kanj.entr = entr.id
            JOIN rdng ON rdng.entr = entr.id
        WHERE
            kanj.txt = %s AND rdng.txt = %s;
    """
    print(query2)

    with conn.cursor() as cur:
        cur.execute(query, (txt, reading))
        print(cur.fetchone())
        return cur.fetchone()

    conn.close()

def query_compounds():
    cur = conn.cursor()
    cur.execute(
    "SELECT * from kanj where kanj.txt = '心臓';"
    )
    print(cur.fetchone())
    conn.close()