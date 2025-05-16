USE ORDER_DDS;
GO
-- Updates Dim_Customers using SCD2 logic

-- Declare date parameters (optional - not used here)
DECLARE @start_date DATE;
DECLARE @end_date DATE;

-- Get the SOR_SK for stg_raw_Customers
DECLARE @sor_sk INT;
SELECT @sor_sk = sor_sk FROM Dim_SOR WHERE source_table_name = 'stg_raw_Customers';

-- Insert new versions for changed customers
INSERT INTO Dim_Customers (
    customer_durable_sk,
    customer_nk,
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
    effective_date,
    ineffective_date,
    current_flag,
    staging_raw_id_sk,
    sor_sk
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
    GETDATE(),  -- effective_date
    NULL,       -- ineffective_date
    1,          -- current_flag
    c.staging_raw_id_sk,
    @sor_sk
FROM stg_raw_Customers c
WHERE NOT EXISTS (
    SELECT 1
    FROM Dim_Customers d
    WHERE d.customer_nk = c.CustomerID
      AND d.current_flag = 1
      AND (
          d.company_name != c.CompanyName OR
          d.contact_name != c.ContactName OR
          d.contact_title != c.ContactTitle OR
          d.address != c.Address OR
          d.city != c.City OR
          d.region != c.Region OR
          d.postal_code != c.PostalCode OR
          d.country != c.Country OR
          d.phone != c.Phone OR
          d.fax != c.Fax
      )
);

-- Mark old versions as inactive
UPDATE Dim_Customers
SET ineffective_date = GETDATE(),
    current_flag = 0
WHERE current_flag = 1
AND EXISTS (
    SELECT 1
    FROM stg_raw_Customers c
    WHERE c.CustomerID = Dim_Customers.customer_nk
      AND (
          Dim_Customers.company_name != c.CompanyName OR
          Dim_Customers.contact_name != c.ContactName OR
          Dim_Customers.contact_title != c.ContactTitle OR
          Dim_Customers.address != c.Address OR
          Dim_Customers.city != c.City OR
          Dim_Customers.region != c.Region OR
          Dim_Customers.postal_code != c.PostalCode OR
          Dim_Customers.country != c.Country OR
          Dim_Customers.phone != c.Phone OR
          Dim_Customers.fax != c.Fax
      )
);
