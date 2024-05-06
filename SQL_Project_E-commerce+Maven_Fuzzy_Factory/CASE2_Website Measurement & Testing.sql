-- CASE2_Website Measurement & Testing

/*
Request 1 from Morgan Rockwell (Website Manager) June 09, 2012
Could you help me get my head around the site by pulling the most-viewed website pages, ranked by session volume?
*/ 

SELECT pageview_url,
	   COUNT(DISTINCT website_session_id) AS sessions
FROM website_pageviews
WHERE  created_at < "2012-06-09" 
GROUP BY pageview_url
ORDER BY sessions DESC;


/*
Request 2 from Morgan Rockwell (Website Manager) June 12, 2012
Would you be able to pull a list of the top entry pages? I want to confirm where our users are hitting the site. If you could pull 
all entry pages and rank them on entry volume, that would be great.
*/ 

SELECT pageview_url, COUNT(DISTINCT website_session_id) AS sessions_hitting_this_landing_page
FROM website_pageviews
WHERE (website_session_id, website_pageview_id) in (
		SELECT  website_session_id, MIN(website_pageview_id) as  website_pageview_id
		FROM website_pageviews
		WHERE created_at < "2012-06-12"
		GROUP BY website_session_id
		)
GROUP BY pageview_url;


/*
Request 3 from Morgan Rockwell (Website Manager) June 14, 2012
The other day you showed us that all of our traffic is landing on the homepage right now. We should check how that landing page is 
performing. Can you pull bounce rates for traffic landing on the homepage? I would like to see three  numbers…Sessions, Bounced 
Sessions, and % of Sessions which Bounced (aka “Bounce Rate”).
*/ 

SELECT pageview_url, 
	   COUNT(DISTINCT website_session_id) AS sessions,
       COUNT(bounced_sessions) AS bounced_sessions,
       CONCAT(FORMAT(COUNT(bounced_sessions)/COUNT(DISTINCT website_session_id) *100, 2), '%') AS bounce_rate
FROM website_pageviews
LEFT JOIN (SELECT website_session_id, "yes" AS bounced_sessions
		FROM website_pageviews
		WHERE created_at < "2012-06-14"
		GROUP BY website_session_id
		HAVING COUNT(website_session_id) = 1) AS subquery
USING (website_session_id)
WHERE (website_session_id, website_pageview_id) in (
		SELECT  website_session_id, MIN(website_pageview_id) as  website_pageview_id
		FROM website_pageviews
		WHERE created_at < "2012-06-14"
		GROUP BY website_session_id
		)
GROUP BY pageview_url;


/*
Request 4 from Morgan Rockwell (Website Manager) July 28, 2012
Based on your bounce rate analysis, we ran a new custom landing page (/lander-1) in a 50/50 test against the homepage (/home) for 
our gsearch nonbrand traffic. Can you pull bounce rates for the two groups so we can evaluate the new page? Make sure to just look 
at the time period where /lander-1 was getting traffic, so that it is a fair comparison.
*/ 

SELECT wp.pageview_url, 
	   COUNT(DISTINCT wp.website_session_id) AS sessions,
       COUNT(bounced_sessions) AS bounced_sessions,
       CONCAT(FORMAT(COUNT(bounced_sessions)/COUNT(DISTINCT wp.website_session_id) *100, 2), '%') AS bounce_rate
FROM website_pageviews wp
LEFT JOIN (SELECT website_session_id, "yes" AS bounced_sessions
		FROM website_pageviews
		WHERE  created_at BETWEEN (SELECT MIN(created_at) FROM website_pageviews WHERE pageview_url = "/lander-1") AND "2012-07-28"
		GROUP BY website_session_id
		HAVING COUNT(website_session_id) = 1) AS subquery
USING (website_session_id)
JOIN website_sessions ws
		USING(website_session_id)
WHERE (website_session_id, website_pageview_id) in (
		SELECT  website_session_id, MIN(website_pageview_id) as  website_pageview_id
		FROM website_pageviews
		WHERE  created_at BETWEEN (SELECT MIN(created_at) FROM website_pageviews WHERE pageview_url = "/lander-1") AND "2012-07-28"
		GROUP BY website_session_id
		) 
        AND wp.created_at BETWEEN (SELECT MIN(created_at) FROM website_pageviews WHERE pageview_url = "/lander-1") AND "2012-07-28"
		AND utm_source = "gsearch"
		AND utm_campaign = "nonbrand"
