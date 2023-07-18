
-- 1. Найдите количество вопросов, которые набрали больше 300 очков или как минимум 100 раз были добавлены в «Закладки».
SELECT 
    COUNT(p.id)
FROM stackoverflow.posts AS p
LEFT JOIN stackoverflow.post_types AS pt ON p.post_type_id = pt.id
WHERE 
    pt.type = 'Question'
    AND (p.score > 300 OR favorites_count >= 100);

--    2. Сколько в среднем в день задавали вопросов с 1 по 18 ноября 2008 включительно? Результат округлите до целого числа.
WITH day_quest AS(
    SELECT  p.creation_date::date AS release_date,
        COUNT(p.id) AS total_daily_questions
        FROM stackoverflow.posts AS p
     LEFT JOIN stackoverflow.post_types AS pt ON p.post_type_id = pt.id
     WHERE  pt.type = 'Question'
            AND  
           p.creation_date BETWEEN '2008-11-01' AND '2008-11-19'
     AND (p.score > 300 OR favorites_count >= 100)
     GROUP BY  p.creation_date::date
     )
SELECT  ROUND(AVG(total_daily_questions), 2) avg_q 
FROM day_quest;


WITH dayly_quests AS (
    SELECT  CAST(DATE_TRUNC('day',  p.creation_date) as date) as dt,
        COUNT(p.id) AS total_daily_questions
        FROM stackoverflow.posts AS p
     INNER JOIN stackoverflow.post_types AS pt ON p.post_type_id = pt.id
     WHERE  pt.type = 'Question' 
     GROUP BY  CAST(DATE_TRUNC('day',  p.creation_date) as date)
    )
SELECT ROUND(AVG(total_daily_questions)) avg_q
FROM dayly_quests
WHERE dt BETWEEN '2008-11-01' AND '2008-11-18';

--3.
--Сколько пользователей получили значки сразу в день регистрации? Выведите количество уникальных пользователей.
SELECT count(DiSTINCT p.id)
FROM stackoverflow.users as p
JOIN stackoverflow.badges as b ON p.id=b.user_id
where p.creation_date::date=b.creation_date::date;

-- 4. Сколько уникальных постов пользователя с именем Joel Coehoorn получили хотя бы один голос?
SELECT COUNT(DISTINCT v.post_id)
FROM stackoverflow.posts as p
JOIN stackoverflow.votes as v ON p.id=v.post_id 
WHERE p.user_id IN (SELECT id
                 FROM stackoverflow.users
                 WHERE display_name =  'Joel Coehoorn');

-- 5. Выгрузите все поля таблицы vote_types. Добавьте к таблице поле rank, в которое войдут номера записей 
-- в обратном порядке. Таблица должна быть отсортирована по полю id.  
SELECT *, 
    ROW_NUMBER() OVER(ORDER BY id DESC) as rank
FROM stackoverflow.vote_types
ORDER BY id ;
--6.
--Отберите 10 пользователей, которые поставили больше всего голосов типа Close. Отобразите таблицу из двух полей:
-- идентификатором пользователя и количеством голосов. Отсортируйте данные сначала по убыванию количества голосов,
-- потом по убыванию значения идентификатора пользователя.

SELECT vote.user_id,
    COUNT(DISTINCT posts.id)
FROM stackoverflow.users as profiles
JOIN stackoverflow.posts as posts ON profiles.id=posts.user_id
JOIN stackoverflow.votes as vote ON posts.id=vote.post_id
JOIN stackoverflow.vote_types as vt ON vote.vote_type_id=vt.id
wHERE vt.name = 'Close'
GROUP BY vote.user_id
ORDER BY 2 DESC, 1 DESC
LiMIT 10;             
                 
SELECT DiSTINCT vote.user_id,
        COUNT(DISTINCT posts.id)
FROM stackoverflow.posts as posts
JOIN stackoverflow.votes as vote ON posts.id=vote.post_id
WHERE vote_type_id = (SELECT id 
                        FROM stackoverflow.vote_types
                        WHERE name = 'Close')
GROUP BY vote.user_id
ORDER BY 2 DESC, 1 DESC
LiMIT 10

-- 7. Отберите 10 пользователей по количеству значков, полученных в период с 15 ноября по 15 декабря 2008 года включительно. Отобразите несколько полей:
--идентификатор пользователя;
--число значков;
--место в рейтинге — чем больше значков, тем выше рейтинг.
--Пользователям, которые набрали одинаковое количество значков, присвойте одно и то же место в рейтинге.
--Отсортируйте записи по количеству значков по убыванию, а затем по возрастанию значения идентификатора пользователя.

