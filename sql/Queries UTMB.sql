- =====================================================================
-- UTMB Puerto Vallarta 2024 
-- Schema: corredores (runners) — carreras (races) — resultados (results)
-- =====================================================================

/*
 1. Top 10 fastest finish times overall
Basic JOIN across the three tables. Only finishers are included (DNF runners have time = 00:00:00, which would otherwise sort first).
*/

SELECT r.general_rank, r.time, c.given_name, c.last_name, c.nationality, c.gender, s.race_name, s.race_category
FROM resultados r
INNER JOIN corredores c 
ON r.corredor_id = c.id
INNER JOIN carreras s
ON r.carrera_id = s.id
-- Change s.race_category = '' depending on the requested Overall 
WHERE r.status = 'Finisher' and s.race_category = '100M'
ORDER BY r.time
LIMIT 10;


/*
1b. Top 10 fastest finish times by Gender
Basic JOIN across the three tables. Only finishers are included (DNF runners have time = 00:00:00, which would otherwise sort first).
*/

SELECT r.general_rank, r.time, c.given_name, c.last_name, c.nationality, c.gender, s.race_name, s.race_category
FROM resultados r
INNER JOIN corredores c 
ON r.corredor_id = c.id
INNER JOIN carreras s
ON r.carrera_id = s.id
-- Change s.race_category = '' and c.gender = '' depending on the requested 
WHERE r.status = 'Finisher' AND s.race_category = '100M' AND c.gender = 'Men'
ORDER BY r.time
LIMIT 10;


/*
2. DNF (did not finish) rate by race/distance
Aggregation with CASE + GROUP BY.
Answers: do longer races really have a higher dropout rate?
*/

SELECT s.race_name, s.race_category, s.distance_km,
COUNT(*) as total_runners, SUM(CASE WHEN r.status = 'DNF' THEN 1 ELSE 0 END) AS dnf_count, 
ROUND(100.0* SUM(CASE WHEN r.status = 'DNF' THEN 1 ELSE 0 END)/COUNT(*),1) AS dnf_rate_pct
FROM resultados r
INNER JOIN corredores c 
ON r.corredor_id = c.id
INNER JOIN carreras s
ON r.carrera_id = s.id
GROUP BY s.id, s.race_name, s.race_category, s.distance_km, s.year
ORDER BY s.distance_km DESC;


/*
2b. DNF rate by race and gender
IMPORTANT: the denominator for each gender's rate must be that
gender's own total, not the combined total_runners.
*/

SELECT s.race_name, s.race_category, s.distance_km,
COUNT(*) as total_runners, SUM(CASE WHEN r.status = 'DNF' AND c.gender = 'Women' THEN 1 ELSE 0 END) AS dnf_count_women, 
ROUND(100.0* SUM(CASE WHEN r.status = 'DNF' AND c.gender = 'Women' THEN 1 ELSE 0 END)/nullif(SUM(CASE WHEN c.gender = 'Women' THEN 1 ELSE 0 END),0),1) AS dnf_women_rate_pct,
SUM(CASE WHEN r.status = 'DNF' AND c.gender = 'Men' THEN 1 ELSE 0 END) AS dnf_count_men, 
ROUND(100.0* SUM(CASE WHEN r.status = 'DNF' AND c.gender = 'Men' THEN 1 ELSE 0 END)/nullif(SUM(CASE WHEN c.gender = 'Men' THEN 1 ELSE 0 END),0),1) AS dnf_men_rate_pct
FROM resultados r
INNER JOIN corredores c 
ON r.corredor_id = c.id
INNER JOIN carreras s
ON r.carrera_id = s.id
GROUP BY s.id, s.race_name, s.race_category, s.distance_km, s.year
ORDER BY s.distance_km DESC;


/*
3. Countries with the most participants (minimum sample size)
GROUP BY + HAVING. Answers: where is this event drawing runners from?

The raw data has a long-tail distribution. The filtering approach depends 
 on the next steps for the analysis:

 Approach A (Statistical Validity): Use HAVING COUNT(DISTINCT r.corredor_id) >= 10
 Useful if we plan to cross this data with DNF rates or finish times. 
 A minimum sample size of 10 reduces variance and prevents outliers from 
 skewing the metrics (e.g., a country with 1 runner having a 100% DNF rate).

 Approach B (Dashboard Visualization): Use LIMIT 10
 Useful if the goal is purely descriptive. It keeps visuals in Power BI 
 clean by only showing the top 10 categories.
*/

SELECT c.nationality, COUNT(DISTINCT r.corredor_id) as runner_count
FROM resultados r
INNER JOIN corredores c ON r.corredor_id = c.id
GROUP BY c.nationality
HAVING COUNT(DISTINCT r.corredor_id)>=1
ORDER BY runner_count DESC;
LIMIT 10


/*
V1. Runners linked to more than one race in the SAME edition
Within a single event edition, start times make it physically
impossible for one runner to complete more than one distance. 
So any runner showing up here is certainly two different people 
who share: given_name, last_name, nationality).
*/


