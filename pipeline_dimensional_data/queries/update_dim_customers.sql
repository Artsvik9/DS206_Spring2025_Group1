USE ORDER_DDS;
GO

DECLARE @start_date DATE;
DECLARE @end_date DATE;

DECLARE @sor_sk INT;
SELECT @sor_sk = sor_sk 
FROM Dim_SOR 
WHERE staging_table_name = 'Staging_Customers';

INSERT INTO DimCustomers (
    customer_sk_durable,
    customer_id_nk,
    customer_name,
    contact_name,
    contact_title,
    address,
    city,
    region,
    postal_code,
    country,
    phone,
    fax,
    valid_from,
    valid_to,
    sor_sk,
    staging_raw_id_sk
)
SELECT
    ABS(CHECKSUM(c.CustomerID)),  
    c.CustomerID,
    c.CompanyName,
    c.ContactName,
    c.ContactTitle,
    c.Address,
    c.City,
    c.Region,
    c.PostalCode,
    c.Country,
    c.Phone,
    c.Fax,
    GETDATE(),      
    NULL,            
    @sor_sk,
    c.Staging_Raw_ID
FROM Staging_Customers c
WHERE NOT EXISTS (
    SELECT 1
    FROM DimCustomers d
    WHERE d.customer_id_nk = c.CustomerID
      AND d.valid_to IS NULL  
      AND (
          d.customer_name    != c.CompanyName OR
          d.contact_name     != c.ContactName OR
          d.contact_title    != c.ContactTitle OR
          d.address          != c.Address OR
          d.city             != c.City OR
          d.region           != c.Region OR
          d.postal_code      != c.PostalCode OR
          d.country          != c.Country OR
          d.phone            != c.Phone OR
          d.fax              != c.Fax
      )
);

UPDATE DimCustomers
SET valid_to = GETDATE()
WHERE valid_to IS NULL
AND EXISTS (
    SELECT 1
    FROM Staging_Customers c
    WHERE c.CustomerID = DimCustomers.customer_id_nk
      AND (
          DimCustomers.customer_name    != c.CompanyName OR
          DimCustomers.contact_name     != c.ContactName OR
          DimCustomers.contact_title    != c.ContactTitle OR
          DimCustomers.address          != c.Address OR
          DimCustomers.city             != c.City OR
          DimCustomers.region           != c.Region OR
          DimCustomers.postal_code      != c.PostalCode OR
          DimCustomers.country          != c.Country OR
          DimCustomers.phone            != c.Phone OR
          DimCustomers.fax              != c.Fax
      )
);