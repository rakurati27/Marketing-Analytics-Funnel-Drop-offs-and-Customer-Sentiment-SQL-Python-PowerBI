/*==============================================================================
Purpose:
- Categorize products by price bands (Low/Medium/High)
- Add light data-quality signals for pricing

Why (analysis / business context):
- Price tiers are useful for conversion + revenue segmentation
- Python can later model conversion by price tier; SQL should prep clean labels
==============================================================================*/

CREATE OR ALTER VIEW dbo.vw_dim_products_enriched
AS
SELECT
    p.ProductID,                         -- Unique product key
    p.ProductName,                       -- Product name
    p.Price,                             -- Numeric price

    -- Price banding for quick segmentation
    CASE
        WHEN p.Price IS NULL OR p.Price <= 0 THEN 'Invalid/Missing'
        WHEN p.Price < 50 THEN 'Low'
        WHEN p.Price BETWEEN 50 AND 200 THEN 'Medium'
        ELSE 'High'
    END AS PriceCategory,

    -- Simple quality flag
    CASE
        WHEN p.Price IS NULL OR p.Price <= 0 THEN 1
        ELSE 0
    END AS IsPriceInvalid
FROM dbo.products AS p;

GO

-- Distribution tiers for Python features
SELECT ProductID, ProductName, Price,
        NTILE(4) OVER (ORDER BY Price) AS PriceQuartile
FROM dbo.products;
