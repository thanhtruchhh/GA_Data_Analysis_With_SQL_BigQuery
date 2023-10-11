# Google Analytics Data Analysis with SQL and BigQuery

This project involves running a series of 8 queries on a Google Analytics Sample Dataset using BigQuery. The dataset contains valuable information about website traffic and user interactions.

## Dataset

The project utilizes a sample dataset from the [Google Merchandise Store](https://www.googlemerchandisestore.com/shop.axd/Home?utm_source=Partners&utm_medium=affiliate&utm_campaign=Data%20Share%20Promo). The dataset contains obfuscated Google Analytics 360 data and represents a real ecommerce store. It includes the following types of information:

- **Traffic source data**: Information about where website visitors originate, including data about organic traffic, paid search traffic, display traffic...
- **Content data**: Information about user behavior on the site, including the URLs of pages visited and how users interact with content.
- **Transactional data**: Information about the transactions that occur on the Google Merchandise Store website.
  
## Data Description

In this dataset, there are numerous fields available. Below, I list some of the important fields that I will use in my queries:

- **fullVisitorId** (STRING): The unique visitor ID.
- **date** (STRING): The date of the session in YYYYMMDD format.
- **totals** (RECORD): This section contains aggregate values across the session.
  - **totals.bounces** (INTEGER): Total bounces (for convenience). For a bounced session, the value is 1; otherwise, it is null.
  - **totals.hits** (INTEGER): Total number of hits within the session.
  - **totals.pageviews** (INTEGER): Total number of pageviews within the session.
  - **totals.visits** (INTEGER): The number of sessions (for convenience). This value is 1 for sessions with interaction events. The value is null if there are no interaction events in the session.
- **trafficSource.source** (STRING): The source of the traffic source. Could be the name of the search engine, the referring hostname, or a value of the utm_source URL parameter.
- **hits** (RECORD): This row and nested fields are populated for any and all types of hits.
  - **hits.eCommerceAction** (RECORD): This section contains all of the eCommerce hits that occurred during the session. This is a repeated field and has an entry for each hit that was collected.
    - **hits.eCommerceAction.action_type** (STRING): The action type. Click through of product lists = 1, Product detail views = 2, Add product(s) to cart = 3, Remove product(s) from cart = 4, Check out = 5, Completed purchase = 6, Refund of purchase = 7, Checkout options = 8, Unknown = 0.
- **hits.product** (RECORD): This row and nested fields will be populated for each hit that contains Enhanced Ecommerce PRODUCT data.
  - **hits.product.productQuantity** (INTEGER): The quantity of the product purchased.
  - **hits.product.productRevenue** (INTEGER): The revenue of the product, expressed as the value passed to Analytics multiplied by 10^6.
  - **hits.product.productSKU** (STRING): Product SKU.
  - **hits.product.v2ProductName** (STRING): Product Name.

For more detailed information on the dataset schema, you can refer to [the Google Analytics documentation](https://support.google.com/analytics/answer/3437719?hl=en).

## SQL Queries

The queries are as follows:

**Query 01:** Calculate total visits, pageviews, and transactions for Jan, Feb, and March 2017, ordered by month.

**Query 02:** Bounce session is the session that user does not raise any click after landing on the website. Determine the bounce rate per traffic source in July 2017 and sort the results in descending order by total_visit. *(Bounce_rate = num_bounce / total_visit)*.

**Query 03:** Calculate revenue by traffic source by week and by month in June 2017.

**Query 04:** Find the average number of pageviews by purchaser type (purchasers vs. non-purchasers) in June and July 2017.

**Query 05:** Calculate the average number of transactions per user who made a purchase in July 2017.

**Query 06:** Determine the average amount of money spent per session, considering only purchaser data in July 2017.

**Query 07:** Identify other products purchased by customers who bought the product "YouTube Men's Vintage Henley" in July 2017. The output should show the product name and the quantity ordered.

**Query 08:** Calculate a cohort map from product view to add to cart to purchase in Jan, Feb, and March 2017. Calculate the add_to_cart rate and purchase rate in product level. For example, 100% product view then 40% add_to_cart and 10% purchase. The output should be calculated in product level. *(Add_to_cart_rate = number product  add to cart / number product view. Purchase_rate = number product purchase / number product view)*.
