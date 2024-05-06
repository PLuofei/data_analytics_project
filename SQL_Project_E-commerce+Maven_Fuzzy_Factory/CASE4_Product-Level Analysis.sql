-- CASE4_Product-Level Analysis

/*
Request 1 from Cindy Sharp (CEO) January 04, 2013 
We’re about to launch a new product, and I’d like to do a deep dive on our  current flagship product. Can you please pull monthly 
trends to date for number of sales, total revenue, and total margin generated for the business?
*/ 

SELECT year(created_at) AS yr,
	   MONTH(created_at) AS mo,
       COUNT(DISTINCT order_id) AS number_of_sales,
       SUM(price_usd) AS total_revenue,
       SUM(price_usd - cogs_usd) AS total_margin
FROM orders
WHERE created_at < '2013-01-04'
GROUP BY year(created_at), MONTH(created_at);


/*
Request 2 from Morgan Rockwell (Website Manager) April 06, 2014
Now that we have a new product, I’m thinking about our user path and conversion funnel. Let’s look at sessions which hit the 
/products page and see where they went next. Could you please pull clickthrough rates from /products since the new product launch 
on January 6th 2013, by product, and compare to the 3 months leading up to launch as a baseline?
*/ 

SELECT year(w.created_at) AS yr,
	   MONTH(w.created_at) AS mo,
       COUNT(DISTINCT w.website_session_id) AS sessions,
	   COUNT(DISTINCT o.order_id) AS orders,
       CONCAT(FORMAT(COUNT(DISTINCT o.order_id)/COUNT(DISTINCT w.website_session_id) *100,2), "%") AS conv_rate,
       ROUND(SUM(price_usd)/COUNT(DISTINCT w.website_session_id),2) AS rev_per_session,
       COUNT(DISTINCT CASE WHEN o.primary_product_id = 1 THEN o.order_id END)AS product_one_orders,
       COUNT(DISTINCT CASE WHEN o.primary_product_id = 2 THEN o.order_id END) AS product_two_orders   
FROM website_sessions w
LEFT JOIN  orders o
USING (website_session_id)
WHERE w.created_at BETWEEN '2012-04-01' AND '2013-04-05'
GROUP BY year(w.created_at), MONTH(w.created_at)
ORDER BY year(w.created_at), MONTH(w.created_at);


/*
Request 3 from Morgan Rockwell (Website Manager) April 10, 2014
I’d like to look at our two products since January 6th and analyze the conversion funnels from each product page to conversion.
It would be great if you could produce a comparison between the two conversion funnels, for all website traffic.
*/ 

SELECT	
	'A.Pre_Product_1' AS time_period,
	COUNT(DISTINCT w.website_session_id) AS sessions,
    COUNT(DISTINCT CASE WHEN w.created_at > lp_time THEN website_session_id ELSE NULL END) AS w_next_pg,
    CONCAT(FORMAT(COUNT(DISTINCT CASE WHEN w.created_at > lp_time THEN website_session_id ELSE NULL END) / 
    COUNT(DISTINCT w.website_session_id) * 100,2), '%') AS pct_w_next_pg,
    COUNT(DISTINCT CASE WHEN pageview_url = '/the-original-mr-fuzzy' THEN w.website_session_id END) AS to_mrfuzzy,
    CONCAT(FORMAT(COUNT(DISTINCT CASE WHEN pageview_url = '/the-original-mr-fuzzy' THEN w.website_session_id END) / 
    COUNT(DISTINCT w.website_session_id) * 100,2), '%') AS pct_to_mrfuzzy,
    COUNT(DISTINCT CASE WHEN pageview_url = '/the-forever-love-bear' THEN w.website_session_id END) AS to_lovebea,
    CONCAT(FORMAT(COUNT(DISTINCT CASE WHEN pageview_url = '/the-forever-love-bear' THEN w.website_session_id END) / 
    COUNT(DISTINCT w.website_session_id) * 100,2), '%') AS pct_to_lovebea
