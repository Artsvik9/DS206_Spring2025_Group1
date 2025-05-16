USE ORDER_DDS;
GO

DECLARE @start_date DATE;
DECLARE @end_date DATE;

-- Get SOR_SK
DECLARE @sor_sk INT;
SELECT @sor_sk = sor_sk FROM Dim_SOR WHERE source_table_name = 'stg_raw_Territories';

-- Update changed territory descriptions (SCD3 logic)
UPDATE Dim_Territories
SET
    previous_description = current_description,
    current_description = s.TerritoryDescription,
    region_nk = s.RegionID,
    staging_raw_id_sk = s.staging_raw_id_sk,
    sor_sk = @sor_sk
FROM Dim_Territories d
JOIN stg_raw_Territories s ON d.territory_nk = s.TerritoryID
WHERE d.current_description != s.TerritoryDescription;

-- Insert new territories
INSERT INTO Dim_Territories (
    territory_nk,
    region_nk,
    current_description,
    previous_description,
    staging_raw_id_sk,
    sor_sk
)
SELECT
    s.TerritoryID,
    s.RegionID,
    s.TerritoryDescription,
    NULL,
    s.staging_raw_id_sk,
    @sor_sk
FROM stg_raw_Territories s
WHERE NOT EXISTS (
    SELECT 1 FROM Dim_Territories d
    WHERE d.territory_nk = s.TerritoryID
);
