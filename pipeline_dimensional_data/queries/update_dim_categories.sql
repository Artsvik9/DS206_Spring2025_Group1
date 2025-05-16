USE ORDER_DDS;
GO

DECLARE @start_date DATE;
DECLARE @end_date DATE;

DECLARE @sor_sk INT;
SELECT @sor_sk = sor_sk 
FROM Dim_SOR 
WHERE staging_table_name = 'Staging_Categories';

MERGE DimCategories AS target
USING Staging_Categories AS source
ON target.category_id_nk = source.CategoryID
WHEN MATCHED AND (
    target.category_name != source.CategoryName OR
    target.description  != source.Description
)
THEN UPDATE SET
    category_name       = source.CategoryName,
    description         = source.Description,
    staging_raw_id_sk   = source.Staging_Raw_ID,
    sor_sk              = @sor_sk
WHEN NOT MATCHED BY TARGET
THEN INSERT (
    category_id_nk,
    category_name,
    description,
    staging_raw_id_sk,
    sor_sk
)
VALUES (
    source.CategoryID,
    source.CategoryName,
    source.Description,
    source.Staging_Raw_ID,
    @sor_sk
);

DELETE FROM DimCategories
WHERE category_id_nk NOT IN (
    SELECT CategoryID FROM Staging_Categories
);