FROM website_pageviews w
JOIN (SELECT website_session_id, MIN(created_at) AS lp_time
		   FROM website_pageviews 
		   WHERE pageview_url = '/products'
				 AND created_at > '2012-10-06' AND created_at < '2013-01-06' -- teacher suggests
		   GROUP BY website_session_id) AS subquery 
USING (website_session_id)
LEFT JOIN orders o USING (website_session_id)
UNION
SELECT	
	'A.Post_Product_2' AS time_period,
	COUNT(DISTINCT w.website_session_id) AS sessions,
    COUNT(DISTINCT CASE WHEN w.created_at > lp_time THEN website_session_id ELSE NULL END) AS w_next_pg,
    CONCAT(FORMAT(COUNT(DISTINCT CASE WHEN w.created_at > lp_time THEN website_session_id ELSE NULL END) / 
    COUNT(DISTINCT w.website_session_id) * 100,2), '%') AS pct_w_next_pg,
    COUNT(DISTINCT CASE WHEN pageview_url = '/the-original-mr-fuzzy' THEN w.website_session_id END) AS to_mrfuzzy,
    CONCAT(FORMAT(COUNT(DISTINCT CASE WHEN pageview_url = '/the-original-mr-fuzzy' THEN w.website_session_id END) / 
    COUNT(DISTINCT w.website_session_id) * 100,2), '%') AS pct_to_mrfuzzy,
    COUNT(DISTINCT CASE WHEN pageview_url = '/the-forever-love-bear' THEN w.website_session_id END) AS to_lovebea,
    CONCAT(FORMAT(COUNT(DISTINCT CASE WHEN pageview_url = '/the-forever-love-bear' THEN w.website_session_id END) / 
    COUNT(DISTINCT w.website_session_id) * 100,2), '%') AS pct_to_lovebea
FROM website_pageviews w
JOIN (SELECT website_session_id, MIN(created_at) AS lp_time
		   FROM website_pageviews 
		   WHERE pageview_url = '/products'
				 AND created_at >= '2013-01-06' AND created_at < '2013-04-06' -- teacher suggests
		   GROUP BY website_session_id) AS subquery 
USING (website_session_id)
LEFT JOIN orders o USING (website_session_id);


/*
Request 4 from Cindy Sharp (CEO) November 22, 2013
On September 25th we started giving customers the option to add a 2nd product while on the /cart page. Morgan says this has been 
positive, but I’d like your take on it. Could you please compare the month before vs the month after the change? I’d like to see 
CTR from the /cart page, Avg Products per Order, AOV, and overall revenue per /cart page view.
*/ 

SELECT product_seen,
	   CONCAT(FORMAT(to_cart/sessions * 100,2),'%') AS product_p_ctr,
       CONCAT(FORMAT(to_shipping/to_cart * 100,2),'%') AS cart_p_ctr,
	   CONCAT(FORMAT(to_billing/to_shipping * 100,2),'%') AS shipping_p_ctr,
	   CONCAT(FORMAT(to_thankyou/to_billing * 100,2),'%') AS billing_p_ctr
FROM( SELECT 'mrfuzzy' AS product_seen,
			   COUNT(DISTINCT website_session_id) AS sessions,
			   COUNT(DISTINCT CASE WHEN pageview_url = '/cart' THEN website_session_id ELSE NULL END) AS to_cart,
			   COUNT(DISTINCT CASE WHEN pageview_url = '/shipping' THEN website_session_id ELSE NULL END) AS to_shipping,
			   COUNT(DISTINCT CASE WHEN pageview_url = '/billing-2' THEN website_session_id ELSE NULL END) AS to_billing,
			   COUNT(DISTINCT CASE WHEN pageview_url = '/thank-you-for-your-order' THEN website_session_id ELSE NULL END) AS to_thankyou       
		FROM website_pageviews 
		WHERE created_at >= '2013-01-06' AND created_at < '2013-04-10'
			AND website_session_id IN (SELECT DISTINCT website_session_id FROM website_pageviews 
            WHERE pageview_url = '/the-original-mr-fuzzy')
) AS subquery_1
UNION
SELECT product_seen,
	   CONCAT(FORMAT(to_cart/sessions * 100,2),'%') AS product_p_ctr,
       CONCAT(FORMAT(to_shipping/to_cart * 100,2),'%') AS cart_p_ctr,
	   CONCAT(FORMAT(to_billing/to_shipping * 100,2),'%') AS shipping_p_ctr,
	   CONCAT(FORMAT(to_thankyou/to_billing * 100,2),'%') AS billing_p_ctr
