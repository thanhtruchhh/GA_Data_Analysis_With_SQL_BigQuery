-- Project 1
-- Q1:  Calculate total visit, pageview, transaction for Jan, Feb and March 2017 (order by month).
-- Output: Month, total visits, total pageviews, total transactions

SELECT 
  FORMAT_DATE('%Y%m', (PARSE_DATE('%Y%m%d', date))) AS month,
  COUNT(fullVisitorId) AS vistits,
  SUM(totals.pageviews) AS pageviews,
  SUM(totals.transactions) AS transactions,
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_2017*`
WHERE _TABLE_SUFFIX BETWEEN '0101' AND '0331'
GROUP BY 1
ORDER BY 1;


-- Q2: Bounce rate per traffic source in July 2017 (order by total visit desc).
-- Output: Source, total visits, no bounces, bounce rate.

SELECT 
  trafficSource.source,
  COUNT(fullVisitorId) AS total_visits,
  COUNT(totals.bounces) AS total_no_of_bounces, -- totals.bounces contains 1 or NULL -> Use COUNT to avoid potential NULL value in output.
  100 * COUNT(totals.bounces) / COUNT(fullVisitorId) AS bounce_rate -- Bounce_rate = num_bounce / total_visit.
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_201707*`
GROUP BY 1
ORDER BY 2 DESC;


-- Q3: Calculate revenue by traffic source by week, by month in June 2017.
-- Output: Time type, time, source, revenue.
-- Notes: 
--  Time type = 'Month' or 'Week'.
--  Week is the week number of the year (Monday as the 1st day of the week).
--  Shorten revenue by divide it by 1000000.

-- Get revenue by traffic source by month
WITH revenue_by_month AS (
  SELECT 
    'Month' AS time_type,
    FORMAT_DATE('%Y%m', PARSE_DATE('%Y%m%d', date)) AS time,
    trafficSource.source AS source, 
    SUM(productRevenue) / 1000000 AS revenue
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_201706*`,
  UNNEST (hits) hits,
  UNNEST (hits.product) product
  GROUP BY 2, 3
),

-- Get revenue by traffic source by week 
revenue_by_week AS (
  SELECT 
    'Week' AS time_type,
    FORMAT_DATE('%Y%W', PARSE_DATE('%Y%m%d', date)) AS time, 
    trafficSource.source AS source, 
    SUM(productRevenue) / 1000000 AS revenue
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_201706*`,
  UNNEST (hits) hits,
  UNNEST (hits.product) product
  GROUP BY 2, 3
)

-- Union
SELECT *
FROM revenue_by_week
UNION ALL
SELECT *
FROM revenue_by_month
ORDER BY 4 DESC;


-- Q4: Average number of pageviews by purchaser type (purchasers vs non-purchasers) in June, July 2017 (sort by month).
-- Output: Month, avg pageview purchase, avg pageview non purchase.

-- Calc avg pageviews of pur
WITH pageviews_purchase AS (
  SELECT 
    FORMAT_DATE('%Y%m', PARSE_DATE('%Y%m%d', date)) AS month,
    SUM(totals.pageviews) / COUNT(DISTINCT fullVisitorId) AS avg_pageviews_purchase
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_2017*`, 
  UNNEST (hits) hits,
  UNNEST (hits.product) product
  WHERE _TABLE_SUFFIX BETWEEN '0601' AND '0731'
    AND totals.transactions >=1
    AND productRevenue IS NOT NULL
  GROUP BY month
),

-- Calc avg pageviews of non-pur
pageviews_non_purchase AS (  
  SELECT 
    FORMAT_DATE('%Y%m', PARSE_DATE('%Y%m%d', date)) AS month,
    SUM(totals.pageviews) / COUNT(DISTINCT fullVisitorId) AS avg_pageviews_non_purchase
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_2017*`, 
  UNNEST (hits) hits,
  UNNEST (hits.product) product
  WHERE _TABLE_SUFFIX BETWEEN '0601' AND '0731'
    AND totals.transactions IS NULL
    AND productRevenue IS NULL
  GROUP BY month
)

