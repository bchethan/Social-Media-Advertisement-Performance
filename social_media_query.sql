-- Total number of users
SELECT DISTINCT COUNT(*) 
FROM users;

-- Total number of campaigns
SELECT DISTINCT COUNT(*) 
FROM campaigns;

-- Number of ads in each campaign
SELECT name, 
       COUNT(*) AS no_of_ads
FROM campaigns c 
JOIN ads a 
	ON a.campaign_id = c.campaign_id
GROUP BY name;

-- Gender distribution
SELECT user_gender, 
	   ROUND(COUNT(*) * 100/(SELECT COUNT(*) FROM users),2) AS percentage
FROM users
GROUP BY user_gender;

-- Users by country
SELECT country,
	   COUNT(*) AS total_users
FROM users
GROUP BY country;

-- Average age of users
SELECT ROUND(AVG(user_age)) AS avg_age FROM users;

-- Top 10 oldest users
SELECT user_id 
FROM users
ORDER BY user_age DESC
LIMIT 10;

-- Campaign budget analysis: Find minimum, maximum, and average campaign budget.
SELECT MIN(total_budget) AS minimum, 
	   MAX(total_budget) AS maximum, 
	   ROUND(AVG(total_budget),2) AS average 
FROM campaigns;

-- Total ad events
SELECT COUNT(*) AS total_ad_events 
FROM ad_events;

-- Event type distribution
-- Count how many Impressions, Clicks, Purchases, Likes, etc. occurred.
SELECT event_type, 
	   COUNT(*) AS event_count
FROM ad_events
GROUP BY event_type;

-- Campaign with highest budget
SELECT * 
FROM campaigns
ORDER BY total_budget DESC
LIMIT 1;

-- Campaign with longest duration
SELECT * 
FROM campaigns
ORDER BY duration_days DESC
LIMIT 1;

-- Average budget by campaign type
SELECT campaign_type, 
	   ROUND(AVG(total_budget))
FROM campaigns
GROUP BY campaign_type;

ALTER TABLE campaigns
ADD COLUMN campaign_type VARCHAR(25) AFTER name;

UPDATE campaigns
SET campaign_type = REGEXP_REPLACE(name, 'Campaign_[0-9]+_', '');

-- Number of users interested in each category
SELECT interests, 
	   COUNT(*) AS no_of_users
FROM users
GROUP BY interests;

-- Which gender clicks ads the most?
SELECT user_gender, COUNT(*) AS clicks
FROM users u 
JOIN ad_events ae
	ON ae.user_id = u.user_id
WHERE event_type = 'Click'
GROUP BY user_gender
ORDER BY clicks DESC;

-- Which country has the highest purchase count?
SELECT country, 
	   COUNT(*) AS purchase_count
FROM ad_events ae
JOIN users u
	ON ae.user_id = u.user_id
WHERE event_type = 'Purchase'
GROUP BY country
ORDER BY purchase_count DESC
LIMIT 1;

-- Most active users
SELECT user_id, 
	   COUNT(*) AS no_of_events 
FROM ad_events
GROUP BY user_id
ORDER BY no_of_events DESC
LIMIT 10;

-- Top 10 ads by total clicks
SELECT ad_id, 
	   COUNT(*) AS total_clicks
FROM ad_events
WHERE event_type = 'Click'
GROUP BY ad_id
ORDER BY total_clicks DESC;

-- Top campaigns by purchases
SELECT c.name, COUNT(*) AS total_purchases
FROM ad_events ae
JOIN ads a
	ON a.ad_id = ae.ad_id
JOIN campaigns c 
	ON c.campaign_id = a.campaign_id
WHERE event_type = 'Purchase'
GROUP BY c.name
ORDER BY total_purchases DESC
LIMIT 10;

-- Average age of purchasing users
SELECT AVG(user_age) AS avg_age_of_purchasing_user
FROM ad_events ae
JOIN users u
	ON u.user_id = ae.user_id
WHERE event_type = 'Purchase';

-- Which age group generates the most purchases?
SELECT age_group, COUNT(*) AS total_purchases
FROM ad_events ae
JOIN users u
	ON u.user_id = ae.user_id
WHERE event_type = 'Purchase'
GROUP BY age_group
ORDER BY total_purchases DESC
LIMIT 1;

-- Event count by weekday
SELECT day_of_week, 
	   COUNT(*) AS event_count
FROM ad_events
WHERE day_of_week NOT IN ('Saturday','Sunday')
GROUP BY day_of_week;

-- Monthly campaign performance
SELECT EXTRACT(YEAR FROM ae.timestamp) AS year,
	   EXTRACT(MONTH FROM ae.timestamp) AS month,
	   c.name,
       COUNT(*) AS total
