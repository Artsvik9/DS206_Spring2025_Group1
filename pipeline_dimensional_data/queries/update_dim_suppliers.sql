USE ORDER_DDS;
GO

DECLARE @sor_sk INT;
SELECT @sor_sk = sor_sk 
FROM Dim_SOR 
WHERE staging_table_name = 'Staging_Suppliers';

INSERT INTO DimSuppliers (
    supplier_sk_durable,
    supplier_id_nk,
    company_name,
    contact_name,
    contact_title,
    address,
    city,
    region,
    postal_code,
    country,
    phone,
    fax,
    home_page,
    snapshot_date,
    staging_raw_id_sk,
    sor_sk
)
SELECT
    ABS(CHECKSUM(s.SupplierID)),  
    s.SupplierID,
    s.CompanyName,
    s.ContactName,
    s.ContactTitle,
    s.Address,
    s.City,
    s.Region,
    s.PostalCode,
    s.Country,
    s.Phone,
    s.Fax,
    s.HomePage,
    GETDATE(),        
    s.Staging_Raw_ID,  
    @sor_sk
FROM Staging_Suppliers s;
