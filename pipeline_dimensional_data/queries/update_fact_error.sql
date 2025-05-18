USE ORDER_DDS;
GO

DECLARE @start_date DATE = '1996-01-01';
DECLARE @end_date DATE = '1998-12-31';

DECLARE @sor_sk INT;
SELECT @sor_sk = sor_sk 
FROM Dim_SOR 
WHERE staging_table_name = 'Staging_Orders';

INSERT INTO Fact_Error (
    order_id_nk,
    customer_id_nk,
    employee_id_nk,
    shipper_id_nk,
    order_date,
    shipped_date,
    freight,
    staging_raw_id_sk,
    sor_sk
)
SELECT
    s.OrderID,
    s.CustomerID,
    s.EmployeeID,
    s.ShipVia,
    TRY_CAST(s.OrderDate AS DATE),
    TRY_CAST(s.ShippedDate AS DATE),
    s.Freight,
    s.Staging_Raw_ID,
    @sor_sk
FROM Staging_Orders s
LEFT JOIN DimCustomers c
    ON s.CustomerID = c.customer_id_nk
    AND c.valid_to IS NULL  
LEFT JOIN DimEmployees e
    ON s.EmployeeID = e.employee_id_nk
LEFT JOIN DimShippers sh
    ON s.ShipVia = sh.shipper_id_nk
WHERE TRY_CAST(s.OrderDate AS DATE) BETWEEN @start_date AND @end_date
  AND (
      c.customer_sk_table IS NULL OR
      e.employee_sk_table IS NULL OR
      sh.shipper_sk_table IS NULL
  );