FROM ad_events ae
JOIN ads a 
	ON a.ad_id = ae.ad_id
JOIN campaigns c
	ON c.campaign_id = a.campaign_id
WHERE event_type = 'Purchase'
GROUP BY EXTRACT(MONTH FROM ae.timestamp), EXTRACT(YEAR FROM ae.timestamp), c.name, event_type
ORDER BY name, year, month
LIMIT 10;

-- Average events per campaign
WITH total_events_per_campaign_cte AS
(
SELECT name, 
	   COUNT(*) AS total_events
FROM ad_events ae 
JOIN ads a 
	ON a.ad_id = ae.ad_id
JOIN campaigns c
	ON c.campaign_id = a.campaign_id
GROUP BY name
)
SELECT ROUND(AVG(total_events)) AS avg_events_per_campaign
FROM total_events_per_campaign_cte;

-- Which interests generate the highest purchases?
SELECT interests, 
	   COUNT(*) AS total_purchases
FROM users u
JOIN ad_events ae
	ON u.user_id = ae.user_id
WHERE event_type = 'Purchase'
GROUP BY interests
ORDER BY total_purchases DESC
LIMIT 1;

-- Advanced SQL 
-- Conversion Funnel
-- Calculate: Impressions, Clicks, Add to Cart,  Purchases for each campaign.
SELECT name,
	   SUM(CASE WHEN event_type = 'Impression' THEN 1 ELSE 0 END) AS impressions,
	   SUM(CASE WHEN event_type = 'Click' THEN 1 ELSE 0 END) AS clicks,
	   SUM(CASE WHEN event_type = 'Like' THEN 1 ELSE 0 END) AS likes,
	   SUM(CASE WHEN event_type = 'Purchase' THEN 1 ELSE 0 END) AS purchases
FROM ad_events ae
JOIN ads a
	ON a.ad_id = ae.ad_id
JOIN campaigns c
	ON c.campaign_id = a.campaign_id
GROUP BY name;

-- Conversion Rate
-- Conversion Rate = Purchases / Clicks * 100
WITH campaign_conversion_cte AS (
SELECT name, 
       SUM(CASE WHEN event_type = 'Click' THEN 1 ELSE 0 END) AS clicks,
	   SUM(CASE WHEN event_type = 'Purchase' THEN 1 ELSE 0 END) AS purchases
FROM ad_events ae
JOIN ads a 
	ON ae.ad_id = a.ad_id
JOIN campaigns c
	ON c.campaign_id = a.campaign_id
WHERE event_type IN ('Purchase', 'Click')
GROUP BY name
)
SELECT name, 
	   ROUND(purchases*100.0 / NULLIF(clicks, 0), 2) AS conversion_rate 
FROM campaign_conversion_cte;

-- CTR (Click Through Rate)
-- CTR = Clicks / Impressions * 100
WITH click_through_rate_cte AS(
SELECT name, 
	   SUM(CASE WHEN event_type = 'Impression' THEN 1 ELSE 0 END)AS impressions,
	   SUM(CASE WHEN event_type = 'Click' THEN 1 ELSE 0 END) AS clicks
FROM ad_events ae
JOIN ads a 
	ON a.ad_id = ae.ad_id
JOIN campaigns c
	ON c.campaign_id = a.campaign_id
WHERE event_type IN ('Click','Impression')
GROUP BY name
)
SELECT name, ROUND(clicks*100.0/NULLIF(impressions,0)) AS ctr
FROM click_through_rate_cte;

-- Best performing ad
-- Rank ads using
-- Clicks
-- Purchases
-- Conversion Rate
WITH ad_performance_cte AS (
SELECT ad_id,
	   SUM(CASE WHEN event_type = "Purchase" THEN 1 ELSE 0 END) AS purchase,
	   SUM(CASE WHEN event_type = "Click" THEN 1 ELSE 0 END) AS click
FROM ad_events 
WHERE event_type IN ("Click", "Purchase")
GROUP BY ad_id
)
SELECT ad_id, 
	   purchase, 
       click, 
       ROUND(purchase*100.0/NULLIF(click, 0), 2) AS conversion_rate,
       ROW_NUMBER() OVER(ORDER BY purchase*100.0/NULLIF(click, 0) DESC, purchase, click) AS ranked_ads
FROM ad_performance_cte;

-- Worst performing campaigns
-- Find campaigns with
-- High budget
-- Very low purchases

SELECT name, 
	   total_budget,
       COUNT(CASE WHEN event_type = 'Purchase' THEN 1 END) AS purchases,
       COUNT(CASE WHEN event_type = 'Purchase' THEN 1 END)*1.0/total_budget AS purchase_rate
