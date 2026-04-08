import json

with open('kradfile-3.6.2.json', 'r') as file:
    data = json.load(file)

def pg_array_escape(lst):

    escaped = []
    for item in lst:
        # Escape backslashes and double quotes
        s = item.replace('\\', '\\\\').replace('"', '\\"').replace('\'', '\\"')
        escaped.append(s)
    return '{' + ','.join(escaped) + '}'

with open("krad.sql", "w", encoding="utf-8") as krad:
    for item in data['kanji']:
        literal = item;
        radicals = pg_array_escape(data['kanji'][item])
        krad.write(
            f"INSERT INTO kradfile(krad_literal, radicals)\n"
            f"VALUES('{literal}', '{radicals}');\n"
        )