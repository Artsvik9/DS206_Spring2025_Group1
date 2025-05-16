USE ORDER_DDS;
GO

DECLARE @sor_sk INT;
SELECT @sor_sk = sor_sk 
FROM Dim_SOR 
WHERE staging_table_name = 'Staging_Territories';

UPDATE DimTerritories
SET
    prior_territory_description = current_territory_description,
    current_territory_description = s.TerritoryDescription,
    region_id = s.RegionID,
    staging_raw_id_sk = s.Staging_Raw_ID,
    sor_sk = @sor_sk
FROM Staging_Territories s
JOIN DimTerritories d
    ON s.TerritoryID = d.territory_id_nk
WHERE d.current_territory_description != s.TerritoryDescription;

INSERT INTO DimTerritories (
    territory_id_nk,
    current_territory_description,
    prior_territory_description,
    region_id,
    staging_raw_id_sk,
    sor_sk
)
SELECT
    s.TerritoryID,
    s.TerritoryDescription,
    NULL,                 
    s.RegionID,
    s.Staging_Raw_ID,
    @sor_sk
FROM Staging_Territories s
WHERE NOT EXISTS (
    SELECT 1 FROM DimTerritories d
    WHERE d.territory_id_nk = s.TerritoryID
);