FROM campaigns c
JOIN ads a 
	ON c.campaign_id = a.campaign_id
JOIN ad_events ae
	ON ae.ad_id = a.ad_id
WHERE total_budget >= 10000
GROUP BY name, total_budget
ORDER BY purchase_rate
LIMIT 10;

-- Top spending campaigns
-- Rank campaigns using
-- RANK()
SELECT name, 
	   RANK() OVER(ORDER BY total_budget DESC) AS top_spending_rank
FROM campaigns
LIMIT 10;

-- Dense ranking of ads by clicks
-- Use DENSE_RANK()
SELECT ad_id, 
	   COUNT(*) AS clicks, 
       DENSE_RANK() OVER(ORDER BY COUNT(*) DESC) AS ranking_by_clicks
FROM ad_events 
WHERE event_type = "Click"
GROUP BY ad_id
LIMIT 10;

-- Find duplicate users (if any)
-- Using
-- GROUP BY
-- HAVING COUNT(*) > 1
SELECT user_id
FROM users
GROUP BY user_id
HAVING COUNT(*) > 1;

-- User retention
-- Find users who interacted with ads on multiple days.
SELECT u.user_id, 
	   COUNT(*) AS interactions
FROM users u 
JOIN ad_events ae
	ON u.user_id = ae.user_id 
GROUP BY u.user_id
HAVING interactions > 1 AND COUNT(DISTINCT DATE(timestamp)) > 1
LIMIT 10;

-- First interaction date of every user
-- Using
-- MIN(event_date)
SELECT u.user_id, 
	   MIN(timestamp) AS first_interaction
FROM ads a 
JOIN ad_events ae
	ON ae.ad_id = a.ad_id
JOIN users u 
	ON u.user_id = ae.user_id
GROUP BY u.user_id;

-- Last interaction date of every user
SElECT u.user_id, 
	   MAX(timestamp) AS last_interaction
FROM ads a 
JOIN ad_events ae
	ON a.ad_id = ae.ad_id
JOIN users u 
	ON u.user_id = ae.user_id
GROUP BY u.user_id;

-- Country-wise conversion rate
WITH country_wise_cte AS (
SELECT country,
	   COUNT(CASE WHEN event_type = "Click" THEN 1 END) AS clicks,
       COUNT(CASE WHEN event_type = "Purchase" THEN 1 END) AS purchases
FROM users u 
JOIN ad_events ae
	ON u.user_id = ae.user_id
GROUP BY country
)
SELECT country, 
	   ROUND(purchases*100.0/NULLIF(clicks,0),2) AS conversion_rate 
FROM country_wise_cte;

-- Gender-wise conversion rate
WITH gender_wise_cte AS (
SELECT user_gender, 
	   COUNT(CASE WHEN event_type = "Click" THEN 1 END) AS clicks,
       COUNT(CASE WHEN event_type = "Purchase" THEN 1 END) AS purchases
FROM users u 
JOIN ad_events ae
	ON ae.user_id = u.user_id
GROUP BY user_gender
)
SELECT user_gender, 
	   ROUND(purchases*100.0/clicks, 2) AS conversion_rate 
FROM gender_wise_cte;

-- Top 5 countries by campaign performance
SELECT country, 
	   COUNT(*) AS performance
FROM ad_events ae
JOIN ads a 
	ON a.ad_id = ae.ad_id
JOIN campaigns c
	ON c.campaign_id = a.campaign_id
JOIN users u 
	ON u.user_id = ae.user_id
WHERE event_type IN ("Purchase")
GROUP BY country
ORDER BY performance DESC
LIMIT 5;

-- Best target age group
-- Find the age group with the highest purchase rate.
SELECT u.age_group,
	ROUND(COUNT(CASE WHEN ae.event_type = "Purchase" THEN 1 END)*100.0/
		(SELECT COUNT(*) FROM ad_events WHERE event_type = "Purchase"),2) AS purchase_rate
FROM users u 
JOIN ad_events ae
	ON u.user_id = ae.user_id
GROUP BY age_group
ORDER BY purchase_rate DESC
LIMIT 1;

-- Highest engagement hour
-- Find the hour with the most user interactions.
SELECT HOUR(timestamp) AS hour, 
	   COUNT(*) AS interactions 
FROM ad_events
GROUP BY HOUR(timestamp)
ORDER BY interactions DESC
LIMIT 1;

