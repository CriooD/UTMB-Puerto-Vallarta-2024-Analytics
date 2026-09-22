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

## Script walk-through
