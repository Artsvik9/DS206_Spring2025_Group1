USE ORDER_DDS;
GO

-- Optional parameters (not used)
DECLARE @start_date DATE;
DECLARE @end_date DATE;

-- Get the SOR_SK for stg_raw_Region
DECLARE @sor_sk INT;
SELECT @sor_sk = sor_sk FROM Dim_SOR WHERE source_table_name = 'stg_raw_Region';

-- MERGE for overwrite (SCD1)
MERGE Dim_Region AS target
USING stg_raw_Region AS source
ON target.region_nk = source.RegionID
WHEN MATCHED AND (
    target.region_description != source.RegionDescription
)
THEN UPDATE SET
    region_description = source.RegionDescription,
    staging_raw_id_sk = source.staging_raw_id_sk,
    sor_sk = @sor_sk
WHEN NOT MATCHED BY TARGET
THEN INSERT (
    region_nk,
    region_description,
    staging_raw_id_sk,
    sor_sk
)
VALUES (
    source.RegionID,
    source.RegionDescription,
    source.staging_raw_id_sk,
    @sor_sk
);
