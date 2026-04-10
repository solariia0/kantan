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





( SELECT 
    krad.radicals, 
    k.literal, 
    k.onreadings,
    k.meanings,
    k.id
FROM kradfile AS krad
JOIN (
    SELECT 
        k.literal, 
        k.id,
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
ORDER BY RANDOM()
LIMIT 3)
UNION ALL
( SELECT 
    krad.radicals, 
    k.literal, 
    k.onreadings,
    k.meanings,
    k.id
FROM kradfile AS krad
JOIN (
    SELECT 
        k.literal, 
        k.id,
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
ORDER BY RANDOM()
LIMIT 3);