GROUP BY pageview_url;    


/*
Request 5 from Morgan Rockwell (Website Manager) August 31, 2012
Could you pull the volume of paid search nonbrand traffic landing on /home and /lander-1, trended weekly since June 1st? I want 
to confirm the traffic is all routed correctly. Could you also pull our overall paid search bounce rate trended weekly? I want to 
make sure the lander change has improved the overall picture.
*/ 

SELECT MIN(Date(wp.created_at)) AS week_start_date,
       CONCAT(FORMAT(COUNT(bounced_sessions)/COUNT(DISTINCT wp.website_session_id) *100, 2), '%') AS bounce_rate,
	   COUNT(DISTINCT CASE WHEN wp.pageview_url = '/home' THEN wp.website_session_id END) AS home_sessions,
       COUNT(DISTINCT CASE WHEN wp.pageview_url = '/lander-1' THEN wp.website_session_id END) AS lander_sessions
FROM website_pageviews wp
LEFT JOIN (SELECT website_session_id, "yes" AS bounced_sessions
		FROM website_pageviews
		WHERE created_at BETWEEN  "2012-06-01" AND "2012-08-31"
		GROUP BY website_session_id
		HAVING COUNT(website_session_id) = 1) AS subquery
USING (website_session_id)
JOIN website_sessions ws
		USING(website_session_id)
WHERE (website_session_id, website_pageview_id) in (
		SELECT  website_session_id, MIN(website_pageview_id) as  website_pageview_id
		FROM website_pageviews
		WHERE created_at BETWEEN "2012-06-01" AND "2012-08-31"
		GROUP BY website_session_id
		) 
        AND wp.created_at BETWEEN "2012-06-01" AND "2012-08-31"
		AND utm_source = "gsearch"
        AND utm_campaign = "nonbrand"
GROUP BY WEEK(wp.created_at);    


/*
Request 1 from Morgan Rockwell (Website Manager) September 05, 2012
I’d like to understand where we lose our gsearch visitors between the new /lander-1 page and placing an order. Can you build us a 
full conversion funnel, analyzing how many customers make it to each step? Start with /lander-1 and build the funnel all the way to 
ourthank you page. Please use data since August 5th.
*/ 

SELECT sessions,
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
		WHERE ws.created_at BETWEEN "2012-08-05" AND "2012-09-05" 
			  AND ws.utm_source = "gsearch"
			  AND ws.utm_campaign = "nonbrand"
			  AND pageview_url in ('/lander-1', '/products', '/the-original-mr-fuzzy', '/cart', '/shipping', '/billing', '/thank-you-for-your-order')
		) AS subquery;


/*
Request 1 from Cindy (CEO) November 10, 2012
We tested an updated billing page based on your funnel analysis. Can you take a look and see whether /billing-2 is doing any better 
than the original /billing page? We’re wondering what % of sessions on those pages end up placing an order. FYI – we ran this test 
for all traffic, not just for our search visitors.
*/ 

SELECT  pageview_url AS billing_version_seen,
		COUNT(DISTINCT website_session_id) AS session,
		COUNT(orders) AS orders,
        CONCAT(FORMAT(COUNT(orders) /COUNT(DISTINCT website_session_id) * 100, 2), '%')AS billing_to_order_rt
FROM website_pageviews
LEFT JOIN (
		SELECT website_session_id, "with_order" AS orders
		FROM website_pageviews
		WHERE created_at BETWEEN (SELECT MIN(created_at) FROM website_pageviews WHERE pageview_url = '/billing-2') AND '2012-11-10'
			  AND pageview_url = '/thank-you-for-your-order'
		 ) AS subquery
USING (website_session_id)
WHERE created_at BETWEEN (SELECT MIN(created_at) FROM website_pageviews WHERE pageview_url = '/billing-2') AND '2012-11-10'
      AND pageview_url IN ('/billing', '/billing-2')
GROUP BY pageview_url;

