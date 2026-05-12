-- get the count of attempts for kanji at user level and the accuracy
select 
count(u.kanji_id) as "learned kanji",
count(u.on_accuracy) * 100 / NULLIF(count(u.kanji_id), 0)  as "accuracy",
(select count(k.id) as "level count" from kanjidic2 as k left join users as u on u.id = 1 where k.jlptLevel = u.level)
from user_kanji u
join kanjidic2 k on k.id = u.kanji_id
where u.user_id = 1 and k.jlptLevel = (
    select u.level from users u where u.id = 1
);

-- get total kanji count for user level (jlpt)
select count(k.id) from kanjidic2 as k left join users as u on u.id = 1 where k.jlptLevel = u.level;
-- total kanji count for level (jlpt)
select count(k.id) from kanjidic2 as k where k.jlptLevel = 3; 

-- get kanji that contain at least 1 similar kanji (krad) or have been mistaken for the other in the past

select
k.literal,
krm.onreadings,
krm.kunreadings,
krm.meanings,
krad.radicals,
u.mcq_mistakes
from kanjidic2 as k
left join user_kanji u on u.kanji_id = k.id
join kanjidic2ReadingMeaning as krm on krm.kanji_id = k.id
join kradfile as krad on krad.krad_literal = k.literal
where exists (
        SELECT 1
            FROM kanjidic2 k2
            left JOIN user_kanji u2 
                ON k2.id = u2.kanji_id
            WHERE u2.user_id = 1
            AND k2.literal = ANY(krad.radicals)
) or exists (
        SELECT 1
            FROM kanjidic2 k2
            left JOIN user_kanji u2 
                ON k2.id = u2.kanji_id
            WHERE u2.user_id = 1
            AND k2.literal = ANY(u2.mcq_mistakes)
) 
order by random()
limit 4;


WITH user_data AS (
    SELECT *
    FROM user_kanji
    join users on users.id = user_kanji.user_id
    WHERE user_id = 1
)

SELECT
    k.literal,
    krm.onreadings,
    krm.kunreadings,
    krm.meanings,
    krad.radicals,
    u.mcq_mistakes
FROM kanjidic2 k
LEFT JOIN user_data u 
    ON u.kanji_id = k.id
JOIN kanjidic2ReadingMeaning krm 
    ON krm.kanji_id = k.id
JOIN kradfile krad 
    ON krad.krad_literal = k.literal

WHERE
(
EXISTS (
    SELECT 1
    FROM user_data u2
    RIGHT JOIN kanjidic2 k2 ON k2.id = u2.kanji_id -- right join for testing puroses
    WHERE k2.literal = ANY(krad.radicals)
)

-- OR 2. This kanji appears in mistakes for any studied kanji
OR EXISTS (
    SELECT 1
    FROM user_data u2
    WHERE k.literal = ANY(u2.mcq_mistakes)
)
)
and k.jlptLevel = u.level

ORDER BY RANDOM()
LIMIT 4;

-- get new kanji for jlpt level
WITH filtered_radicals AS (
    SELECT
        krad.krad_literal AS kanji,
        filtered.user_radicals
    FROM kradfile krad
    LEFT JOIN LATERAL (
        SELECT array_agg(k.literal) AS user_radicals
        FROM kanjidic2 k
        JOIN user_kanji u ON u.kanji_id = k.id
        WHERE u.user_id = 1
        AND k.literal = ANY(krad.radicals)
    ) AS filtered ON TRUE
) SELECT 
    k.id,
    k.literal,
    krm.onreadings,
    krm.kunreadings,
    krm.meanings,
    krad.radicals,
    f.user_radicals
FROM kanjidic2 k
JOIN kanjidic2ReadingMeaning krm ON krm.kanji_id = k.id
JOIN kradfile krad ON krad.krad_literal = k.literal
JOIN filtered_radicals f ON f.kanji = krad.krad_literal
LEFT JOIN user_kanji u ON u.kanji_id = k.id AND u.user_id = 1
WHERE k.jlptLevel = (
    SELECT level FROM users WHERE id = 1
) AND u.kanji_id IS NULL;

-- kunyomi new
WITH filtered_radicals AS (
    SELECT
        krad.krad_literal AS kanji,
        filtered.user_radicals
    FROM kradfile krad
    LEFT JOIN LATERAL (
        SELECT array_agg(k.literal) AS user_radicals
        FROM kanjidic2 k
        JOIN user_kanji u ON u.kanji_id = k.id
        WHERE u.user_id = 1
        AND k.literal = ANY(krad.radicals)
    ) AS filtered ON TRUE
) SELECT 
    k.id,
    k.literal,
    krm.onreadings,
    krm.kunreadings,
    krm.meanings,
    krad.radicals,
    f.user_radicals
