-- CASE1_Traffic Analysis & Optimization

/*
Request 1 from Cindy (CEO) April 12, 2012
We've been live for almost a month now and we’re starting to generate sales. Can you help me understand where the bulk of our 
website sessions are coming from, through yesterday? I’d like to see a breakdown by UTM source, campaign and referring domain 
if possible. 
*/ 

SELECT 
	utm_source, 
	utm_campaign, 
	http_referer, 
COUNT(DISTINCT website_session_id) AS total_session
FROM website_sessions
WHERE DATE(created_at) < "2012-4-12"
GROUP BY utm_source, utm_campaign, http_referer
ORDER BY total_session DESC;


/*
Request 2 from Tom (Marketing Director) April 14, 2012
Sounds like gsearch nonbrand is our major traffic source, but we need to understand if those sessions are driving sales.
Could you please calculate the conversion rate (CVR) from session to order? Based on what we're paying for clicks, we’ll 
need a CVR of at least 4% to make the numbers work.If we're much lower, we’ll need to reduce bids. If we’re higher, we can 
increase bids to drive more volume.
*/ 

SELECT
	COUNT(DISTINCT o.order_id) AS total_orders,
	COUNT(DISTINCT w.website_session_id) AS total_session,
CONCAT(FORMAT(COUNT(DISTINCT o.order_id)/COUNT(DISTINCT w.website_session_id) *100, 2), '%') AS sessions_orders_CVR
FROM website_sessions w
LEFT JOIN orders o USING (website_session_id)
WHERE utm_source = "gsearch" 
AND utm_campaign = "nonbrand" 
	AND DATE(w.created_at) < "2012-4-14";


/*
Request 3 from Tom (Marketing Director) May 12, 2012 
Based on your conversion rate analysis, we bid down gsearch nonbrand on 2012-04-15. Can you pull gsearch nonbrand trended session 
volume, by week, to see if the bid changes have caused volume to drop at all?
*/ 

SELECT  MIN(DATE(created_at)) AS week_start_date,
		COUNT(DISTINCT website_session_id) AS sessions
FROM website_sessions
WHERE created_at < "2012-5-12" 
	AND utm_source = "gsearch" 
	AND utm_campaign = "nonbrand"
GROUP BY YEARWEEK(created_at);


/*
Request 4 from Tom (Marketing Director) May 11, 2012
I was trying to use our site on my mobile device the other day, and the experience was not great. Could you pull conversion rates 
from session to order, by device type? If desktop performance is better than on mobile we may be able to bid up for desktop specifically 
to get more volume?
*/ 

SELECT device_type,
	   COUNT(DISTINCT w.website_session_id) AS sessions,
	   COUNT(DISTINCT o.order_id) AS orders,
       CONCAT(FORMAT(COUNT(DISTINCT o.order_id)/COUNT(DISTINCT w.website_session_id) *100, 2), '%') AS CVR
FROM website_sessions w
LEFT JOIN orders o
USING (website_session_id)
WHERE DATE(w.created_at) < "2012-05-11" AND utm_source = "gsearch" AND utm_campaign = "nonbrand"
GROUP BY device_type
ORDER BY CVR desc;


/*
Request 5 from Tom (Marketing Director) June 09, 2012
After your device-level analysis of conversion rates, we realized desktop was doing well, so we bid our gsearch nonbrand desktop 
campaigns up on 2012-05-19. Could you pull weekly trends for both desktop and mobile so we can see the impact on volume? You can 
use 2012-04-15 until the bid change as a baseline.
*/ 

SELECT MIN(DATE(created_at)) AS start_date,
	   COUNT(DISTINCT CASE WHEN device_type = "desktop" THEN website_session_id ELSE NULL END) AS dtop_sessions,
	   COUNT(DISTINCT CASE WHEN device_type = "mobile" THEN website_session_id ELSE NULL END) AS mob_sessions	   
FROM website_sessions
WHERE DATE(created_at)  BETWEEN  "2012-04-15" AND "2012-06-08"
AND utm_source = "gsearch" 
AND utm_campaign = "nonbrand"
GROUP BY YEARWEEK(created_at);
