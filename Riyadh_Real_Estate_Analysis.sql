/*
===============================================================================
Project: Riyadh Real Estate Market Analysis
Author: Ziyad Alahmari
Date: February 2026
Description: 
    This script performs data cleaning, exploratory data analysis (EDA), 
    and advanced transformation on Riyadh real estate data.
    The output is used to feed a Power BI dashboard.
===============================================================================
*/

-- ---------------------------------------------------------
-- 1. DATA SETUP: Filtering for Target City
-- ---------------------------------------------------------
-- Create a dedicated table for Riyadh listings to improve query performance
CREATE TABLE riyadh_listings AS 
SELECT * FROM listings 
WHERE city = 'الرياض';


-- ---------------------------------------------------------
-- 2. DATA QUALITY CHECKS
-- ---------------------------------------------------------
-- Inspecting price ranges to identify potential outliers
SELECT 
    MIN(price) as min_price, 
    MAX(price) as max_price
FROM riyadh_listings;

-- Investigating extreme outliers (e.g., placeholder prices like 10 Billion)
SELECT title, price, area
FROM riyadh_listings
WHERE price = 10000000000;


-- ---------------------------------------------------------
-- 3. EXPLORATORY DATA ANALYSIS (EDA)
-- ---------------------------------------------------------

-- A. Price Analysis: Average price per district (Excluding outliers)
-- Filtering logic: Removing prices < 10k (likely errors) and > 50M (commercial/outliers)
SELECT 
    district,
    ROUND(AVG(price), 2) AS avg_price
FROM riyadh_listings
WHERE price > 10000 AND price < 50000000
GROUP BY district
ORDER BY avg_price DESC
LIMIT 5;

-- B. Meter Price Analysis: The true indicator of value
-- Using CTE to calculate meter price first, then aggregating
WITH meter_price_calc AS (
    SELECT 
        district, 
        price, 
        area, 
        (price / area) AS meter_price
    FROM riyadh_listings
    WHERE price > 10000 AND price < 50000000 AND area > 0 
)
SELECT 
    district, 
    ROUND(AVG(meter_price), 2) AS avg_meter_price
FROM meter_price_calc
GROUP BY district
ORDER BY avg_meter_price DESC
LIMIT 5;

-- C. Market Activity: Most active districts by number of listings
SELECT 
    district, 
    COUNT(*) AS listings_count, 
    ROUND(AVG(price), 2) AS avg_price
FROM riyadh_listings
WHERE price > 10000 AND price < 50000000
GROUP BY district 
ORDER BY listings_count DESC
LIMIT 5;


-- ---------------------------------------------------------
-- 4. DATA TRANSFORMATION (For Power BI Master Data)
-- ---------------------------------------------------------
-- Mapping numeric categories to meaningful Arabic labels
-- This query prepares the main dataset for the dashboard
SELECT 
    district,
    title,
    price,
    area,
    (price/area) as meter_price, -- Added metric for analysis
    CASE 
        WHEN category = '1' THEN 'شقة للإيجار'
        WHEN category = '2' THEN 'أرض للبيع'
        WHEN category = '3' THEN 'فيلا للبيع'
        WHEN category = '6' THEN 'شقة للبيع'
        ELSE 'غير معروف'
    END as property_type
FROM riyadh_listings 
WHERE price > 1000 AND area > 50;


-- ---------------------------------------------------------
-- 5. ADVANCED ANALYTICS (Window Functions)
-- ---------------------------------------------------------
-- Identify the Top 3 most expensive villas in EACH district
-- Used to populate the "Top Opportunities" table in the dashboard
WITH villas_ranking AS (
    SELECT
        district,
        price,
        area,
        title,
        -- Rank properties within each district by price (Highest first)
        ROW_NUMBER() OVER (
            PARTITION BY district
            ORDER BY price DESC, area DESC
        ) as rank_num
    FROM riyadh_listings 
    WHERE category = '3'      -- Filter for Villas only
      AND price > 100000      -- Exclude data entry errors
      AND area > 200          -- Exclude small properties
)
SELECT *
FROM villas_ranking
WHERE rank_num <= 3
ORDER BY district, rank_num;