-- Версия №1
with reiting as (
	select distinct user_id,
		COUNT(id) OVER(partition  by user_id) as total_count_badges
	from stackoverflow.badges 
	where creation_date between '2008-11-15' and '2008-12-16'
)
select *,
	dense_rank() OVER(ORDER BY total_count_badges DESC, 1 desc)
from  reiting
order by 2 desc,1 asc
limit 10;

-- Версия №2
WITH top_10 as(
    SELECT user_id,
    SUM(count_badges)
    FROM(SELECT  b.user_id,
            CAST(DATE_TRUNC('day',  b.creation_date) as date) as dt,
            COUNT(b.user_id) as count_badges
        FROM stackoverflow.badges AS b
        where creation_date BETWEEN '2008-11-15' AND '2008-12-16'
        GROUP BY 1, 2) as count_badges_users
    GROUP BY 1
    ORDER BY 2 DESC    )
SELECT *,
    dense_rank() OVER(ORDER BY sum DESC, 1 desc)
FROM top_10
order by 2 desc,1 asc
LIMIT 10;

-- 8. Сколько в среднем очков получает пост каждого пользователя?
--Сформируйте таблицу из следующих полей:
--заголовок поста;
--идентификатор пользователя;
--число очков поста;
--среднее число очков пользователя за пост, округлённое до целого числа.
--Не учитывайте посты без заголовка, а также те, что набрали ноль очков.
select distinct title ,
		user_id,
		score,
		round( AVG(score) over(partition by user_id)) avg_score
	from stackoverflow.posts p 
	where title is not null and score != 0;
-- 9. Отобразите заголовки постов, которые были написаны пользователями, получившими более 1000 значков. Посты без заголовков не должны попасть в список.
	
with total_list_badges as (
select distinct user_id,
	COUNT(id) OVER(partition  by user_id) as total_count_badges
from stackoverflow.badges 
order by 2 desc)
select title
from stackoverflow.posts p 
where user_id in (select user_id
					from total_list_badges
					where total_count_badges >= 1000
		) and title is not null;

--10. Напишите запрос, который выгрузит данные о пользователях из США (англ. United States). Разделите пользователей на три группы в зависимости от количества просмотров их профилей:
--пользователям с числом просмотров больше либо равным 350 присвойте группу 1;
--пользователям с числом просмотров меньше 350, но больше либо равно 100 — группу 2;
--пользователям с числом просмотров меньше 100 — группу 3.
--Отобразите в итоговой таблице идентификатор пользователя, количество просмотров профиля и группу. Пользователи с нулевым количеством просмотров не должны войти в итоговую таблицу.
	
select u.id,
	u.views,
case 
	when u.views >= 350 then 1
	when u.views between 100 and 349 then 2
	else 3
end rank	
from stackoverflow.users u 
where u.location like '%United States%' and u.views != 0 ;

--11.Дополните предыдущий запрос. Отобразите лидеров каждой группы — пользователей, которые набрали максимальное число просмотров в своей группе. 
--Выведите поля с идентификатором пользователя, группой и количеством просмотров. Отсортируйте таблицу по убыванию просмотров, а затем по возрастанию значения идентификатора.
with grouping_views as(
	select *,
		RANK() over(partition by rank order by views DESC) as rn
	FROM (select u.id,
			u.views,
		case 
			when u.views >= 350 then 1
			when u.views between 100 and 349 then 2
			else 3
		end rank	
		from stackoverflow.users u 
		where u.location like '%United States%' and u.views != 0 ) as group_users)
select id, 
	rank,
	views 
from grouping_views
where rn = 1
order by 3 desc, asc;

-- 12. Посчитайте ежедневный прирост новых пользователей в ноябре 2008 года. Сформируйте таблицу с полями:
--номер дня;
--число пользователей, зарегистрированных в этот день;
--сумму пользователей с накоплением.


select distinct extract(DAY from days_month) as day_month,
	COUNT(uid) OVER(partition by extract(DAY from days_month)),
	COUNT(*) OVER(order by extract(DAY from days_month))
from (select id as uid,
		DATE_TRUNC('day', creation_date)::date as days_month
	from stackoverflow.users u 
	where creation_date between '2008-11-01' and '2008-12-01'
	order by creation_date asc) as registr_new_users_november
order by day_month 

-- 13. Для каждого пользователя, который написал хотя бы один пост, найдите интервал между регистрацией и временем создания первого поста. Отобразите:
--идентификатор пользователя;
--разницу во времени между регистрацией и первым постом.
with list_post as(
select u.id as uid,
	u.display_name as name_user,
	u.creation_date as date_reg,
	p.creation_date as first_post,
	RANK() OVER(partition by u.id order by p.creation_date) as rn
from stackoverflow.users u 
join stackoverflow.posts p on u.id=p.user_id)
select uid, 
	first_post - date_reg as inter