FROM( SELECT 'lovebear' AS product_seen,
			   COUNT(DISTINCT website_session_id) AS sessions,
			   COUNT(DISTINCT CASE WHEN pageview_url = '/cart' THEN website_session_id ELSE NULL END) AS to_cart,
			   COUNT(DISTINCT CASE WHEN pageview_url = '/shipping' THEN website_session_id ELSE NULL END) AS to_shipping,
			   COUNT(DISTINCT CASE WHEN pageview_url = '/billing-2' THEN website_session_id ELSE NULL END) AS to_billing,
			   COUNT(DISTINCT CASE WHEN pageview_url = '/thank-you-for-your-order' THEN website_session_id ELSE NULL END) AS to_thankyou       
		FROM website_pageviews 
		WHERE created_at >= '2013-01-06' AND created_at < '2013-04-10'
			AND website_session_id IN (SELECT DISTINCT website_session_id FROM website_pageviews 
            WHERE pageview_url = '/the-forever-love-bear')
) AS subquery_2;


/*
Request 5 from Cindy Sharp (CEO) January 12, 2014
On December 12th 2013, we launched a third product targeting the birthday gift market (Birthday Bear). Could you please run a 
pre-post analysis comparing the month before vs. the month after, in terms of session-to-order conversion rate, AOV, products per 
order, and revenue per session?
*/ 

SELECT  'A.Pre_Cross_Sell' AS time_period,
	   COUNT(DISTINCT CASE WHEN pageview_url = '/cart' THEN w.website_session_id ELSE NULL END) AS cart_sessions,
	   COUNT(DISTINCT CASE WHEN w.created_at > cart_time THEN w.website_session_id ELSE NULL END) AS clicktrhoughs,
	   CONCAT(FORMAT(COUNT(DISTINCT CASE WHEN w.created_at > cart_time THEN w.website_session_id ELSE NULL END) / 
       COUNT(DISTINCT CASE WHEN pageview_url = '/cart' THEN w.website_session_id ELSE NULL END)*100,2),'%') AS cart_ctr,
       COUNT(DISTINCT o.order_id) AS order_placed,
       SUM(o.items_purchased) AS products_purchased,
       SUM(o.items_purchased)/COUNT(DISTINCT o.order_id) AS products_per_order,
       SUM(price_usd) AS revenue,
       ROUND(SUM(price_usd)/COUNT(DISTINCT o.order_id),2) AS aov,
       ROUND(SUM(price_usd)/COUNT(DISTINCT CASE WHEN pageview_url = '/cart' 
       THEN w.website_session_id ELSE NULL END),2) AS rev_per_c_sessions
