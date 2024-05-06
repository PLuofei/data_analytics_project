/* CASE_Support CEO with performance report to the board
I’ve just been hired as an eCommerce Database Analyst for Maven Fuzzy Factory, an online retailer which has just 
launched their first product.

Cindy is the CEO of Maven Fuzzy Factory. Maven Fuzzy Factory has been live for ~8 months, and Cindy is 
due to present company performance metrics to the board next week. You’ll be the one tasked with preparing 
relevant metrics to show the company’s promising growth.

Following is the requests from Cindy.
*/

/*
1.	Gsearch seems to be the biggest driver of our business. Could you pull monthly 
trends for gsearch sessions and orders so that we can showcase the growth there? 
*/ 

SELECT  MIN(DATE(w.created_at)) AS month_start_day,
		COUNT(DISTINCT website_session_id) AS gsearch_sessions,
        COUNT(DISTINCT order_id) AS orders,
       CONCAT(FORMAT(COUNT(DISTINCT order_id) / COUNT(DISTINCT website_session_id) * 100, 2), '%') AS cvr
FROM website_sessions w
LEFT JOIN orders o
USING (website_session_id)
WHERE utm_source = "gsearch" AND w.created_at < "2012-11-27"
GROUP BY MONTH(w.created_at);

/*
2.	Next, it would be great to see a similar monthly trend for Gsearch, but this time splitting out nonbrand 
and brand campaigns separately. I am wondering if brand is picking up at all. If so, this is a good story to tell. 
*/ 

SELECT  MIN(DATE(w.created_at)) AS start_date,
		COUNT(DISTINCT CASE WHEN utm_campaign = "nonbrand" THEN w.website_session_id ELSE NULL END) AS nonbrand_sessions,
		COUNT(DISTINCT CASE WHEN utm_campaign = "nonbrand" THEN o.order_id ELSE NULL END) AS nonbrand_orders,
        COUNT(DISTINCT CASE WHEN utm_campaign = "brand" THEN w.website_session_id ELSE NULL END) AS brand_sessions,
        COUNT(DISTINCT CASE WHEN utm_campaign = "brand" THEN o.order_id ELSE NULL END) AS brand_orders
FROM website_sessions w
LEFT JOIN orders o
USING (website_session_id)
WHERE utm_source = "gsearch" AND w.created_at < "2012-11-27" 
GROUP BY MONTH(w.created_at);


/*
3.	While we’re on Gsearch, could you dive into nonbrand, and pull monthly sessions and orders split by device type? 
I want to flex our analytical muscles a little and show the board we really know our traffic sources. 
*/ 

SELECT  MIN(DATE(w.created_at)) AS start_date,
		COUNT(DISTINCT CASE WHEN device_type = "mobile" THEN w.website_session_id ELSE NULL END) AS mobile_sessions,
		COUNT(DISTINCT CASE WHEN device_type = "mobile" THEN o.order_id ELSE NULL END) AS mobile_orders,
        COUNT(DISTINCT CASE WHEN device_type = "desktop" THEN w.website_session_id ELSE NULL END) AS desktop_sessions,
        COUNT(DISTINCT CASE WHEN device_type = "desktop" THEN o.order_id ELSE NULL END) AS desktop_orders
FROM website_sessions w
LEFT JOIN orders o
USING (website_session_id)
WHERE utm_source = "gsearch" AND w.created_at < "2012-11-27" AND utm_campaign = "nonbrand"
GROUP BY MONTH(w.created_at);


/*
4.	I’m worried that one of our more pessimistic board members may be concerned about the large % of traffic from Gsearch. 
Can you pull monthly trends for Gsearch, alongside monthly trends for each of our other channels?
*/ 

SELECT DISTINCT 
	utm_source,
    utm_campaign, 
    http_referer
FROM website_sessions
WHERE website_sessions.created_at < '2012-11-27';