SELECT
    c.given_name || ' ' || c.last_name AS corredor_repetido,
    GROUP_CONCAT(c.id, ',') AS ids,
	GROUP_CONCAT(s.race_category, ', ') AS categorias_carreras,
	GROUP_CONCAT(r.time, ', ') AS tiempo_finalizacion,
	GROUP_CONCAT(c.nationality, ', ') AS nacionalidad
FROM resultados r
JOIN corredores c
    ON r.corredor_id = c.id
JOIN carreras s
    ON r.carrera_id = s.id
GROUP BY
    c.given_name,
    c.last_name
HAVING COUNT(*) > 1
ORDER BY
    s.race_category,
    c.given_name,
    c.last_name;


/*
4. Gap between the category winner and the category average
Identify how far ahead the winner is compared to the rest of their
 age group, highlighting standout athletic performances.

1) CTE 1 (time_to_seconds): converts the TEXT time ('HH:MM:SS') into
 total seconds, since you can't AVG() or subtract text directly.
2) CTE 2 (category_stats): Groups the data to find the winner's time and 
   the category average. 
3) Filter: 'HAVING COUNT(*) >= 2' is crucial. It removes single-runner 
   categories to avoid trivial 0.0 minute gaps in the final output.

NOTE (ties): if two runners in the same category have the exact same winning
 time, this join will return both as "the winner". Window functions (next queries)
 are the clean way to pick just one deterministically with RANK() — for now this is a known edge case, not a bug.
*/


WITH time_to_seconds AS(
	SELECT r.id AS result_id, r.corredor_id, r.carrera_id, r.age_category, r.time, 
	CAST(substr(r.time,1,2) as INT) * 3600
		+ CAST(substr(r.time,4,2) AS INT) * 60 
		+ CAST(substr(r.time, 7,2) AS INT) AS time_seconds
	FROM resultados r
	WHERE r.status = 'Finisher'
	),
category_stats AS (
	SELECT carrera_id, age_category, 
	COUNT(*) AS finishers_in_category, MIN(time_seconds) AS winner_seconds, AVG(time_seconds) AS avg_seconds
	FROM time_to_seconds
	GROUP BY carrera_id, age_category
	--HAVING COUNT(*) >= 2 --Skip categories with only one finisher 
)
SELECT s.race_name, s.race_category, cs.age_category, cs.finishers_in_category, c.given_name || ' ' || c.last_name AS winner_name, tts.time AS winner_time,
	ROUND(cs.avg_seconds / 60.0 , 1) as category_avg_minutes, ROUND((cs.avg_seconds - cs.winner_seconds)/60.0,1) AS gap_to_avg_min
FROM category_stats cs
INNER JOIN time_to_seconds tts 
	ON cs.carrera_id = tts.carrera_id AND tts.age_category = cs.age_category AND tts.time_seconds = cs.winner_seconds
INNER JOIN carreras s 
	ON cs.carrera_id = s.id
INNER JOIN corredores c
	ON tts.corredor_id = c.id
ORDER BY s.race_category, cs.age_category;



/*
 4b. Gap between the race category winner and the race category average
Evaluate the absolute champion's dominance over the entire field for each 
race distance, regardless of age or gender.

- Reuses the 'time_to_seconds' CTE logic to handle string-based durations.
- Changes the aggregation level in 'category_stats': Groups only by race ID
 (carrera_id) instead of race and age category, providing a macro-level view of the performance gap.
*/


WITH time_to_seconds AS(
	SELECT r.id AS result_id, r.corredor_id, r.carrera_id, r.time, 
	CAST(substr(r.time,1,2) as INT) * 3600
		+ CAST(substr(r.time,4,2) AS INT) * 60 
		+ CAST(substr(r.time, 7,2) AS INT) AS time_seconds
	FROM resultados r
	WHERE r.status = 'Finisher'
	),
category_stats AS (
	SELECT carrera_id,
	COUNT(*) AS finishers_in_race, MIN(time_seconds) AS winner_seconds, AVG(time_seconds) AS avg_seconds
	FROM time_to_seconds
	GROUP BY carrera_id
)

SELECT s.race_name, s.race_category, cs.finishers_in_race, c.given_name || ' ' || c.last_name AS winner_name, tts.time AS winner_time,
	ROUND(cs.avg_seconds / 60.0 , 1) as avg_minutes, ROUND((cs.avg_seconds - cs.winner_seconds)/60.0,1) AS gap_to_avg_min
FROM category_stats cs
INNER JOIN time_to_seconds tts 
	ON cs.carrera_id = tts.carrera_id AND tts.time_seconds = cs.winner_seconds
INNER JOIN carreras s 
	ON cs.carrera_id = s.id
INNER JOIN corredores c
	ON tts.corredor_id = c.id
ORDER BY s.race_category;



