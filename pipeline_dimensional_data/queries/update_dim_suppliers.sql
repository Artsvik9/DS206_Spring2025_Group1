USE ORDER_DDS;
GO

DECLARE @sor_sk INT;
SELECT @sor_sk = sor_sk FROM Dim_SOR WHERE source_table_name = 'stg_raw_Suppliers';

-- Merge with profile table
MERGE Dim_Suppliers AS target
USING (
    SELECT
        s.SupplierID,
        s.CompanyName,
        s.ContactName,
        s.ContactTitle,
        s.Address,
        s.City,
        s.Region,
        s.PostalCode,
        s.Country,
        s.staging_raw_id_sk,
        p.supplier_profile_sk
    FROM stg_raw_Suppliers s
    JOIN Dim_Suppliers_Profile p
      ON s.Phone = p.phone
     AND s.Fax = p.fax
     AND s.HomePage = p.homepage
) AS source
ON target.supplier_nk = source.SupplierID
WHEN MATCHED AND (
    target.company_name != source.CompanyName OR
    target.contact_name != source.ContactName OR
    target.contact_title != source.ContactTitle OR
    target.address != source.Address OR
    target.city != source.City OR
    target.region != source.Region OR
    target.postal_code != source.PostalCode OR
    target.country != source.Country OR
    target.supplier_profile_sk != source.supplier_profile_sk
)
THEN UPDATE SET
    company_name = source.CompanyName,
    contact_name = source.ContactName,
    contact_title = source.ContactTitle,
    address = source.Address,
    city = source.City,
    region = source.Region,
    postal_code = source.PostalCode,
    country = source.Country,
    supplier_profile_sk = source.supplier_profile_sk,
    staging_raw_id_sk = source.staging_raw_id_sk,
    sor_sk = @sor_sk
WHEN NOT MATCHED BY TARGET
THEN INSERT (
    supplier_nk,
    company_name,
    contact_name,
    contact_title,
    address,
    city,
    region,
    postal_code,
    country,
    supplier_profile_sk,
    staging_raw_id_sk,
    sor_sk
)
VALUES (
    source.SupplierID,
    source.CompanyName,
    source.ContactName,
    source.ContactTitle,
    source.Address,
    source.City,
    source.Region,
    source.PostalCode,
    source.Country,
    source.supplier_profile_sk,
    source.staging_raw_id_sk,
    @sor_sk
);
