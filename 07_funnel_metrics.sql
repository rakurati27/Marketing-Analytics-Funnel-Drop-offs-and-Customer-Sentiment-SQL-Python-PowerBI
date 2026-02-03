/*==============================================================================
Purpose
Build funnel-level metrics from cleaned customer journey data

What we are doing:
- Aggregate customer journey steps into funnel stages
- Calculate conversion and drop-off metrics
- Estimate revenue loss due to drop-offs

Analysis (business context):
- Funnels show where users leave the product
- Drop-off value loss translates behavior into $ / ₹ impact
==============================================================================*/

CREATE OR ALTER VIEW dbo.vw_funnel_metrics AS
WITH funnel_flags AS (
    SELECT
        CustomerID,
        ProductID,
        VisitDate,

        -- Funnel stage flags
        MAX(CASE WHEN Stage = 'AWARENESS' THEN 1 ELSE 0 END) AS awareness,
        MAX(CASE WHEN Stage = 'CONSIDERATION' THEN 1 ELSE 0 END) AS consideration,
        MAX(CASE WHEN Stage = 'CHECKOUT' THEN 1 ELSE 0 END) AS checkout,
        MAX(CASE WHEN Stage = 'PURCHASE' THEN 1 ELSE 0 END) AS purchase
    FROM dbo.vw_fact_customer_journey_clean
    GROUP BY CustomerID, ProductID, VisitDate
),
stage_counts AS (
    SELECT
        COUNT(*) AS total_users,
        SUM(awareness) AS awareness_users,
        SUM(CASE WHEN awareness = 1 AND consideration = 1 THEN 1 ELSE 0 END) AS consideration_users,
        SUM(CASE WHEN consideration = 1 AND checkout = 1 THEN 1 ELSE 0 END) AS checkout_users,
        SUM(CASE WHEN checkout = 1 AND purchase = 1 THEN 1 ELSE 0 END) AS purchase_users
    FROM funnel_flags
)
SELECT
    total_users,
    awareness_users,
    consideration_users,
    checkout_users,
    purchase_users,

    -- Conversion rates
    CAST(consideration_users * 1.0 / NULLIF(awareness_users, 0) AS DECIMAL(5,2)) AS awareness_to_consideration_cr,
    CAST(checkout_users * 1.0 / NULLIF(consideration_users, 0) AS DECIMAL(5,2)) AS consideration_to_checkout_cr,
    CAST(purchase_users * 1.0 / NULLIF(checkout_users, 0) AS DECIMAL(5,2)) AS checkout_to_purchase_cr,

    -- Drop-offs
    awareness_users - consideration_users AS drop_after_awareness,
    consideration_users - checkout_users AS drop_after_consideration,
    checkout_users - purchase_users AS drop_after_checkout
FROM stage_counts;
GO
