/*==============================================================================
Purpose:
Data quality checks for marketing analytics tables

What we are doing:
- Identify common data issues that affect funnel and ROI analysis
- Provide visibility into missing, duplicate, or invalid records

Analysis (business context):
- Poor data quality leads to wrong decisions
- Explicit checks increase trust in reported metrics
==============================================================================*/

-- 1️⃣ Missing customer or product IDs in journey data
SELECT
    COUNT(*) AS missing_keys_count
FROM dbo.customer_journey
WHERE CustomerID IS NULL
   OR ProductID IS NULL;

-- 2️⃣ Duplicate journey records (before cleaning)
SELECT
    CustomerID,
    ProductID,
    VisitDate,
    Stage,
    Action,
    COUNT(*) AS duplicate_count
FROM dbo.customer_journey
GROUP BY CustomerID, ProductID, VisitDate, Stage, Action
HAVING COUNT(*) > 1;

-- 3️⃣ Invalid product prices
SELECT
    COUNT(*) AS invalid_price_count
FROM dbo.products
WHERE Price IS NULL
   OR Price <= 0;

-- 4️⃣ Invalid customer review ratings
SELECT
    COUNT(*) AS invalid_rating_count
FROM dbo.customer_reviews
WHERE Rating IS NULL
   OR Rating < 1
   OR Rating > 5;
GO
