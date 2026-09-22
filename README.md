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
  
   
4.1 **Gap between the overall race category winner and the race category average**\
  
  
5. **Ranking within each race + age category (window functions)**\

  5.1 **Ranking within each race + age category + gender**\
   
6. **Top 10% fastest finishers within each category (window functions)**\
   
7. **Full grid of race × age category with explicit zeros (LEFT JOIN)**\