SELECT
	YEAR(website_sessions.created_at) AS yr, 
    MONTH(website_sessions.created_at) AS mo, 
    COUNT(DISTINCT CASE WHEN utm_source = 'gsearch' THEN website_sessions.website_session_id ELSE NULL END) AS gsearch_paid_sessions,
    COUNT(DISTINCT CASE WHEN utm_source = 'bsearch' THEN website_sessions.website_session_id ELSE NULL END) AS bsearch_paid_sessions,
    COUNT(DISTINCT CASE WHEN utm_source IS NULL AND http_referer IS NOT NULL THEN website_sessions.website_session_id ELSE NULL END) AS organic_search_sessions,
    COUNT(DISTINCT CASE WHEN utm_source IS NULL AND http_referer IS NULL THEN website_sessions.website_session_id ELSE NULL END) AS direct_type_in_sessions
FROM website_sessions
	LEFT JOIN orders 
		ON orders.website_session_id = website_sessions.website_session_id
WHERE website_sessions.created_at < '2012-11-27'
GROUP BY 1,2;


/*
5.	I’d like to tell the story of our website performance improvements over the course of the first 8 months. 
Could you pull session to order conversion rates, by month? 

*/ 

SELECT  MIN(DATE(w.created_at)) AS start_date,
		COUNT(DISTINCT w.website_session_id) AS sessions,
        COUNT(DISTINCT o.order_id) AS orders,
        CONCAT(FORMAT(COUNT(DISTINCT o.order_id)/COUNT(DISTINCT w.website_session_id) * 100, 2), '%')  AS sessions_orders_cvr
FROM website_sessions w
LEFT JOIN orders o
USING (website_session_id)
WHERE w.created_at < "2012-11-27" 
GROUP BY MONTH(w.created_at);


/*
6.	For the gsearch lander test, please estimate the revenue that test earned us 
(Hint: Look at the increase in CVR from the test (Jun 19 – Jul 28), and use 
nonbrand sessions and revenue since then to calculate incremental value)
*/ 

-- Q6
SELECT   DATE(w.created_at) AS date,
		COUNT(DISTINCT w.website_session_id) AS sessions,
        SUM(price_usd - cogs_usd) AS revenue,
        CONCAT(FORMAT(SUM(price_usd - cogs_usd) / COUNT(DISTINCT w.website_session_id) *100, 2), "%")  AS cvr
FROM website_sessions w
LEFT JOIN orders o
USING (website_session_id)
WHERE (DATE(w.created_at) = '2012-07-19' OR DATE(w.created_at) = '2012-07-28' ) AND utm_campaign = 'nonbrand'
GROUP BY DATE(w.created_at);


/*
7.	For the landing page test you analyzed previously, it would be great to show a full conversion funnel 
from each of the two pages to orders. You can use the same time period you analyzed last time (Jun 19 – Jul 28).
*/ 


SELECT "home" AS segment,
	   CONCAT(FORMAT(product_landing_page/sessions * 100, 2), '%') AS lander_clickthrough_rate,
 	   CONCAT(FORMAT(mrfuzzy_landing_page/product_landing_page * 100, 2), '%')  AS product_clickthrough_rate,
	   CONCAT(FORMAT(cart_landing_page/mrfuzzy_landing_page * 100, 2), '%')  AS mrfuzzy_clickthrough_rate,
	   CONCAT(FORMAT(shopping_landing_page/cart_landing_page * 100, 2), '%')  AS cart_clickthrough_rate,
       CONCAT(FORMAT(billing_landing_page/shopping_landing_page * 100, 2), '%')  AS shopping_clickthrough_rate,
       CONCAT(FORMAT(thankyou_landing_page/billing_landing_page * 100, 2), '%')  AS billing_clickthrough_rate
FROM (
		SELECT COUNT(DISTINCT ws.website_session_id) AS sessions,
			   SUM(CASE WHEN wp.pageview_url = '/products' THEN 1 ELSE NULL END) AS product_landing_page,
			   SUM(CASE WHEN wp.pageview_url = '/the-original-mr-fuzzy' THEN 1 ELSE NULL END) AS mrfuzzy_landing_page,
			   SUM(CASE WHEN wp.pageview_url = '/cart' THEN 1 ELSE NULL END) AS cart_landing_page,
			   SUM(CASE WHEN wp.pageview_url = '/shipping' THEN 1 ELSE NULL END) AS shopping_landing_page,
			   SUM(CASE WHEN wp.pageview_url = '/billing' THEN 1 ELSE NULL END) AS billing_landing_page,
			   SUM(CASE WHEN wp.pageview_url = '/thank-you-for-your-order' THEN 1 ELSE NULL END) AS thankyou_landing_page
		FROM website_sessions ws
		LEFT JOIN website_pageviews wp
		USING (website_session_id)
		WHERE ws.created_at BETWEEN '2012-06-19' AND '2012-07-28'
			  AND ws.utm_campaign = "nonbrand"
              AND ws.utm_source = 'gsearch' 
			  AND pageview_url in ('/home', '/products', '/the-original-mr-fuzzy', '/cart', '/shipping', '/billing', '/thank-you-for-your-order')
              AND website_session_id IN (SELECT DISTINCT website_session_id FROM website_pageviews WHERE pageview_url = '/home')
		) AS subquery
