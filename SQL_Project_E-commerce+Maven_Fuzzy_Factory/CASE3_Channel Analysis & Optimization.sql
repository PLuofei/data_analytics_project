-- CASE3_Channel Analysis & Optimization

/*
Request 1 from Tom Parmesan (Marketing Director) November 29, 2012
With gsearch doing well and the site performing better, we launched a second paid search channel, bsearch, around August 22.
Can you pull weekly trended session volume since then and compare to gsearch nonbrand so I can get a sense for how important 
this will be for the business?
*/ 

SELECT MIN(DATE(created_at)) AS week_start_date,
	   COUNT(DISTINCT CASE WHEN utm_source = 'gsearch' THEN website_session_id END) AS gsearch_sessions,
       COUNT(DISTINCT CASE WHEN utm_source = 'bsearch' THEN website_session_id END) AS bsearch_sessions
FROM website_sessions
WHERE created_at BETWEEN '2012-08-22' AND '2012-11-29' 
	  AND utm_campaign = "nonbrand"
GROUP BY WEEK(created_at);


/*
Request 2 from Tom Parmesan (Marketing Director) November 30, 2012
I’d like to learn more about the bsearch nonbrand campaign. Could you please pull the percentage of traffic coming on Mobile, 
and compare that to gsearch? Feel free to dig around and share anything else you find interesting. Aggregate data since August 
22nd is great, no need to show trending at this point.
*/ 

SELECT utm_source,
	   COUNT(DISTINCT website_session_id) AS sessions,
	   COUNT(DISTINCT CASE WHEN device_type = "mobile" THEN website_session_id ELSE NULL END ) AS mobile_session,
       CONCAT(FORMAT(COUNT(DISTINCT CASE WHEN device_type = "mobile" THEN website_session_id ELSE NULL END) 
       / COUNT(DISTINCT website_session_id) * 100,2), "%") AS pct_session
FROM website_sessions
WHERE created_at  > '2012-08-22' 
	  AND created_at  < '2012-11-30' 
	  AND utm_campaign = "nonbrand" 
      AND (utm_source = "bsearch" OR utm_source = "gsearch") 
GROUP BY utm_source;


/*
Request 3 from Tom Parmesan (Marketing Director) December 01, 2012
I’m wondering if bsearch nonbrand should have the same bids as gsearch. Could you pull nonbrand conversion rates from session to 
order for gsearch and bsearch, and slice the data by device type? Please analyze data from August 22 to September 18; we ran a 
special pre-holiday campaign for gsearch starting on September 19th, so the data after that isn’t fair game.
*/ 

SELECT w.device_type,
	   w.utm_source,
	   COUNT(DISTINCT w.website_session_id) AS sessions,
	   COUNT(DISTINCT o.order_id) AS orders,
       CONCAT(FORMAT(COUNT(DISTINCT order_id)/COUNT(DISTINCT website_session_id) * 100,2),"%") AS conv_rate
FROM website_sessions w
LEFT JOIN orders o 
USING (website_session_id) 
WHERE w.created_at BETWEEN '2012-08-22' AND '2012-09-18' 
	  AND w.utm_campaign = "nonbrand" 
	  AND (w.utm_source = "bsearch" OR w.utm_source = "gsearch") 
GROUP BY w.device_type, w.utm_source;


/*
Request 4 from Tom Parmesan (Marketing Director) December 22, 2012
Based on your last analysis, we bid down bsearch nonbrand on December 2nd. Can you pull weekly session volume for gsearch and bsearch 
nonbrand, broken down by device, since November 4th? If you can include a comparison metric to show bsearch as a percent of gsearch
for each device, that would be great too.
*/ 

SELECT MIN(DATE(created_at)) AS week_start_date,
	   COUNT(DISTINCT CASE WHEN utm_source = "gsearch" AND device_type = "desktop" THEN website_session_id ELSE NULL END) AS g_drop_sessions,
	   COUNT(DISTINCT CASE WHEN utm_source = "bsearch" AND device_type = "desktop" THEN website_session_id ELSE NULL END) AS g_drop_sessions,
	   CONCAT(FORMAT(COUNT(DISTINCT CASE WHEN utm_source = "bsearch" AND device_type = "desktop" THEN website_session_id ELSE NULL END) /
       COUNT(DISTINCT CASE WHEN utm_source = "gsearch" AND device_type = "desktop" THEN website_session_id ELSE NULL END)*100,2),"%") AS pct_1,
	   COUNT(DISTINCT CASE WHEN utm_source = "gsearch" AND device_type = "mobile" THEN website_session_id ELSE NULL END) AS g_drop_sessions,
	   COUNT(DISTINCT CASE WHEN utm_source = "bsearch" AND device_type = "mobile" THEN website_session_id ELSE NULL END) AS g_drop_sessions,
	   CONCAT(FORMAT(COUNT(DISTINCT CASE WHEN utm_source = "bsearch" AND device_type = "mobile" THEN website_session_id ELSE NULL END) /
       COUNT(DISTINCT CASE WHEN utm_source = "gsearch" AND device_type = "mobile" THEN website_session_id ELSE NULL END)*100,2),"%") AS pct_2
FROM  website_sessions
WHERE created_at BETWEEN '2012-11-04' AND '2012-12-22'
	  AND utm_campaign = "nonbrand" 
GROUP BY YEARWEEK(created_at);


