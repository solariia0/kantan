import json

with open('kanjireading.json', 'r') as file:
    data = json.load(file)

with open("onyomifrequency.sql", "w", encoding="utf-8") as f_kanji:
    for item in data:
         f_kanji.write(
           f'{item}\n'
        )
    