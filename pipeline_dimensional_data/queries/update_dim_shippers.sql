USE ORDER_DDS;
GO

DECLARE @start_date DATE;
DECLARE @end_date DATE;

-- Get SOR_SK
DECLARE @sor_sk INT;
SELECT @sor_sk = sor_sk FROM Dim_SOR WHERE source_table_name = 'stg_raw_Shippers';

-- Update existing shippers if phone has changed
UPDATE Dim_Shippers
SET 
    previous_phone = current_phone,
    current_phone = s.Phone,
    company_name = s.CompanyName,
    staging_raw_id_sk = s.staging_raw_id_sk,
    sor_sk = @sor_sk
FROM Dim_Shippers d
JOIN stg_raw_Shippers s ON d.shipper_nk = s.ShipperID
WHERE d.current_phone != s.Phone;

-- Insert new shippers
INSERT INTO Dim_Shippers (
    shipper_nk,
    company_name,
    current_phone,
    previous_phone,
    staging_raw_id_sk,
    sor_sk
)
SELECT
    s.ShipperID,
    s.CompanyName,
    s.Phone,
    NULL,
    s.staging_raw_id_sk,
    @sor_sk
FROM stg_raw_Shippers s
WHERE NOT EXISTS (
    SELECT 1 FROM Dim_Shippers d WHERE d.shipper_nk = s.ShipperID
);