from list_post
where rn =1 
order by inter

--1. Выведите общую сумму просмотров постов за каждый месяц 2008 года. Если данных за какой-либо месяц в базе нет, такой месяц можно пропустить. Результат отсортируйте по убыванию общего количества просмотров.
WITH list_2008 AS (SELECT  id,
	EXTRACT(MONTH FROM p.creation_date::date),
	SUM(p.views_count) OVER(PARTITION BY id ORDER BY EXTRACT(MONTH FROM creation_date::date)) AS st
FROM stackoverflow.posts p 
WHERE EXTRACT(YEAR FROM p.creation_date) = 2008 
ORDER BY st DESC)
SELECT date_part,
	SUM(st)
FROM list_2008
GROUP BY date_part
ORDER BY 2 DESC

SELECT DISTINCT date_trunc('month', p.creation_date)::date,
	SUM(p.views_count) OVER(PARTITION BY date_trunc('month', p.creation_date)::date
							) AS st
FROM stackoverflow.posts p 
WHERE EXTRACT(YEAR FROM p.creation_date) = 2008 
ORDER BY st DESC;

-- 2.Выведите имена самых активных пользователей, которые в первый месяц после регистрации (включая день регистрации) дали больше 100 ответов.
-- Вопросы, которые задавали пользователи, не учитывайте. Для каждого имени пользователя выведите количество уникальных значений user_id. 
-- Отсортируйте результат по полю с именами в лексикографическом порядке.
SELECT
    u.display_name,
    COUNT(DISTINCT u.id)
FROM stackoverflow.posts p
JOIN stackoverflow.users u ON u.id = p.user_id
WHERE
    p.post_type_id IN (SELECT pt.id
                      FROM stackoverflow.post_types pt
                      WHERE type = 'Answer')
    AND date_trunc('DAY', p.creation_date)::date <= DATE_TRUNC('DAY', u.creation_date)::date + INTERVAL '1 month'
GROUP BY u.display_name
HAVING COUNT(*) > 100
ORDER BY u.display_name;

--3. Выведите количество постов за 2008 год по месяцам. Отберите посты от пользователей, которые зарегистрировались в сентябре 2008 года и
-- сделали хотя бы один пост в декабре того же года. Отсортируйте таблицу по значению месяца по убыванию.

SELECT DISTINCT date_trunc('month', creation_date)::date AS dt_create_post,
	count(id) OVER(PARTITION BY date_trunc('month', creation_date)::date) AS month_count_post
FROM stackoverflow.posts AS posts
WHERE posts.user_id IN (SELECT DISTINCT u.id
							FROM stackoverflow.users u 
							JOIN stackoverflow.posts p ON u.id=p.user_id 
							WHERE EXTRACT(YEAR FROM u.creation_date) = 2008
									AND EXTRACT(MONTH FROM u.creation_date) = 9
									AND EXTRACT(MONTH FROM  p.creation_date) = 12)
ORDER BY 1 DESC;

SELECT DISTINCT date_trunc('month', creation_date)::date AS dt_create_post,
	count(id) OVER(PARTITION BY date_trunc('month', creation_date)::date) AS month_count_post
FROM stackoverflow.posts AS posts
WHERE posts.user_id IN (SELECT DISTINCT u.id
				FROM stackoverflow.users u 
				JOIN stackoverflow.posts p ON u.id=p.user_id 
				WHERE u.creation_date::date BETWEEN '2008-09-01' AND '2008-09-30'
				AND p.creation_date::date BETWEEN '2008-12-01' AND '2008-12-31')
ORDER BY 1 DESC;

SELECT DISTINCT date_trunc('month', posts.creation_date)::date AS dt_create_post,
	count(*)  OVER(PARTITION BY date_trunc('month', creation_date)::date) AS month_count_post
FROM stackoverflow.posts AS posts
WHERE posts.user_id IN 
    (SELECT DISTINCT u.id
	FROM stackoverflow.users u 
	JOIN stackoverflow.posts p ON u.id=p.user_id 
	WHERE DATE_TRUNC('month', u.creation_date)::date = '2008-09-01'
			AND DATE_TRUNC('month', p.creation_date)::date = '2008-12-01')
ORDER BY 1 DESC;

--4. Используя данные о постах, выведите несколько полей:
--идентификатор пользователя, который написал пост;
--дата создания поста;
--количество просмотров у текущего поста;
--сумму просмотров постов автора с накоплением.
--Данные в таблице должны быть отсортированы по возрастанию идентификаторов пользователей,
-- а данные об одном и том же пользователе — по возрастанию даты создания поста.
SELECT user_id,
	creation_date ,
	views_count,
	SUM(views_count) OVER(PARTITION BY user_id ORDER BY creation_date ASC)
