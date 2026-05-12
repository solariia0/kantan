

CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(20) NOT NULL UNIQUE,
    mode VARCHAR(5) NOT NULL,
    level INT NOT NULL,
    last_practiced timestamp DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE user_streaks (
    user_id INT REFERENCES users(id),
    practiced_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    practiced BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE kanjidic2(
    id SERIAL PRIMARY KEY,
    literal VARCHAR(5),
    jlptLevel INT,
    grade INT,
    strokes INT,
       onreadings VARCHAR[],
    kunreadings VARCHAR[],
    meanings VARCHAR[]
);

CREATE TABLE user_kanji (
    user_id INT REFERENCES users(id),
    kanji_id INT REFERENCES kanjidic2(id),
    PRIMARY KEY (user_id, kanji_id),
    on_accuracy NUMERIC GENERATED ALWAYS AS ((on_correct * 100.0) / NULLIF(on_attempts, 0)) STORED,
    on_attempts INT DEFAULT 0,
    on_correct INT DEFAULT 0,
    on_wrong INT DEFAULT 0,
    kun_accuracy  NUMERIC GENERATED ALWAYS AS ((kun_correct * 100.0) / NULLIF(kun_attempts, 0)) STORED,
    kun_attempts INT DEFAULT 0,
    kun_wrong INT DEFAULT 0,
    kun_correct INT DEFAULT 0,
    reading_accuracy  NUMERIC GENERATED ALWAYS AS ((reading_correct * 100.0) / NULLIF(reading_attempts, 0)) STORED,
    reading_attempts INT DEFAULT 0,
    reading_wrong INT DEFAULT 0,
    reading_correct INT DEFAULT 0,
    input_mistakes VARCHAR(20),
    mcq_mistakes VARCHAR [],
    last_practiced TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    manually_added BOOLEAN
);

CREATE TABLE kradfile (
    krad_id SERIAL PRIMARY KEY,
    krad_literal VARCHAR(5) NOT NULL,
    radicals VARCHAR[] NOT NULL
);

CREATE TABLE user_vocab(
    user_id INT REFERENCES users(id),
    entry_id INT REFERENCES 
);

create view vocab as (
    SELECT 
  kanj.txt AS kanji,
  rdng.txt AS reading,
  gloss.txt AS meaning
FROM kanj
JOIN entr  ON entr.id = kanj.entr
JOIN rdng  ON rdng.entr = entr.id
JOIN sens  ON sens.entr = entr.id
JOIN gloss ON gloss.entr = sens.entr AND gloss.sens = sens.sens
WHERE gloss.lang = 1
  AND LENGTH(kanj.txt) = 2
);

grant select on kanjidic2, kradfile to jmdictdb;
grant select, update, insert on user_kanji to jmdictdb;
grant select, insert on users to jmdictdb;
grant select, insert on user_streaks to jmdictdb;
grant select on vocab to jmdictdb;

create index idx_user_kanji ON user_kanji(kanji_id, user_id);
-- create index idx_vocab ON vocab(kanji);
create index idx_kanji ON kanjidic2(id, literal);


insert into users(username, mode, level) values ('user1', 'jlpt', 3);
insert into user_streaks(user_id, practiced_at) values (1, '2026-04-13 00:00:00');
insert into user_streaks(user_id, practiced_at) values (1, '2026-04-12 00:00:00');
insert into user_streaks(user_id, practiced_at) values (1, '2026-04-10 00:00:00');