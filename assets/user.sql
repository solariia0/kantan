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
    on_accuracy FLOAT NOT NULL DEFAULT 0,
    on_attempts INT NOT NULL DEFAULT 0,
    on_correct INT NOT NULL DEFAULT 0,
    on_wrong INT NOT NULL DEFAULT 0,
    kun_accuracy FLOAT NOT NULL DEFAULT 0,
    kun_attempts INT NOT NULL DEFAULT 0,
    kun_wrong INT NOT NULL DEFAULT 0,
    kun_correct INT NOT NULL DEFAULT 0,
    reading_accuracy FLOAT NOT NULL DEFAULT 0,
    reading_attempts INT NOT NULL DEFAULT 0,
    reading_wrong INT NOT NULL DEFAULT 0,
    reading_correct INT NOT NULL DEFAULT 0,
    input_mistakes VARCHAR(20),
    mcq_mistakes VARCHAR [],
    last_practiced timestamp
);

insert into users(username, mode, level) values ('user1', 'jlpt', 3);

SELECT k.literal, krm.onreadings
FROM kanjidic2 k
JOIN kanjidic2ReadingMeaning krm 
  ON krm.kanji_id = k.id
LEFT JOIN user_kanji u 
  ON k.id = u.kanji_id AND u.user_id = 1
WHERE u.kanji_id IS NULL
  AND k.jlptLevel = (
    SELECT level FROM users WHERE id = 1
  ) ORDER BY RANDOM();

SELECT k.literal, krm.onreadings
FROM kanjidic2 k
JOIN kanjidic2ReadingMeaning krm 
  ON krm.kanji_id = k.id
LEFT JOIN user_kanji u 
  ON k.id = u.kanji_id AND u.user_id = 1
WHERE u.kanji_id IS NULL
  AND k.jlptLevel = (
    SELECT level FROM users WHERE id = 1
  ) ORDER BY RANDOM();


//dsfsd
SELECT 
    krad.radicals, 
    k.literal, 
    k.onreadings,
    k.meanings
FROM kradfile AS krad
JOIN (
    SELECT 
        k.literal, 
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
ORDER BY RANDOM();