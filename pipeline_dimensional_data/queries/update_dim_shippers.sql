USE ORDER_DDS;
GO

DECLARE @start_date DATE;
DECLARE @end_date DATE;

DECLARE @sor_sk INT;
SELECT @sor_sk = sor_sk 
FROM Dim_SOR 
WHERE staging_table_name = 'Staging_Shippers';

UPDATE DimShippers
SET 
    previous_phone       = current_phone,
    current_phone        = s.Phone,
    current_company_name = s.CompanyName,
    staging_raw_id_sk    = s.Staging_Raw_ID,
    sor_sk               = @sor_sk
FROM DimShippers d
JOIN Staging_Shippers s ON d.shipper_id_nk = s.ShipperID
WHERE d.current_phone != s.Phone;

INSERT INTO DimShippers (
    shipper_id_nk,
    current_company_name,
    current_phone,
    previous_company_name,
    previous_phone,
    staging_raw_id_sk,
    sor_sk
)
SELECT
    s.ShipperID,
    s.CompanyName,
    s.Phone,
    NULL,
    NULL,
    s.Staging_Raw_ID,
    @sor_sk
FROM Staging_Shippers s
WHERE NOT EXISTS (
    SELECT 1 
    FROM DimShippers d 
    WHERE d.shipper_id_nk = s.ShipperID
);