SELECT *
FROM pageviews_purchase
FULL JOIN pageviews_non_purchase -- Use FULL JOIN to ensure data is no missing.
USING(month)
ORDER BY 1;


-- Q5: Average number of transactions per user that made a purchase in July 2017.
-- Output: Month, avg no trans/ user.
-- Notes:
-- fullVisitorId field is user id. 
-- Purchaser: totals.transactions >=1; productRevenue is not null.

SELECT 
  FORMAT_DATE('%Y%m', PARSE_DATE('%Y%m%d' ,date)) AS Month,
  SUM(totals.transactions) / COUNT(DISTINCT fullVisitorId) AS Avg_total_transactions_per_user
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_201707*`,
UNNEST(hits) hits,
UNNEST(hits.product) product
WHERE 
  productRevenue IS NOT NULL
  AND totals.transactions >= 1
GROUP BY 1;


-- Q6: Average amount of money spent per session. Only include purchaser data in July 2017.
-- Output: Month, avg.
-- Notes: 
-- Per visit is different per visitor.
-- Shorten revenue by divide it by 1000000.

SELECT 
  FORMAT_DATE('%Y%m', PARSE_DATE('%Y%m%d', date)) AS Month,
  (SUM(productRevenue) / 1000000 )/ COUNT(totals.visits) AS avg_revenue_by_user_per_visit
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_201707*`,
UNNEST (hits) hits,
UNNEST (hits.product) product
WHERE totals.transactions >= 1
  AND productRevenue IS NOT NULL
GROUP BY 1;


-- Q7:Other products purchased by customers who purchased product "YouTube Men's Vintage Henley" in July 2017 (sort by quantity in desc order). 
-- Output: Product name, quantity was ordered.

-- Get customers who bought "YouTube Men's Vintage Henley" in July 2017
WITH customers_bought_henley AS (
  SELECT fullVisitorId
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_201707*`,
  UNNEST (hits) hits,
  UNNEST (hits.product) product
  WHERE v2ProductName = 'YouTube Men\'s Vintage Henley'
    AND totals.transactions IS NOT NULL
    AND productRevenue IS NOT NULL
)

SELECT 
  v2ProductName AS other_purchased_products,
  SUM(productQuantity) AS quantity
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`,
UNNEST (hits) hits,
UNNEST (hits.product) product
WHERE fullVisitorId IN (SELECT * FROM customers_bought_henley)
  AND totals.transactions IS NOT NULL
  AND productRevenue IS NOT NULL
  AND v2ProductName != 'YouTube Men\'s Vintage Henley'
GROUP BY 1
ORDER BY 2 DESC;


-- Q8:Calculate cohort map from product view to addtocart to purchase in Jan, Feb and March 2017. 

-- Calc product views, add to cart, purchase of each month
WITH actions AS (
  SELECT 
    FORMAT_DATE('%Y%m', PARSE_DATETIME('%Y%m%d', date)) AS month,
    COUNT(
      CASE WHEN eCommerceAction.action_type = '2' THEN 1 END 
    ) AS num_product_view,
    COUNT(
      CASE WHEN eCommerceAction.action_type = '3' THEN 1 END 
    ) AS num_addtocart,
    COUNT(
      CASE WHEN eCommerceAction.action_type = '6' AND product.productRevenue IS NOT NULL THEN 1 END 
    ) AS num_purchase
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_2017*`,
  UNNEST (hits) hits,
  UNNEST (hits.product) product
  WHERE _TABLE_SUFFIX BETWEEN '0101' AND '0331'
  GROUP BY month
)

SELECT 
  *,
  ROUND(100 * num_addtocart / num_product_view, 2) AS add_to_cart_rate,
  ROUND(100 * num_purchase / num_product_view, 2) AS purchase_rate
FROM actions
ORDER BY 1;

