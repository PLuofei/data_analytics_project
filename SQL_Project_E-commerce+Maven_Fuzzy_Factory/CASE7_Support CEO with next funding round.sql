/* CASE_Support CEO with next funding round
I’ve just been hired as an eCommerce Database Analyst for Maven Fuzzy Factory, an online retailer which has just 
launched their first product.

Cindy is the CEO of Maven Fuzzy Factory. She is close to securing Maven Fuzzy Factory’s next round of funding, 
and she needs my help to tell a compelling story to investors. I’ll need to pull the relevant data, and help the
CEO craft a story about a data-driven company that has been producing rapid growth.

Following is the requests from Cindy.
*/

/*
1. First, I’d like to show our volume growth. Can you pull overall session and order volume, 
trended by quarter for the life of the business? Since the most recent quarter is incomplete, 
you can decide how to handle it.
*/ 

SELECT YEAR(w.created_at) AS year,
	   QUARTER(w.created_at) AS quarter,
       COUNT(DISTINCT w.website_session_id) AS sessions,
       COUNT(DISTINCT o.order_id) AS orders       
FROM website_sessions w
LEFT JOIN orders o
USING (website_session_id)
WHERE w.created_at < '2015-04-01'
GROUP BY 1,2;

/*
2. Next, let’s showcase all of our efficiency improvements. I would love to show quarterly figures 
since we launched, for session-to-order conversion rate, revenue per order, and revenue per session. 
*/

SELECT YEAR(w.created_at) AS yr,  
	   QUARTER(w.created_at) AS qr, 
	   -- COUNT(DISTINCT w.website_session_id) AS sessions,
	   -- COUNT(DISTINCT o.order_id) AS orders,
       CONCAT(FORMAT(COUNT(DISTINCT o.order_id)/COUNT(DISTINCT w.website_session_id)*100,2),'%') AS s_o_cvr,
       -- SUM(o.price_usd) AS revenue,
       ROUND(SUM(o.price_usd)/COUNT(DISTINCT o.order_id),2) AS r_p_orders,
       ROUND(SUM(o.price_usd)/COUNT(DISTINCT w.website_session_id),2) AS r_p_sessions
FROM website_sessions w
LEFT JOIN orders o
USING (website_session_id)
WHERE w.created_at < '2015-04-01'
GROUP BY 1,2;

/*
3. I’d like to show how we’ve grown specific channels. Could you pull a quarterly view of orders 
from Gsearch nonbrand, Bsearch nonbrand, brand search overall, organic search, and direct type-in?
*/

SELECT YEAR(o.created_at) AS year,
	   QUARTER(o.created_at) AS quarter,
       COUNT(DISTINCT CASE WHEN utm_source='gsearch' AND utm_campaign='nonbrand' THEN o.order_id END) AS orders_gsearch_nonbrand,
       COUNT(DISTINCT CASE WHEN utm_source='bsearch' AND utm_campaign='nonbrand' THEN o.order_id END) AS orders_bsearch_nonbrand,
       COUNT(DISTINCT CASE WHEN utm_campaign='brand' THEN o.order_id END) AS orders_brand,
       COUNT(DISTINCT CASE WHEN utm_campaign IS NULL AND http_referer IS NOT NULL THEN o.order_id END) AS orders_og_search,
       COUNT(DISTINCT CASE WHEN utm_campaign IS NULL AND http_referer IS NULL THEN o.order_id END) AS orders_type_in
FROM orders o
LEFT JOIN website_sessions w USING (website_session_id)
WHERE o.created_at < '2015-04-01'
GROUP BY 1,2;


/*
4. Next, let’s show the overall session-to-order conversion rate trends for those same channels, 
by quarter. Please also make a note of any periods where we made major improvements or optimizations.
*/

SELECT year,
	   quarter,
       CONCAT(FORMAT(orders_gsearch_nonbrand/sessions_gsearch_nonbrand * 100,2),'%') AS gsearch_nonbrand_cvr,
       CONCAT(FORMAT(orders_bsearch_nonbrand/sessions_bsearch_nonbrand * 100,2),'%') AS bearch_nonbrand_cvr,
       CONCAT(FORMAT(orders_brand/sessions_brand * 100,2),'%') AS brand_cvr,
       CONCAT(FORMAT(orders_og_search/sessions_og_search * 100,2),'%') AS og_search_cvr,
       CONCAT(FORMAT(orders_type_in/sessions_type_in * 100,2),'%') AS type_in_cvr