-- User segmentation
-- Create segments such as:
-- High Engagement
-- Medium Engagement
-- Low Engagement 
-- based on the number of events. 
WITH user_engagement_cte AS (
	SELECT user_id, 
		   COUNT(*) AS interactions
	FROM ad_events
	GROUP BY user_id
	ORDER BY interactions
)
SELECT user_id, interactions,
		CASE WHEN interactions <= 30 THEN 'Low Engagement' 
			 WHEN interactions <= 50 THEN 'Medium Engagement' 
			ELSE 'High Engagement'END AS user_engagement
FROM user_engagement_cte;

-- Rank campaigns by purchases within each country
SELECT country, 	
	   name, 
       COUNT(*) AS total_purchases, 
       RANK() OVER(
					PARTITION BY country 
                    ORDER BY COUNT(*) DESC
				  ) AS campaign_rank
FROM campaigns c
JOIN ads a 
	ON a.campaign_id = c.campaign_id
JOIN ad_events ae
	ON ae.ad_id = a.ad_id
JOIN users u 
	ON u.user_id = ae.user_id
WHERE event_type = 'Purchase'
GROUP BY country, name;

-- Find users whose purchases are above the average: Use a subquery or CTE.
-- using subquery
SELECT user_id, 
	   total_purchase FROM (
	SELECT user_id, 
		   COUNT(*) AS total_purchase, 
           AVG(COUNT(*)) OVER() AS avg_purchase
	FROM ad_events
	WHERE event_type = 'Purchase'
	GROUP BY user_id
) AS user_purchases
WHERE total_purchase > avg_purchase;

-- using cte
WITH user_purchase_cte AS(
	SELECT user_id, 
		   COUNT(*) AS purchase_count,
		   AVG(COUNT(*)) OVER() AS avg_purchase
	FROM ad_events
	WHERE event_type = 'Purchase'
	GROUP BY user_id
)
SELECT user_id,
	   purchase_count
FROM user_purchase_cte
WHERE purchase_count > avg_purchase;

-- Top 3 ads in every campaign Use ROW_NUMBER()
WITH ads_ranked_cte AS(
	SELECT name, 
		   a.ad_id,
		   COUNT(*) AS purchases,
		   ROW_NUMBER() OVER(
				PARTITION BY c.name 
				ORDER BY COUNT(*) DESC
			) AS ads_rank
	FROM campaigns c
	JOIN ads a
		ON a.campaign_id = c.campaign_id
	JOIN ad_events ae
		ON ae.ad_id = a.ad_id
	WHERE ae.event_type = 'Purchase'
	GROUP BY name, a.ad_id
)
SELECT name, 
	   ad_id,
       purchases,
       ads_rank
FROM ads_ranked_cte 
WHERE ads_rank <= 3
ORDER BY name, ads_rank;

-- Cumulative purchases over time
WITH campaign_purchases_cte AS (
	SELECT name, 
		   DATE_FORMAT(ae.timestamp, '%Y-%m') AS purchased_time, 
		   COUNT(*) AS purchases
	FROM ad_events ae
	JOIN ads a
		ON a.ad_id = ae.ad_id
	JOIN campaigns c
		ON c.campaign_id = a.campaign_id
	WHERE event_type = 'Purchase'
	GROUP BY name, DATE_FORMAT(ae.timestamp, '%Y-%m')
	ORDER BY name, purchased_time
)
SELECT name, 
	   purchased_time, 
       purchases, 
       SUM(purchases) OVER(
				PARTITION BY name 
                ORDER BY purchases DESC
	   ) AS cumulative_sum
FROM campaign_purchases_cte;

-- Campaign performance dashboard
-- Create a query that returns: Campaign Name, Budget, Total Ads, Impressions, Clicks, Purchases, CTR, Conversion Rate, Ranking
WITH campaign_details_cte AS (
SELECT name, 
	   total_budget, 
	   COUNT(DISTINCT a.ad_id) AS total_ads, 
       SUM(CASE WHEN event_type = 'Impression' THEN 1 ELSE 0 END) AS impressions,
       SUM(CASE WHEN event_type = 'Click' THEN 1 ELSE 0 END) AS clicks,
       SUM(CASE WHEN event_type = 'Purchase' THEN 1 ELSE 0 END) AS purchases
FROM campaigns c
JOIN ads a 
	ON a.campaign_id = c.campaign_id
JOIN ad_events ae
	ON ae.ad_id = a.ad_id
GROUP BY name, total_budget
)
SELECT name,
	   total_ads,
	   total_budget, 
       impressions, 
       clicks, 
       purchases, 
	   ROUND(clicks*100.0/NULLIF(impressions, 0), 2) AS CTR, 
       ROUND(purchases*100.0/NULLIF(clicks, 0), 2) AS conversion_rate,
       RANK() OVER(
			ORDER BY purchases*1.0/NULLIF(clicks, 0) DESC
		) AS conversion_rank
FROM campaign_details_cte;