import psycopg2

# Connect to the School database
conn = psycopg2.connect(
    dbname="jmdict",
    user="jmdict",
    password="jmdict",
    host="localhost"
)

cur = conn.cursor()


cur.execute(
    "SELECT * from kanj where kanj.txt = '心臓';"
)
print(cur.fetchone())

cur.close()
conn.close()