FROM kanjidic2 k
JOIN kanjidic2ReadingMeaning krm ON krm.kanji_id = k.id
JOIN kradfile krad ON krad.krad_literal = k.literal
JOIN filtered_radicals f ON f.kanji = krad.krad_literal
LEFT JOIN user_kanji u ON u.kanji_id = k.id AND u.user_id = 1
WHERE k.jlptLevel = (
    SELECT level FROM users WHERE id = 1
) AND u.kun_attempts = 0
order by random()
limit 3;

-- 
/*
for onyomi 
radical to corresponding onyomi reading by frequency percentage
radical to semantic grouping 
*/

select * from kanj 
join kinf on kinf.entr = kanj.entr  and kinf.kanj = kanj.kanj 
join kwkinf on kwkinf.id = kinf.kw ;
where kanj.txt LIKE'心';


-- gettting vocab matches
select * from (
SELECT 
  * from vocab where NOT EXISTS (
  SELECT 1
  FROM unnest(string_to_array(vocab.kanji, NULL)) AS ch
  LEFT JOIN kanjidic2 k ON k.literal = ch
  LEFT JOIN user_kanji uk 
    ON uk.kanji_id = k.id AND uk.user_id = 1
  WHERE uk.kanji_id IS NULL
)
) vocab order by random() limit 3;

-- alt
select * from (
    select * from vocab
WHERE NOT EXISTS (
  SELECT 1
  FROM regexp_split_to_table(vocab.kanji, '') AS ch
  JOIN kanjidic2 k USING (k.literal)
  LEFT JOIN user_kanji uk
    ON uk.kanji_id = k.id AND uk.user_id = 1
  WHERE uk.kanji_id IS NULL
)
) vocab order by random() limit 3;


-- review onyomi
 SELECT 
    k.id,
    k.literal,
    k.onreadings,
    k.kunreadings,
    k.meanings,
    krad.radicals,
from kanjidic2 k
join kradfile krad on krad.literal = k.literal
where k.on_accuracy < 70;

-- review kunyomi
 SELECT 
    k.id,
    k.literal,
    k.onreadings,
    k.kunreadings,
    k.meanings,
    krad.radicals,
from kanjidic2 k
join kradfile krad on krad.literal = k.literal
where k.kun_accuracy < 70;

-- review kunyomi
 SELECT 
    k.id,
    k.literal,
    k.onreadings,
    k.kunreadings,
    k.meanings,
    krad.radicals,
from kanjidic2 k
join kradfile krad on krad.literal = k.literal
where k.reading_accuracy < 70;

-- review kunyomi
 SELECT 
    k.id,
    k.literal,
    k.onreadings,
    k.kunreadings,
    k.meanings,
    krad.radicals,
from kanjidic2 k
join kradfile krad on krad.literal = k.literal
join user_vocab
where k.reading_accuracy < 70;

-- all jlpt level kanji info with user_radicals as user known radicals
WITH filtered_radicals AS (
    SELECT
        krad.krad_literal AS kanji,
        filtered.user_radicals
    FROM kradfile krad
    LEFT JOIN LATERAL (
        SELECT array_agg(k.literal) AS user_radicals
        FROM kanjidic2 k
        JOIN user_kanji u ON u.kanji_id = k.id
        WHERE u.user_id = 1
        AND k.literal = ANY(krad.radicals)
    ) AS filtered ON TRUE
) SELECT 
    k.id,
    k.literal,
    krm.onreadings,
    krm.kunreadings,
    krm.meanings,
    krad.radicals,
    f.user_radicals
FROM kanjidic2 k
JOIN kanjidic2ReadingMeaning krm ON krm.kanji_id = k.id
JOIN kradfile krad ON krad.krad_literal = k.literal
JOIN filtered_radicals f ON f.kanji = krad.krad_literal
LEFT JOIN user_kanji u ON u.kanji_id = k.id AND u.user_id = 1
WHERE k.jlptLevel = (
    SELECT level FROM users WHERE id = 1
);

-- get overall accuracy
select (u.on_accuracy + u.kun_accuracy + u.reading_accuracy) * 100 / (u.on_attempts + u.kun_attempts + u.reading_attempts) AS accuracy
from user_kanji u
join kanjidic2 k on k.id = u.kanji_id
where u.user_id = 1 and k.jlptLevel = (select users.level from users where id = 1) group by u.kanji_id;

-- get streak
-- add none for unpracticed days
SELECT s.practiced_at, s.practiced
FROM user_streaks s
WHERE s.user_id = 1
  AND s.practiced_at::date >= CURRENT_TIMESTAMP - INTERVAL '6 days' ORDER BY s.practiced_at ASC;