FROM stackoverflow.posts p;

--5. Сколько в среднем дней в период с 1 по 7 декабря 2008 года включительно пользователи взаимодействовали
-- с платформой? Для каждого пользователя отберите дни, в которые он или она опубликовали хотя бы один пост. 
-- Нужно получить одно целое число — не забудьте округлить результат.

EXPLAIN ANALYZE
-- Временная таблица подсчет активных дней
WITH  first_week_december AS (
	SELECT DISTINCT user_id,
		COUNT(dt) OVER(PARTITION BY user_id)
		-- Подзапрос: uid, и приводим активные дни к дневному типу данных
	FROM (SELECT DISTINCT user_id, 
			DATE_TRUNC('day', p.creation_date)::date AS dt
			FROM stackoverflow.posts p
			WHERE p.creation_date::date BETWEEN '2008-12-01' AND '2008-12-07') AS ls)
-- Вывод среднего
SELECT ROUND(AVG(count))
FROM first_week_december

--6. На сколько процентов менялось количество постов ежемесячно с 1 сентября по 31 декабря 2008 года? Отобразите таблицу со следующими полями:
--* номер месяца;
--* количество постов за месяц;
--* процент, который показывает, насколько изменилось количество постов в текущем месяце по сравнению с предыдущим.
--Если постов стало меньше, значение процента должно быть отрицательным, если больше — положительным. 
--Округлите значение процента до двух знаков после запятой.
--Напомним, что при делении одного целого числа на другое в PostgreSQL в результате получится целое число,
--округлённое до ближайшего целого вниз. Чтобы этого избежать, переведите делимое в тип numeric.

WITH post AS (SELECT *,
	LAG(cnt_post, 1) OVER(ORDER BY dt_create_post) AS previos_mounth_count_post,
	ROUND((cnt_post::NUMERIC /LAG(cnt_post) OVER(ORDER BY dt_create_post) -1) * 100 , 2)  AS procent
FROM (SELECT DISTINCT
		date_trunc('month', posts.creation_date)::date AS dt_create_post,
		COUNT(posts.id) OVER(PARTITION BY  date_trunc('month', posts.creation_date)::date) AS cnt_post
	FROM stackoverflow.posts posts
	WHERE EXTRACT(YEAR FROM creation_date::date) = 2008
		AND EXTRACT(MONTH FROM  creation_date::date) IN (9, 10, 11, 12)) AS post_2008)
SELECT EXTRACT('month' FROM  dt_create_post), cnt_post, procent
FROM post
 
WITH post AS (SELECT *,
	LAG(cnt_post, 1) OVER(ORDER BY dt_create_post) AS previos_mounth_count_post,
	ROUND(cnt_post::NUMERIC /LAG(cnt_post) OVER(ORDER BY dt_create_post), 2)  AS procent
FROM (SELECT DISTINCT
		date_trunc('month', posts.creation_date)::date AS dt_create_post,
		COUNT(posts.id) OVER(PARTITION BY  date_trunc('month', posts.creation_date)::date) AS cnt_post
	FROM stackoverflow.posts posts
	WHERE DATE_TRUNC('month', creation_date)::date IN ('2008-09-01', '2008-10-01', '2008-11-01', '2008-12-01')) AS post_2008)
SELECT EXTRACT('month' FROM  dt_create_post), cnt_post, procent
FROM post
 

--7. Выгрузите данные активности пользователя, который опубликовал больше всего постов за всё время. Выведите данные за октябрь 2008 года в таком виде:
--номер недели;
--дата и время последнего поста, опубликованного на этой неделе.
WITH list_post_lider AS (
	SELECT id AS uid,
		creation_date AS dt_creation,
		EXTRACT(week FROM creation_date::date) AS week,
		ROW_NUMBER() OVER(PARTITION BY EXTRACT(week FROM creation_date::date) 
							ORDER BY creation_date DESC) AS rn
	FROM stackoverflow.posts posts
	WHERE posts.user_id IN (
		SELECT id
			FROM (SELECT DISTINCT u.id, 
				COUNT(p.id) OVER(PARTITION BY u.id )
				FROM stackoverflow.users u 
				JOIN stackoverflow.posts p ON u.id=p.user_id 
				ORDER BY count DESC
				LIMIT 1) AS lider)
	AND DATE_TRUNC('month', creation_date)::date = '2008-10-01')
SELECT week, dt_creation
FROM list_post_lider
WHERE rn=1