UNION
SELECT "lander-1" AS segment,
	   CONCAT(FORMAT(product_landing_page/sessions * 100, 2), '%') AS lander_clickthrough_rate,
 	   CONCAT(FORMAT(mrfuzzy_landing_page/product_landing_page * 100, 2), '%')  AS product_clickthrough_rate,
	   CONCAT(FORMAT(cart_landing_page/mrfuzzy_landing_page * 100, 2), '%')  AS mrfuzzy_clickthrough_rate,
	   CONCAT(FORMAT(shopping_landing_page/cart_landing_page * 100, 2), '%')  AS cart_clickthrough_rate,
       CONCAT(FORMAT(billing_landing_page/shopping_landing_page * 100, 2), '%')  AS shopping_clickthrough_rate,
       CONCAT(FORMAT(thankyou_landing_page/billing_landing_page * 100, 2), '%')  AS billing_clickthrough_rate
FROM (
		SELECT COUNT(DISTINCT ws.website_session_id) AS sessions,
			   SUM(CASE WHEN wp.pageview_url = '/products' THEN 1 ELSE NULL END) AS product_landing_page,
			   SUM(CASE WHEN wp.pageview_url = '/the-original-mr-fuzzy' THEN 1 ELSE NULL END) AS mrfuzzy_landing_page,
			   SUM(CASE WHEN wp.pageview_url = '/cart' THEN 1 ELSE NULL END) AS cart_landing_page,
			   SUM(CASE WHEN wp.pageview_url = '/shipping' THEN 1 ELSE NULL END) AS shopping_landing_page,
			   SUM(CASE WHEN wp.pageview_url = '/billing' THEN 1 ELSE NULL END) AS billing_landing_page,
			   SUM(CASE WHEN wp.pageview_url = '/thank-you-for-your-order' THEN 1 ELSE NULL END) AS thankyou_landing_page
		FROM website_sessions ws
		LEFT JOIN website_pageviews wp
		USING (website_session_id)
		WHERE ws.created_at BETWEEN '2012-06-19' AND '2012-07-28'
			  AND ws.utm_campaign = "nonbrand"
              AND ws.utm_source = 'gsearch' 
			  AND pageview_url in ('/lander-1', '/products', '/the-original-mr-fuzzy', '/cart', '/shipping', '/billing', '/thank-you-for-your-order')
              AND website_session_id IN (SELECT DISTINCT website_session_id FROM website_pageviews WHERE pageview_url = '/lander-1')
		) AS subquery
ORDER BY 1 DESC;

        
/*
8.	I’d love for you to quantify the impact of our billing test, as well. Please analyze the lift generated 
from the test (Sep 10 – Nov 10), in terms of revenue per billing page session, and then pull the number 
of billing page sessions for the past month to understand monthly impact.
*/ 	

SELECT pageview_url,
	   COUNT(DISTINCT website_session_id) AS sessions,
	   SUM(price_usd) AS revenue,
	   ROUND(SUM(price_usd)/COUNT(DISTINCT website_session_id),2) AS revenue_per_sessions
FROM website_pageviews w
LEFT JOIN orders o
USING (website_session_id)
WHERE w.created_at BETWEEN '2012-09-10' AND '2012-11-10' 
	  AND (pageview_url = '/billing' OR pageview_url = '/billing-2')
GROUP BY pageview_url;

SELECT COUNT(website_session_id) AS billing_sessions_past_month
FROM website_pageviews 
WHERE website_pageviews.pageview_url IN ('/billing','/billing-2') 
	AND created_at BETWEEN '2012-10-27' AND '2012-11-27';