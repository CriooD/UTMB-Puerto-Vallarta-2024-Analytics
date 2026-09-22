<h1>UTMB - Puerto Vallarta 2024 Analytics</h1>

<h2>Description</h2>



<h2>Languages Used</h2>

- <b> SQL </b>

<h2>SQL - business analysis queries</h2>

- <b>JOINs</b>

- <b>CTEs</b>

- <b>Window functions</b>

<h2>Environment Used</h2>

- <b>SQLite</b>

<h2>Business Questions</h2>
<ol> 
  <li> Top 10 fastest finish times overall </li>
    <ul><li> Top 10 fastest finish times by gender </li></ul>
  <li> DNF (drop-out) rate by race/distance</li>
    <ul><li>  DNF (drop-out) rate by gender </li></ul>
  <li> Countries with the most participants (minimum sample size) </li>
  <li> Gap between the overall category winner and the category average (CTE) </li>
     <ul><li>   Gap between the overall race category winner and the race category average </li></ul>
  <li> Ranking within each race + age category (window functions) </li>
   <ul><li>  Ranking within each race + age category + gender </li></ul>
  <li> Top 10% fastest finishers within each category (window functions) </li>
  <li> Full grid of race × age category with explicit zeros (LEFT JOIN) </li>
</ol>

The file also includes a couple of validation queries (not business insights)

<h2>Script walk-through:</h2>