FROM
(SELECT YEAR(w.created_at) AS year,
	   QUARTER(w.created_at) AS quarter,
       COUNT(DISTINCT CASE WHEN utm_source='gsearch' AND utm_campaign='nonbrand' THEN w.website_session_id END) AS sessions_gsearch_nonbrand,
       COUNT(DISTINCT CASE WHEN utm_source='bsearch' AND utm_campaign='nonbrand' THEN w.website_session_id  END) AS sessions_bsearch_nonbrand,
       COUNT(DISTINCT CASE WHEN utm_campaign='brand' THEN w.website_session_id END) AS sessions_brand,
       COUNT(DISTINCT CASE WHEN utm_campaign IS NULL AND http_referer IS NOT NULL THEN w.website_session_id  END) AS sessions_og_search,
       COUNT(DISTINCT CASE WHEN utm_campaign IS NULL AND http_referer IS NULL THEN w.website_session_id  END) AS sessions_type_in,
       COUNT(DISTINCT CASE WHEN utm_source='gsearch' AND utm_campaign='nonbrand' THEN o.order_id END) AS orders_gsearch_nonbrand,
       COUNT(DISTINCT CASE WHEN utm_source='bsearch' AND utm_campaign='nonbrand' THEN o.order_id END) AS orders_bsearch_nonbrand,
       COUNT(DISTINCT CASE WHEN utm_campaign='brand' THEN o.order_id END) AS orders_brand,
       COUNT(DISTINCT CASE WHEN utm_campaign IS NULL AND http_referer IS NOT NULL THEN o.order_id END) AS orders_og_search,
       COUNT(DISTINCT CASE WHEN utm_campaign IS NULL AND http_referer IS NULL THEN o.order_id END) AS orders_type_in
FROM website_sessions w 
LEFT JOIN orders o
USING (website_session_id)
WHERE W.created_at < '2015-04-01'
GROUP BY 1,2) AS temp;


/*
5. We’ve come a long way since the days of selling a single product. Let’s pull monthly trending for revenue 
and margin by product, along with total sales and revenue. Note anything you notice about seasonality.
*/

SELECT DISTINCT product_id,product_name 
FROM products;

SELECT YEAR(oi.created_at) AS year,
	   MONTH(oi.created_at) AS quarter,
       SUM(CASE WHEN product_id=1 THEN price_usd END) AS mr_Fuzzy_revenues,
       SUM(CASE WHEN product_id=1 THEN price_usd-cogs_usd END) AS mr_Fuzzy_revenues_margin,
       SUM(CASE WHEN product_id=2 THEN price_usd END) AS love_bear_revenues,
       SUM(CASE WHEN product_id=2 THEN price_usd-cogs_usd END) AS love_bear_revenues_margin,
       SUM(CASE WHEN product_id=3 THEN price_usd END) AS panda_revenues,
       SUM(CASE WHEN product_id=3 THEN price_usd-cogs_usd END) AS panda_revenues_margin,
       SUM(CASE WHEN product_id=4 THEN price_usd END) AS hudson_bear_revenues,
       SUM(CASE WHEN product_id=4 THEN price_usd-cogs_usd END) AS hudson_bear_revenues_margin,
	   SUM(price_usd) AS total_revenue,
	   SUM(price_usd-cogs_usd) AS total_margin       
FROM order_items oi
GROUP BY 1,2;

/*
6. Let’s dive deeper into the impact of introducing new products. Please pull monthly sessions to 
the /products page, and show how the % of those sessions clicking through another page has changed 
over time, along with a view of how conversion from /products to placing an order has improved.
*/

SELECT year,
	   month,
       sessions,
       CONCAT(FORMAT(n_click_t/sessions * 100, 2),'%') AS ctr,
       CONCAT(FORMAT(n_placing_orders/sessions * 100, 2),'%') AS cvr_with_orders
FROM
(SELECT YEAR(w.created_at) AS year,
	   MONTH(w.created_at) AS month,
       COUNT(DISTINCT w.website_session_id) AS sessions,
       COUNT(DISTINCT CASE WHEN product_p_time < w.created_at THEN w.website_session_id END) AS n_click_t,
       COUNT(DISTINCT CASE WHEN pageview_url = '/thank-you-for-your-order' THEN w.website_session_id END) AS n_placing_orders    
FROM website_pageviews w
JOIN(
SELECT website_session_id, created_at AS product_p_time
FROM website_pageviews
WHERE pageview_url='/products'
) t
USING(website_session_id)
GROUP BY 1,2
) s;


/*
7. We made our 4th product available as a primary product on December 05, 2014 (it was previously only a cross-sell item). 
Could you please pull sales data since then, and show how well each product cross-sells from one another?
*/ 

SELECT os.primary_product_id,
	   oi.product_id AS cross_product_id,
       COUNT(DISTINCT os.order_id) AS orders
FROM orders os
LEFT JOIN order_items oi 
ON oi.order_id = os.order_id AND oi.is_primary_item = 0
WHERE os.created_at >= '2014-12-05'
GROUP BY 1,2;