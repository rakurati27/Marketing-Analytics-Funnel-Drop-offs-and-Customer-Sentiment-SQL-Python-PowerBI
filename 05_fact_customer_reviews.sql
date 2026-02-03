/*==============================================================================
Purpose:
- Clean review text (trim + normalize whitespace)
- Add date bucketing + rating quality flags

Why (analysis / business context):
- Reviews can be used later in Python for sentiment/topic modeling
- Keeping a clean text column in SQL prevents repeating cleaning logic everywhere
==============================================================================*/

CREATE OR ALTER VIEW dbo.vw_fact_customer_reviews_clean
AS
SELECT
    r.ReviewID,
    r.CustomerID,
    r.ProductID,
    r.ReviewDate,
    r.Rating,

    -- Rating QA: expected range 1–5 
    CASE
        WHEN r.Rating IS NULL THEN 1
        WHEN r.Rating < 1 OR r.Rating > 5 THEN 1
        ELSE 0
    END AS IsRatingInvalid,

    -- Month bucket for trend analysis
    DATEFROMPARTS(YEAR(r.ReviewDate), MONTH(r.ReviewDate), 1) AS ReviewMonth,

    /* Text cleanup:
       - TRIM removes leading/trailing spaces
       - Multiple REPLACE passes reduce extra spaces 
       Note: For perfect whitespace normalization you'd use a function, but this is fine here.
    */
    REPLACE(
        REPLACE(
            REPLACE(TRIM(r.ReviewText), '  ', ' '),
        '  ', ' '),
    '  ', ' ') AS ReviewTextClean
FROM dbo.customer_reviews AS r;

GO

-- Data Check
 SELECT TOP (50) * FROM dbo.vw_fact_customer_reviews_clean ORDER BY ReviewDate DESC;
