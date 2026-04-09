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

CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(20) NOT NULL UNIQUE,
    mode VARCHAR(5) NOT NULL,
    level INT NOT NULL,
    last_practiced timestamp
);

CREATE TABLE user_kanji (
    user_id INT REFERENCES users(id),
    kanji_id INT REFERENCES kanjidic2(id),
    PRIMARY KEY (user_id, kanji_id),
    on_accuracy NUMERIC GENERATED ALWAYS AS ((on_correct * 100.0) / NULLIF(on_attempts, 0)) STORED,
    on_attempts INT NOT NULL DEFAULT 0,
    on_correct INT NOT NULL DEFAULT 0,
    on_wrong INT NOT NULL DEFAULT 0,
    kun_accuracy  NUMERIC GENERATED ALWAYS AS ((kun_correct * 100.0) / NULLIF(kun_attempts, 0)) STORED,
    kun_attempts INT NOT NULL DEFAULT 0,
    kun_wrong INT NOT NULL DEFAULT 0,
    kun_correct INT NOT NULL DEFAULT 0,
    reading_accuracy  NUMERIC GENERATED ALWAYS AS ((reading_correct * 100.0) / NULLIF(reading_attempts, 0)) STORED,
    reading_attempts INT NOT NULL DEFAULT 0,
    reading_wrong INT NOT NULL DEFAULT 0,
    reading_correct INT NOT NULL DEFAULT 0,
    input_mistakes VARCHAR(20),
    mcq_mistakes VARCHAR [],
    last_practiced timestamp
);

CREATE TABLE kradfile (
    krad_id SERIAL PRIMARY KEY,
    krad_literal VARCHAR(5) NOT NULL,
    radicals VARCHAR[] NOT NULL
);