/*==============================================================================
Purpose:
- Enrich customer records with geography attributes (Country, City)
- Standardize a few fields for consistent downstream analysis 

Why (analysis / business context):
- Marketing + funnel analysis often needs segmentation by location
- Clean, standardized dimensions prevent messy CASE statements later
==============================================================================*/

-- Best practice: Using this as a reusable VIEW for BI + Python consumption
CREATE OR ALTER VIEW dbo.vw_dim_customers_enriched
AS
SELECT
    c.CustomerID,                                  -- Unique customer key
    c.CustomerName,                                -- Customer name
    LOWER(LTRIM(RTRIM(c.Email))) AS EmailNormalized,-- Normalize email for matching/dedup 
    UPPER(LTRIM(RTRIM(c.Gender))) AS Gender,        -- Standardize text
    c.Age,                                         -- Keep numeric
    -- Simple bucketing helps quick segmentation
        WHEN c.Age IS NULL THEN 'Unknown'
        WHEN c.Age < 18 THEN '<18'
        WHEN c.Age BETWEEN 18 AND 24 THEN '18-24'
        WHEN c.Age BETWEEN 25 AND 34 THEN '25-34'
        WHEN c.Age BETWEEN 35 AND 44 THEN '35-44'
        WHEN c.Age BETWEEN 45 AND 54 THEN '45-54'
        ELSE '55+'
    END AS AgeBand,
    g.Country,                                     -- Geo enrichment
    g.City
FROM dbo.customers AS c
    -- LEFT JOIN keeps customers even if geography is missing
    LEFT JOIN dbo.geography AS g
        ON c.GeographyID = g.GeographyID;

GO

-- Data Check
-- SELECT TOP (50) * FROM dbo.vw_dim_customers_enriched;
