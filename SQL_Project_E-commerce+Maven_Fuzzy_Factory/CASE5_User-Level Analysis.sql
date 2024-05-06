-- CASE5_User-Level Analysis

/*
Request 1 from Tom Parmesan (Marketing Director) November 01, 2014
We’ve been thinking about customer value based solely on their first session conversion and revenue. But if customers have repeat 
sessions, they may be more valuable than we thought. If that’s the case, we might be able to spend a bit more to acquire them.
Could you please pull data on how many of our website visitors come back for another session? 2014 to date is good.
*/ 

SELECT repeat_sessions, COUNT(DISTINCT user_id) AS users
FROM(
		SELECT t.user_id, 
			   COUNT(DISTINCT w.website_session_id) AS repeat_sessions
		FROM(
		SELECT *
		FROM website_sessions
		WHERE is_repeat_session = 0 
			  AND created_at BETWEEN '2014-01-01' AND '2014-11-01'  -- 先把目标时间段有新的会话的用户跳出来
		) AS t
		LEFT JOIN website_sessions w -- 不会减少，反而会增加，因为user_id是同事两边的主键
		ON t.user_id = w.user_id
			AND w.created_at BETWEEN '2014-01-01' AND '2014-11-01'  -- 先把目标时间段有新的会话的用户跳出来
			AND w.is_repeat_session = 1
		GROUP BY t.user_id
) s
GROUP BY repeat_sessions;


/*
Request 2 from Tom Parmesan (Marketing Director) November 03, 2014
Now you’ve got me curious to better understand the behavior of these repeat customers. Could you help me understand the minimum, 
maximum, and average time between the first and second session for customers who do come back? Again, analyzing 2014 to date is 
probably the right time period.
*/ 

SELECT AVG(DATEDIFF(second_date,first_date)) AS avg,
	   MIN(DATEDIFF(second_date,first_date)) AS min, 
	   MAX(DATEDIFF(second_date,first_date)) AS max
FROM(SELECT user_id, created_at AS first_date
	FROM website_sessions
	WHERE is_repeat_session = 0 
	AND created_at BETWEEN '2014-01-01' AND '2014-11-03'  
) AS f
JOIN 
(SELECT user_id, MIN(created_at) AS second_date
	FROM website_sessions
	WHERE is_repeat_session = 1 
		AND created_at BETWEEN '2014-01-01' AND '2014-11-03'
	GROUP BY user_id
) AS s
USING (user_id);


/*
Request 3 from Morgan Rockwell (Website Manager) November 08, 2014
Sounds like you and Tom have learned a lot about our repeat customers. Can I trouble you for one more thing? I’d love to do a 
comparison of conversion rates and revenue per session for repeat sessions vs new sessions. Let’s continue using data from 2014, 
year to date.
*/ 

SELECT is_repeat_session,
	   COUNT(DISTINCT w.website_session_id) AS sessions,
       CONCAT(FORMAT(COUNT(DISTINCT o.order_id)/COUNT(DISTINCT w.website_session_id)*100,2),'%') AS cvr,
       ROUND(SUM(o.price_usd)/COUNT(DISTINCT w.website_session_id),2) AS rev_per_session
FROM website_sessions w
LEFT JOIN orders o
USING (website_session_id)
WHERE w.created_at BETWEEN '2014-01-01' AND '2014-11-08'
GROUP BY is_repeat_session;