FROM website_pageviews w
LEFT JOIN orders o 
ON o.website_session_id = w.website_session_id AND w.pageview_url = '/billing-2'
LEFT JOIN (SELECT website_session_id, created_at AS cart_time FROM website_pageviews WHERE pageview_url = '/cart') t 
ON t.website_session_id = w.website_session_id
WHERE w.created_at BETWEEN '2013-08-25' AND '2013-09-25'
UNION
SELECT  'B.Post_Cross_Sell' AS time_period,
	   COUNT(DISTINCT CASE WHEN pageview_url = '/cart' THEN w.website_session_id ELSE NULL END) AS cart_sessions,
	   COUNT(DISTINCT CASE WHEN w.created_at > cart_time THEN w.website_session_id ELSE NULL END) AS clicktrhoughs,
	   CONCAT(FORMAT(COUNT(DISTINCT CASE WHEN w.created_at > cart_time THEN w.website_session_id ELSE NULL END) / 
       COUNT(DISTINCT CASE WHEN pageview_url = '/cart' THEN w.website_session_id ELSE NULL END)*100,2),'%') AS cart_ctr,
       COUNT(DISTINCT o.order_id) AS order_placed,
       SUM(o.items_purchased) AS products_purchased,
       SUM(o.items_purchased)/COUNT(DISTINCT o.order_id) AS products_per_order,
       SUM(price_usd) AS revenue,
       ROUND(SUM(price_usd)/COUNT(DISTINCT o.order_id),2) AS aov,
       ROUND(SUM(price_usd)/COUNT(DISTINCT CASE WHEN pageview_url = '/cart' 
       THEN w.website_session_id ELSE NULL END),2) AS rev_per_c_sessions
FROM website_pageviews w
LEFT JOIN orders o 
ON o.website_session_id = w.website_session_id AND w.pageview_url = '/billing-2'
LEFT JOIN (SELECT website_session_id, created_at AS cart_time FROM website_pageviews WHERE pageview_url = '/cart') t 
ON t.website_session_id = w.website_session_id
WHERE w.created_at BETWEEN '2013-09-25' AND '2013-10-25';


/*
Request 6 from Cindy Sharp (CEO) October 15, 2014
Our Mr. Fuzzy supplier had some quality issues which weren’t corrected until September 2013. Then they had a major problem where the 
bears’ arms were falling off in Aug/Sep 2014. As a result, we replaced them with a new supplier on September 16, 2014. Can you please 
pull monthly product refund rates, by product, and confirm our quality issues are now fixed?
*/ 
SELECT 'A.Pre_Birthday_Bear' AS time_period,
	   CONCAT(FORMAT(COUNT(DISTINCT o.order_id)/COUNT(DISTINCT w.website_session_id)*100,2),'%') AS conv_rate,
       ROUND(SUM(price_usd)/COUNT(DISTINCT o.order_id),2) AS aov,
       ROUND(SUM(o.items_purchased)/COUNT(DISTINCT o.order_id),2) AS products_per_order,
       ROUND(SUM(price_usd)/COUNT(DISTINCT w.website_session_id),2) AS rev_per_sessions
FROM website_pageviews w
LEFT JOIN orders o 
ON o.website_session_id = w.website_session_id AND w.pageview_url = '/billing-2'
LEFT JOIN (SELECT website_session_id, created_at AS cart_time FROM website_pageviews WHERE pageview_url = '/cart') t 
ON t.website_session_id = w.website_session_id
WHERE w.created_at BETWEEN '2013-11-12' AND '2013-12-12'
UNION
SELECT 'B.Post_Birthday_Bear' AS time_period,
	   CONCAT(FORMAT(COUNT(DISTINCT o.order_id)/COUNT(DISTINCT w.website_session_id)*100,2),'%') AS conv_rate,
       ROUND(SUM(price_usd)/COUNT(DISTINCT o.order_id),2) AS aov,
       ROUND(SUM(o.items_purchased)/COUNT(DISTINCT o.order_id),2) AS products_per_order,
       ROUND(SUM(price_usd)/COUNT(DISTINCT w.website_session_id),2) AS rev_per_sessions
FROM website_pageviews w
LEFT JOIN orders o 
ON o.website_session_id = w.website_session_id AND w.pageview_url = '/billing-2'
LEFT JOIN (SELECT website_session_id, created_at AS cart_time FROM website_pageviews WHERE pageview_url = '/cart') t 
ON t.website_session_id = w.website_session_id
WHERE w.created_at BETWEEN '2013-12-12' AND '2014-01-12';




