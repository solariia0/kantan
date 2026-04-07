CREATE TABLE kanjidic2(
    id SERIAL PRIMARY KEY,
    literal VARCHAR(5),
    jlptLevel INT,
    grade INT,
    strokes INT
);

CREATE TABLE kanjidic2ReadingMeaning(
    rmid SERIAL PRIMARY KEY,
    kanji_id INT REFERENCES kanjidic2(id),
    onreadings VARCHAR[],
    kunreadings VARCHAR[],
    meanings VARCHAR[]
);