/*
5. Ranking within each race + age category
Window function: RANK() OVER (PARTITION BY ... ORDER BY ...). 
r.general_rank is the OVERALL rank in the race — this gives the rank WITHIN
 the runner's own category, which is what most runners actually care about.
 RANK() also cleanly resolves the tie edge case we flagged in query 4 (ties
 get the same rank, next rank skips — the standard convention in race results,
 e.g. 1, 1, 3). There is a case in the flat CSV file where two runners from 
 the Ereno race with share the same rank but are in a different age_category. 
*/



SELECT s.race_name, s.race_category, r.age_category, c.given_name || ' ' || c.last_name AS runner_name, r.time, r.general_rank AS overall_rank,
    RANK() OVER (
		PARTITION BY r.carrera_id, r.age_category 
		ORDER BY r.time ASC
	) AS category_rank
FROM resultados r
JOIN corredores c 
	ON r.corredor_id = c.id
JOIN carreras   s 
	ON r.carrera_id  = s.id
WHERE r.status = 'Finisher'
ORDER BY s.race_category, r.age_category, category_rank;




/*
5b. Same as query 5, but with an extra rank column by gender category_rank: 
mixed-gender rank within the age category (same as query 5). 
gender_category_rank: rank within gender — the one that matches how UTMB 
actually awards places. Comparing both columns side by side shows exactly 
how much the mixed ranking understates a runner's real standing in their 
own category.
*/


SELECT s.race_name, s.race_category, c.gender, r.age_category, c.given_name || ' ' || c.last_name AS runner_name, r.time, r.general_rank AS overall_rank,
    RANK() OVER (
		PARTITION BY r.carrera_id, r.age_category 
		ORDER BY r.time ASC
	) AS category_rank,
	RANK() OVER (
		PARTITION BY r.carrera_id, c.gender 
		ORDER BY r.time ASC
	) AS gender_rank
FROM resultados r
JOIN corredores c 
	ON r.corredor_id = c.id
JOIN carreras   s 
	ON r.carrera_id  = s.id
WHERE r.status = 'Finisher'
ORDER BY s.race_category, c.gender, r.age_category, category_rank;



/*
6. Top 10% fastest finishers within each category
Another window function: NTILE(10) splits each partition into 10 roughly 
equal-sized buckets by rank order. decile = 1 is the fastest 10% of that 
specific race + age_category. 
CAVEAT: NTILE splits by ROW COUNT, not by time gaps. In a category with 
very few finishers (say, 6 people), "top 10%" isn't a meaningful slice — 
several deciles end up with 0 or 1 person. Same small-sample caution as 
the nationality query earlier: worth checking finishers_in_category-style
 counts before trusting this on small categories.
*/



WITH deciles AS (
    SELECT
        r.carrera_id, r.age_category, c.given_name || ' ' || c.last_name AS runner_name, r.time, 
        NTILE(10) OVER (
				PARTITION BY r.carrera_id, r.age_category 
				ORDER BY r.time ASC
			) AS decile
    FROM resultados r
    JOIN corredores c ON r.corredor_id = c.id
    WHERE r.status = 'Finisher'
)
SELECT
    s.race_name, s.race_category, d.age_category, d.runner_name, d.time  
FROM deciles d
JOIN carreras s ON s.id = d.carrera_id
WHERE d.decile = 1
ORDER BY s.race_category, d.age_category, d.time;



/*
V2. Referential integrity check: any corredor or carrera with zero resultados?
LEFT JOIN + IS NULL is the classic way to find rows with no match. 
Given how build_utmb_db.py populates these tables (corredores and carreras are
 both derived FROM the same raw rows that fill resultados), both queries below
 should return 0 rows — this proves it instead of just assuming it.
*/


SELECT c.id, c.given_name, c.last_name
FROM corredores c
LEFT JOIN resultados r ON r.corredor_id = c.id
WHERE r.id IS NULL;
 
SELECT s.id, s.race_name, s.race_category
FROM carreras s
LEFT JOIN resultados r ON r.carrera_id = s.id
WHERE r.id IS NULL;



/*
7. Full grid of race x age_category, with explicit zerosLEFT JOIN example. 
Every query above so far could have used INNER

Technical Highlights:
 - CROSS JOIN: Generates a complete cartesian product of races and distinct age categories (all_combos).
 - LEFT JOIN: Preserves all generated combinations even when there are no matching finisher records (r.status = 'Finisher').
 - COUNT(r.id): Correctly returns 0 for NULL matches, providing a clean dataset for Power BI matrix visualizations.
*/


WITH all_combos AS (
    SELECT s.id AS carrera_id, s.race_name, s.race_category, ac.age_category
    FROM carreras s
    CROSS JOIN (SELECT DISTINCT age_category FROM resultados) ac
)
SELECT
    ac.race_name, ac.race_category, ac.age_category, COUNT(r.id) AS finisher_count
FROM all_combos ac
LEFT JOIN resultados r
    ON r.carrera_id = ac.carrera_id AND r.age_category = ac.age_category AND r.status = 'Finisher'
GROUP BY ac.carrera_id, ac.race_name, ac.race_category, ac.age_category
ORDER BY ac.race_category, ac.age_category;