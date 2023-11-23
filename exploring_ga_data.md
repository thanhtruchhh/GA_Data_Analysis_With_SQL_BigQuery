# Exploring the Google Analytics Data

In this project, I will write 8 query in Bigquery base on Google Analytics Sample dataset and generate insights, including traffic source, user behavior...

You can access my [project on BigQuery](https://console.cloud.google.com/bigquery?sq=103519097298:e89e992618254be1aa30edf3f1a9c20e) to run the queries and view the output directly.

## 1. Total visits, pageviews, and transactions for Jan, Feb, and March 2017, ordered by month

```sql
SELECT 
  FORMAT_DATE('%Y%m', (PARSE_DATE('%Y%m%d', date))) AS month,
  COUNT(fullVisitorId) AS visits,
  SUM(totals.pageviews) AS pageviews,
  SUM(totals.transactions) AS transactions
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_2017*`
WHERE _TABLE_SUFFIX BETWEEN '0101' AND '0331'
GROUP BY 1
ORDER BY 1;
```

**Output:**

<img width="464" alt="ga_data_q1_output" src="https://github.com/thanhtruchhh/GA_Data_Analysis_With_SQL_BigQuery/assets/145547282/bf93789e-2a75-4337-9ed5-a20894f7562a">

- The total of visits to the website varied from month to month. 
- The total number of transactions is increasing month by month, with a particularly significant surge in March. This could be due to changes in customer behavior or the company's marketing strategies.
- The increasing conversion rate, from 1.10% in January to 1.42% in March

---

## 2. Bounce rate per traffic source in July 2017

- The `totals.bounces` column contains `1` or `NULL` &rarr; Use `COUNT` to avoid potential `NULL` value in output.
- Bounce rate = num bounce / total visit.

```sql
SELECT 
  trafficSource.source,
  COUNT(fullVisitorId) AS total_visits,
  COUNT(totals.bounces) AS total_no_of_bounces,
  100 * COUNT(totals.bounces) / COUNT(fullVisitorId) AS bounce_rate 
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_201707*`
GROUP BY 1
ORDER BY 2 DESC;
```

**Output:**

<img width="470" alt="ga_data_q2_output" src="https://github.com/thanhtruchhh/GA_Data_Analysis_With_SQL_BigQuery/assets/145547282/683031c0-6bb3-44f8-b3de-383c0c3049eb">

* The bounce rates for the different sources vary widely.
* Search engines *(google, bing, yahoo, duckduckgo...)* have high bounce rate. It indicates users arriving from there are not finding what they are looking for or are not engaged effectively &rarr; Need optimize the landing pages to ensure they match search intent, and work on providing compelling and relevant content to keep visitors engaged.
* Google, (direct), and youtube.com are the top sources of visits, but a significant portion of visitors from these sources are leaving the site without engaging further:
  * Direct: There might be UI/UX issues on the website &rarr; Collect user feedback to identify and address these issues.
  * YouTube: Visitors arriving from YouTube might not be finding what they expect or are not encouraged to explore the site further &rarr; Opitimize the landing pages or creating more compelling CTA on the site.
* Both reddit.com and mail.google.com have relatively high total visits and low bounce rates *(<30%)*, which indicates that these sources are performing well in terms of visitor engagement and retention:
  *  Reddit: Paricipate actively in relevant subreddits, response to comments, and contribute positively to discussions related to the company's content.
  *  Mail:
      * Segment the email list.
      * Personalize emails: Use the receipient's name, send personalized recommendations based on their past interactions with the website.
      * Ensure that the content in emails is both relevant and valuable to the receipients: product recommendations, special offers, educational content...

---

## 3. Revenue by traffic source by week, by month in June 2017

**Steps:**

1. Calculate revenue by traffic source for each month.
2. Calculate revenue by traffic source for each week.
3. Combine 2 CTEs and sort the results in descending order based on the revenue column.

```sql
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

SELECT *
FROM revenue_by_week
UNION ALL
SELECT *
FROM revenue_by_month
ORDER BY 4 DESC;
```

**Ouput:**

<img width="584" alt="ga_data_q3_output" src="https://github.com/thanhtruchhh/GA_Data_Analysis_With_SQL_BigQuery/assets/145547282/dcf250b6-0d93-4f8f-a614-a5ce15631400">

Revenue from the direct, google, dfa traffic sources are among the highest:

* Direct traffic often includes loyal customers, who directly type the URL into their browser or use bookmarks to access the site &rarr; Have high conversion rates.
* Given the widespread use of Google for web searches, it's common to see significant traffic and revenue from this source.
* Advertising campaigns managed through DoubleClick for Advertisers *(dfa)* are generating income for the company &rarr; Advertising efforts are driving sales or conversions.

---

## 4. Average number of pageviews by purchaser type *(purchasers vs non-purchasers)* in June, July 2017

**Steps:**

1. Calculate average of pageviews for purchasers: Purchaser have `totals.transactions` >= 1; `productRevenue` is not `null`.
2. Calculate average of pageviews for non-purchasers: Non-purchaser: `totals.transactions` IS `NULL`;  `product.productRevenue` is `null`.
3. Merge results with `FULL JOIN` to prevent data loss if there are months with no data for one of the groups.
   
```sql
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
FULL JOIN pageviews_non_purchase
USING(month)
ORDER BY 1;
```

**Output:**

<img width="382" alt="ga_data_q4_output" src="https://github.com/thanhtruchhh/GA_Data_Analysis_With_SQL_BigQuery/assets/145547282/42085257-441c-4ffb-b6ad-a34a2f3c00cf">

-  The average number of pageviews increased in July for both 2 groups. 
-  Non-purchasers are more actively exploring the website's content, browsing various pages, or spending more time on the site. It indicates that these users are engaged with the company content but might face barriers *(pricing, unclear navigation, a lack of trust, or difficulties in the purchase process..)* &rarr; Optimize the user journey, provide more attractive and clearer CTAs, offer vouchers, flash sales.
-  Purchasers may have a more specific goal in mind, leading to fewer pageviews on average &rarr; Ensure a smoth payment experience + Recommend products beforing checking out.
-  
---

## 5. Average number of transactions per user that made a purchase in July 2017

*Notes*:
- *Purchaser: `totals.transactions` >= 1; `productRevenue` is not null. `fullVisitorId` field is user id.*
- *Add condition "product.productRevenue is not null" to calculate correctly.*
  
```sql
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
```

**Output:**

<img width="290" alt="ga_data_q5_output" src="https://github.com/thanhtruchhh/GA_Data_Analysis_With_SQL_BigQuery/assets/145547282/c9d7da23-b105-416c-a2c4-d16f9ed5e9c3">

Average number of transactions per user that made a purchase in July 2017 is 4.16.

---

## 6. Average amount of money spent per session. Only include purchaser data in July 2017

```sql
SELECT 
  FORMAT_DATE('%Y%m', PARSE_DATE('%Y%m%d', date)) AS Month,
  (SUM(productRevenue) / 1000000 )/ COUNT(totals.visits) AS avg_revenue_by_user_per_visit
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_201707*`,
UNNEST (hits) hits,
UNNEST (hits.product) product
WHERE totals.transactions >= 1
  AND productRevenue IS NOT NULL
GROUP BY 1;
```

**Output:**

<img width="287" alt="ga_data_q6_output" src="https://github.com/thanhtruchhh/GA_Data_Analysis_With_SQL_BigQuery/assets/145547282/2e7da191-6b53-4e26-9b4c-d7de61ba4129">

Average amount of money spent per session in July 2017 is 43.86.

---

## 7. Other products purchased by customers who purchased product "YouTube Men's Vintage Henley" in July 2017

**Steps:**

1. Identify all customers who bought 'YouTube Men's Vintage Henley' in July 2017. 
2. Find purchased products of these customer, exclude the 'YouTube Men's Vintage Henley'.

*Note: Add condition `product.productRevenue` is not null to calculate correctly.*
 
```sql
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
```

**Output:**

<img width="278" alt="ga_data_q7_output" src="https://github.com/thanhtruchhh/GA_Data_Analysis_With_SQL_BigQuery/assets/145547282/06328751-b7be-448a-94ff-ce24c26e1149">

- Google Sunglasses stands out with a substantial quantity of 20.
- The list includes different types, including short sleeve, hoodies, or lip balm, for men or women &rarr; Customers who bought the Henley shirt had a diverse range of preferences, both in terms of style and gender-specific items.
- These products appear to be related to Google or YouTube indicating a level of brand loyalty or interest in related items.

&rarr; Cross-sell or make recommendations for customers who bought the Henley shirt.

---

## 8. Cohort map from product view to addtocart to purchase in Jan, Feb and March 2017

**Steps:**

1.  Calculate the counts of various user actions *(product view, add to cart, purchase)* for each month. Note: Add condition `product.productRevenue` is not null  for purchase to calculate correctly.
2.  Calculate conversion rates.
   
```sql
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
```

**Output:**

<img width="653" alt="ga_data_q8_output" src="https://github.com/thanhtruchhh/GA_Data_Analysis_With_SQL_BigQuery/assets/145547282/4868eb68-43da-4e69-b1e2-8f78ef45f98a">

- The cohort map tracks the progression of users through the conversion funnel: Product view &rarr; add to cart &rarr; purchase.
- Over 3 months, there are consistent increase in convertion rate (`add_to_cart_rate` and `purchase_rate`). It could be influenced by various factors, including seasonal trends or marketing campaigns. It's worth investigating whether specific events or promotions had an impact on user behavior.

---

