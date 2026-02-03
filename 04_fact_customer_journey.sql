/*==============================================================================
Purpose
1) Identify duplicates (same CustomerID, ProductID, VisitDate, Stage, Action)
2) Create a cleaned view that:
   - Uppercases Stage for consistency
   - Removes duplicates (keeps first by JourneyID)
   - Fills missing Duration using avg duration per VisitDate

Why (analysis / business context):
- Funnel metrics are sensitive to duplicates (they inflate steps and conversions)
- A clean journey table is the foundation for funnel drop-offs + revenue loss analysis
==============================================================================*/

/*------------------------------------------------------------------------------
Part A: Duplicate check (debug query)
- A CTE must be followed immediately by ONE statement.
------------------------------------------------------------------------------*/

-- WITH DuplicateRecords AS (
--     SELECT
--         JourneyID,
--         CustomerID,
--         ProductID,
--         VisitDate,
--         Stage,
--         Action,
--         Duration,
--         ROW_NUMBER() OVER (
--             PARTITION BY CustomerID, ProductID, VisitDate, UPPER(Stage), Action
--             ORDER BY JourneyID
--         ) AS row_num
--     FROM dbo.customer_journey
-- )
-- SELECT *
-- FROM DuplicateRecords
-- WHERE row_num > 1
-- ORDER BY JourneyID;
-- GO


/*------------------------------------------------------------------------------
Part B: Clean, standardized journey view (for BI + Python)
------------------------------------------------------------------------------*/

CREATE OR ALTER VIEW dbo.vw_fact_customer_journey_clean
AS
WITH JourneyPrepared AS (
    SELECT
        JourneyID,
        CustomerID,
        ProductID,
        CONVERT(DATE, VisitDate) AS VisitDate,           -- Ensure DATE grain for analytics
        UPPER(LTRIM(RTRIM(Stage))) AS Stage,             -- Standardize Stage
        UPPER(LTRIM(RTRIM(Action))) AS Action,           -- Standardize Action
        Duration,

        -- Avg duration per date
        AVG(Duration) OVER (PARTITION BY CONVERT(DATE, VisitDate)) AS avg_duration,

        -- Dedup logic
        ROW_NUMBER() OVER (
            PARTITION BY CustomerID, ProductID, CONVERT(DATE, VisitDate), UPPER(LTRIM(RTRIM(Stage))), UPPER(LTRIM(RTRIM(Action)))
            ORDER BY JourneyID
        ) AS row_num
    FROM dbo.customer_journey
)
SELECT
    JourneyID,
    CustomerID,
    ProductID,
    VisitDate,
    Stage,
    Action,

    -- Fill missing duration with the avg duration of that date
    COALESCE(Duration, avg_duration) AS Duration
FROM JourneyPrepared
WHERE row_num = 1;  -- Keep only the first record per duplicate group

GO

-- Data Check
 SELECT TOP (50) * FROM dbo.vw_fact_customer_journey_clean ORDER BY VisitDate DESC, JourneyID DESC;
