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