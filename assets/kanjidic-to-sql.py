import json

with open('kanjidic2-all-3.6.2.json', 'r') as file:
    data = json.load(file)

id = 1

def pg_array_escape(lst):

    escaped = []
    for item in lst:
        # Escape backslashes and double quotes
        s = item.replace('\\', '\\\\').replace('"', '\\"').replace('\'', '\\"')
        escaped.append(s)
    return '{' + ','.join(escaped) + '}'



with open("kanjidic-inserts-2.sql", "w", encoding="utf-8") as f_kanji:

    for kanji in data['characters']:
        literal = kanji['literal']
        jlptLevel = kanji['misc'].get('jlptLevel', 'NULL')
        grade = kanji['misc'].get('grade', 'NULL')
        strokes = kanji['misc'].get('strokeCount', 'NULL')

        # Fix kanjidic2 jlpt scoring
        with open('jlpt.txt', "r", encoding='utf-8') as j:
            for line in j:
                line = line.strip()
                if "n" in line:
                        level = line[1:]
                if line == kanji['literal']:
                    jlptLevel = level

        rm = kanji.get('readingMeaning', {})
        if not rm:
            continue
        groups = kanji.get('readingMeaning', {}).get('groups', [])
        if not groups:
            continue

        group = groups[0]
        readings = group.get('readings', [])
        meanings = group.get('meanings', [])

        onreadings = [r['value'] for r in readings if r['type'] == 'ja_on']
        kunreadings = [r['value'] for r in readings if r['type'] == 'ja_kun']
        meaninglist = [m['value'] for m in meanings if m.get('lang') == 'en']

        if not (onreadings or kunreadings or meaninglist):
            continue

        # Convert to PostgreSQL arrays safely
        pg_on = pg_array_escape(onreadings)
        pg_kun = pg_array_escape(kunreadings)
        pg_mean = pg_array_escape(meaninglist)

        f_kanji.write(
            f"INSERT INTO kanjidic2(literal, jlptLevel, grade, strokes,  onreadings, kunreadings, meanings)\n"
            f"VALUES('{literal}', {jlptLevel}, {grade}, {strokes}, '{pg_on}', '{pg_kun}', '{pg_mean}');\n"
        )
        id+=1
