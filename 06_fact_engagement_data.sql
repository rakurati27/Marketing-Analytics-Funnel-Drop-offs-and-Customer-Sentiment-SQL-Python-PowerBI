/*==============================================================================
 Purpose
- Normalize ContentType
- Split ViewsClicksCombined into numeric Views + Clicks safely
- Filter out Newsletter content

Why (analysis / business context):
- Engagement is used for channel/content performance, RPS, and conversion lift analysis
==============================================================================*/

CREATE OR ALTER VIEW dbo.vw_fact_engagement_data_clean
AS
SELECT
    e.EngagementID,
    e.ContentID,
    e.CampaignID,
    e.ProductID,

    -- Normalize ContentType:
    UPPER(
        REPLACE(
            REPLACE(LTRIM(RTRIM(e.ContentType)), 'Socialmedia', 'Social Media'),
        'SocialMedia', 'Social Media')
    ) AS ContentType,

    /* Safe parsing of ViewsClicksCombined (expected format: 'Views-Clicks')
       - TRY_CONVERT ensures numeric output or NULL
    */
    TRY_CONVERT(
        INT,
        CASE
            WHEN CHARINDEX('-', e.ViewsClicksCombined) > 0
                THEN LEFT(e.ViewsClicksCombined, CHARINDEX('-', e.ViewsClicksCombined) - 1)
            ELSE NULL
        END
    ) AS Views,

    TRY_CONVERT(
        INT,
        CASE
            WHEN CHARINDEX('-', e.ViewsClicksCombined) > 0
                THEN RIGHT(e.ViewsClicksCombined, LEN(e.ViewsClicksCombined) - CHARINDEX('-', e.ViewsClicksCombined))
            ELSE NULL
        END
    ) AS Clicks,

    e.Likes,

    -- Keep as DATE for joins/aggregations 
    CONVERT(DATE, e.EngagementDate) AS EngagementDate,

    -- Convenience bucket for monthly trends
    DATEFROMPARTS(YEAR(CONVERT(DATE, e.EngagementDate)), MONTH(CONVERT(DATE, e.EngagementDate)), 1) AS EngagementMonth
FROM dbo.engagement_data AS e
WHERE
    e.ContentType <> 'Newsletter';

GO

-- Data Check
 SELECT TOP (50) * FROM dbo.vw_fact_engagement_data_clean ORDER BY EngagementDate DESC;
