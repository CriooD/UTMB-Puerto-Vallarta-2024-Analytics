# UTMB - Puerto Vallarta 2024 Analytics

## Description

This repository contains the SQL scripts used to analyze the UTMB Puerto Vallarta 2024 race results. Using SQLite, these queries explore key metrics such as runner performance, drop-out (DNF) rates, and demographics.   The project demonstrates practical SQL techniques, including Window Functions for category rankings, Common Table Expressions (CTEs) to compare individual times against averages, and LEFT JOINs to build complete race matrices with explicit zeros. It also includes data validation queries to check data accuracy before exporting the results for visualization.

## Languages Used

- <b> SQL </b>

## Environment Used

- SQLite

## Key SQL Concepts Used

- **JOINs**

- **Common Table Expressions (CTEs)**

- **Window Functions**

## Data Quality Notes
Real-world data is messy, so a few decisions were made on purpose:

- **Anonymous runners**: some runners appear in the results as "Anonymous", with no last name. So, each one is treated as a separate runner instead of being merged into one.

- **Duplicate names**: two different runners can share the same name and nationality. A validation step (verify_load() in build_utmb_db.py) checks for this after loading the data, so no results are lost without a warning.

## Business Questions Analyzed
1. **Top 10 fastest finish times overall**\
  1.1 Top 10 fastest finish times by gender
2. **DNF (drop-out) rate by race/distance**\
  2.1 DNF (drop-out) rate by gender
3. **Countries with the most participants (minimum sample size)**
4. **Gap between the overall category winner and the category average (CTE)**\
  4.1 Gap between the overall race category winner and the race category average
5. **Ranking within each race + age category (window functions)**\
  5.1 Ranking within each race + age category + gender
6. **Top 10% fastest finishers within each category (window functions)**
7. **Full grid of race × age category with explicit zeros (LEFT JOIN)**

> *Note: The file also includes validation queries to ensure data integrity prior to analysis.*

## Queries results

1. **Top 10 fastest finish times overall**\
It is usually a common mistake to take the top 10 times overall, but that would only returns runners from the shortest distance, since a 10K time and a 100M time aren't comparable. Instead, the top 10 times per race are displayed. Additionally, query 1b presents a faster and more compact way to display the results, using a window function (RANK() PARTITION BY race), which also surfaces real ties in the results: two runners tied for 2nd place in the 50K (05:25:54 each) and two tied for 9th place in the 20K. RANK() gives both the same position, instead of arbitrarily splitting them the way ROW_NUMBER() would.\
Women reach the top 10 in every single distance. The standout: in the 50K, Sara Alonso finished tied for 2nd overall — essentially level with the outright win.

1.1 **Top 10 fastest finish times by gender**\
As in query 1, the same mehodology was used. The difference is that the analysis was now broken down by gender — women with women and men with men.

2. **DNF (drop-out) rate by race/distance**\
DNF rate mostly tracks distance, but not perfectly. It drops fairly steadily from the 100M (26.9%) down to the 50K (9.9%) — consistent with longer/harder races wearing runners down. But the relationship isn't fully monotonic: the 10K has a higher DNF rate (6.1%) than the 20K (4.1%), the opposite of what distance alone would predict.

2.1 **DNF (drop-out) rate by gender**\
Splitting by gender surfaces something more interesting: in 5 of the 6 races, men drop out at a noticeably higher rate than women — most dramatically in the 100M, where men DNF almost 3x as often as women (29.0% vs 9.1%). The one exception is the 10K, where the pattern flips entirely: women's DNF rate (8.6%) is roughly 3x men's (2.9%). Worth digging into further (course difficulty, time-of-day/heat exposure, participant experience level per distance) rather than assuming a single cause.

3. **Countries with the most participants (minimum sample size)**\
The nationality data shows a heavy long-tail distribution (Mexico accounts for the vast majority, while many countries have fewer than 5 runners). Depending on the analytical goal, the query can be adjusted in two ways:

- **For statistical analysis** (e.g., comparing DNF rates or average times): A filter of HAVING runner_count >= 10 is applied. This ensures a minimum sample size, preventing high variance and skewed percentages (e.g., avoiding a 100% drop-out rate from a country with only one participant).

- **For visual reporting** (Power BI): A simple LIMIT 10 is used to build clean, uncluttered bar charts showing the top participating countries without overcomplicating the dashboard.

4. **Gap between the overall category winner and the category average (CTE)**\
To measure performance dominance, this query calculates how far ahead a category winner was compared to the average runner in their specific age group. A technical challenge here was converting string-based times ("HH:MM:SS") into total seconds using a CTE to allow for accurate mathematical aggregation (MIN and AVG). Additionally, a HAVING COUNT(*) >= 2 filter was applied to exclude categories with only one finisher, preventing meaningless 0.0-minute gaps. The data reveals massive leads in longer distances: in the 100M (Wixárika), Remigio Huaman Quispe (40-44) beat his category average by 898.2 minutes — an almost 15-hour advantage.
   
4.1 **Gap between the overall race category winner and the race category average**\
Using the same time-conversion methodology, the aggregation shifts from age groups to the entire race distance. This evaluates the absolute champion's dominance over the entire field. Remigio Huaman Quispe’s performance stands out again: not only did he dominate his age group, but he also finished 827.9 minutes (~14 hours) faster than the overall average of all 100M finishers.
  
  
5. **Ranking within each race + age category (window functions)**\
This query builds a micro-leaderboard by calculating the exact finishing position for every runner within their specific race and age group. Using the RANK() OVER (PARTITION BY...) window function instead of a standard GROUP BY preserves row-level details (like runner names). Similar to query 1b, RANK() handles real ties correctly: in the 100K (20-34 category), Apolline Dewatre and Maxime Gregorieff crossed the finish line at the exact same second (20:57:25) and were properly tied for 42nd place.

  5.1 **Ranking within each race + age category + gender**\
 Expanding on the previous query, two parallel RANK() window functions were used to compute multi-dimensional standings in a single pass. This allows us to see a runner's position both within their age group and across their entire gender division without needing complex self-joins. It highlights dual achievements, such as Julián Vinasco Marin winning both his category (40-44) and the overall men's 100K, or Arden Young placing 3rd in her overrall age group (35-39) but taking 1st place in the overall women's 100K.
   
6. **Top 10% fastest finishers within each category (window functions)**\
This query isolates the elite tier of runners by filtering for the top 10% fastest times in every specific race distance and age group. The NTILE(10) window function was used inside a CTE (since window functions cannot be placed directly in a WHERE clause) to divide the partitioned datasets into deciles. The engine handles remainders smartly: for instance, in the 100K 20-34 category with 53 finishers, it correctly assigned the top 6 runners to the first decile.
   
7. **Full grid of race × age category with explicit zeros (LEFT JOIN)**\
When visualizing data in tools like Power BI, categories with no data often disappear entirely, breaking matrix visuals. To prevent this, a CROSS JOIN was first used to generate a complete cartesian product of all races and distinct age categories. Then, a LEFT JOIN connected the finisher results. Counting the matches explicitly returns a 0 where no finishers exist. The results exposed 23 completely empty race/age combinations — predominantly in the older (65-69, 70-74, 80+) and younger (U18, U20) demographics — ensuring the final dashboard reflects these gaps accurately.
