USE ORDER_DDS;
GO

DECLARE @start_date DATE;
DECLARE @end_date DATE;

DECLARE @sor_sk INT;
SELECT @sor_sk = sor_sk 
FROM Dim_SOR 
WHERE staging_table_name = 'Staging_Region';

MERGE DimRegion AS target
USING Staging_Region AS source
ON target.region_id_nk = source.RegionID
WHEN MATCHED AND (
    target.region_description != source.RegionDescription
)
THEN UPDATE SET
    region_description   = source.RegionDescription,
    staging_raw_id_sk    = source.Staging_Raw_ID,
    sor_sk               = @sor_sk
WHEN NOT MATCHED BY TARGET
THEN INSERT (
    region_id_nk,
    region_description,
    staging_raw_id_sk,
    sor_sk
)
VALUES (
    source.RegionID,
    source.RegionDescription,
    source.Staging_Raw_ID,
    @sor_sk
);