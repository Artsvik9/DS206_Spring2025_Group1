USE ORDER_DDS;
GO

-- Declare parameters (optional)
DECLARE @start_date DATE;
DECLARE @end_date DATE;

-- Get the SOR_SK for stg_raw_Categories
DECLARE @sor_sk INT;
SELECT @sor_sk = sor_sk FROM Dim_SOR WHERE source_table_name = 'stg_raw_Categories';

-- UPSERT: Update if exists, otherwise insert
MERGE Dim_Categories AS target
USING stg_raw_Categories AS source
ON target.category_nk = source.CategoryID
WHEN MATCHED AND (
    target.category_name != source.CategoryName OR
    target.description != source.Description
)
THEN UPDATE SET
    category_name = source.CategoryName,
    description = source.Description,
    staging_raw_id_sk = source.staging_raw_id_sk,
    sor_sk = @sor_sk
WHEN NOT MATCHED BY TARGET
THEN INSERT (
    category_nk,
    category_name,
    description,
    staging_raw_id_sk,
    sor_sk
)
VALUES (
    source.CategoryID,
    source.CategoryName,
    source.Description,
    source.staging_raw_id_sk,
    @sor_sk
);

-- DELETE logic: Remove records from Dim_Categories that no longer exist in staging
DELETE FROM Dim_Categories
WHERE category_nk NOT IN (
    SELECT CategoryID FROM stg_raw_Categories
);