/*
Request 5 from Cindy Sharp (CEO) December 23, 2012
A potential investor is asking if we’re building any momentum with our brand or if we’ll need to keep relying on paid traffic.
Could you pull organic search, direct type in, and paid brand search sessions by month, and show those sessions as a % of paid search 
nonbrand?
*/ 

SELECT YEAR(created_at) AS yt,
	   MONTH(created_at) AS mo,
       COUNT(DISTINCT CASE WHEN utm_campaign = 'nonbrand' THEN website_session_id END) AS nonbrand,
       COUNT(DISTINCT CASE WHEN utm_campaign = 'brand' THEN website_session_id END) AS brand,
       CONCAT(FORMAT(COUNT(DISTINCT CASE WHEN utm_campaign = 'brand' THEN website_session_id END)/
       COUNT(DISTINCT CASE WHEN utm_campaign = 'nonbrand' THEN website_session_id END)*100,2),"%") AS brand_pct_of_nonbrand,
       COUNT(DISTINCT CASE WHEN utm_source IS NULL AND http_referer IS NULL THEN website_session_id END) AS direct,
	   CONCAT(FORMAT(COUNT(DISTINCT CASE WHEN utm_source IS NULL AND http_referer IS NULL THEN website_session_id END)/
       COUNT(DISTINCT CASE WHEN utm_campaign = 'nonbrand' THEN website_session_id END) *100,2),"%") AS direct_pct_of_nonbrand,
       COUNT(DISTINCT CASE WHEN utm_source IS NULL AND http_referer IS NOT NULL THEN website_session_id END) AS organic,
	   CONCAT(FORMAT(COUNT(DISTINCT CASE WHEN utm_source IS NULL AND http_referer IS NOT NULL THEN website_session_id END)/
       COUNT(DISTINCT CASE WHEN utm_campaign = 'nonbrand' THEN website_session_id END)*100,2),"%") AS organic_pct_of_nonbrand       
FROM website_sessions
WHERE created_at < '2012-12-23'
GROUP BY YEAR(created_at), MONTH(created_at);


/*
Request 6 from Cindy Sharp (CEO) January 02, 2013
2012 was a great year for us. As we continue to grow, we should take a look at 2012’s monthly and weekly volume patterns, 
to see if we can find any seasonal trends we should plan for in 2013. If you can pull session volume and order volume, that
would be excellent.
*/ 

SELECT YEAR(w.created_at) yt, 
	   MONTH(w.created_at) mo,
       COUNT(DISTINCT w.website_session_id) sessions,
       COUNT(DISTINCT o.order_id) orders
FROM website_sessions w
LEFT JOIN orders o
USING (website_session_id)
WHERE w.created_at < '2013-01-01'
GROUP BY YEAR(w.created_at), MONTH(w.created_at);

SELECT MIN(DATE(w.created_at)) week_start_date,
       COUNT(DISTINCT w.website_session_id) sessions,
       COUNT(DISTINCT o.order_id) orders
FROM website_sessions w
LEFT JOIN orders o
USING (website_session_id)
WHERE w.created_at < '2013-01-01'
GROUP BY YEARWEEK(w.created_at);


/*
Request 7 from Cindy Sharp (CEO) January 05, 2013 
We’re considering adding live chat support to the website to improve our customer experience. Could you analyze the average 
website session volume, by hour of day and by day week, so that we can staff appropriately? Let’s avoid the holiday time period 
and use a date range of Sep 15 - Nov 15, 2013.
*/ 

SELECT HOUR(created_at) AS hr,
	   ROUND(COUNT(DISTINCT CASE WHEN WEEKDAY(created_at) = 0 THEN website_session_id END)/
       COUNT( DISTINCT CASE WHEN WEEKDAY(created_at) = 0 THEN DATE(created_at) END), 1) AS mon,
	   ROUND(COUNT(DISTINCT CASE WHEN WEEKDAY(created_at) = 1 THEN website_session_id END)/
       COUNT( DISTINCT CASE WHEN WEEKDAY(created_at) = 1 THEN DATE(created_at) END), 1) AS tue,
	   ROUND(COUNT(DISTINCT CASE WHEN WEEKDAY(created_at) = 2 THEN website_session_id END)/
       COUNT( DISTINCT CASE WHEN WEEKDAY(created_at) = 2 THEN DATE(created_at) END), 1) AS wed,
	   ROUND(COUNT(DISTINCT CASE WHEN WEEKDAY(created_at) = 3 THEN website_session_id END)/
       COUNT( DISTINCT CASE WHEN WEEKDAY(created_at) = 3 THEN DATE(created_at) END), 1) AS thu,
	   ROUND(COUNT(DISTINCT CASE WHEN WEEKDAY(created_at) = 4 THEN website_session_id END)/
       COUNT( DISTINCT CASE WHEN WEEKDAY(created_at) = 4 THEN DATE(created_at) END), 1) AS fir,
	   ROUND(COUNT(DISTINCT CASE WHEN WEEKDAY(created_at) = 5 THEN website_session_id END)/
       COUNT( DISTINCT CASE WHEN WEEKDAY(created_at) = 5 THEN DATE(created_at) END), 1) AS sat,
	   ROUND(COUNT(DISTINCT CASE WHEN WEEKDAY(created_at) = 6 THEN website_session_id END)/
       COUNT( DISTINCT CASE WHEN WEEKDAY(created_at) = 6 THEN DATE(created_at) END), 1) AS sun
FROM website_sessions
WHERE created_at BETWEEN '2012-09-15' AND '2012-11-15'
GROUP BY HOUR(created_at);


