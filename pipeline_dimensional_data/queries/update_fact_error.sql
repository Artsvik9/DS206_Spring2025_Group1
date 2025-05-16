USE ORDER_DDS;
GO

-- Parameters
DECLARE @start_date DATE = '2022-01-01';
DECLARE @end_date DATE = '2025-12-31';

-- Get SOR_SK for stg_raw_Orders
DECLARE @sor_sk INT;
SELECT @sor_sk = sor_sk FROM Dim_SOR WHERE source_table_name = 'stg_raw_Orders';

-- Insert into fact_error when dimension joins fail
INSERT INTO fact_error (
    order_nk,
    customer_nk,
    employee_nk,
    shipper_nk,
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
    s.OrderDate,
    s.ShippedDate,
    s.Freight,
    s.staging_raw_id_sk,
    @sor_sk
FROM stg_raw_Orders s
LEFT JOIN Dim_Customers c
    ON s.CustomerID = c.customer_nk AND c.current_flag = 1
LEFT JOIN Dim_Employees e
    ON s.EmployeeID = e.employee_nk
LEFT JOIN Dim_Shippers sh
    ON s.ShipVia = sh.shipper_nk
WHERE s.OrderDate BETWEEN @start_date AND @end_date
  AND (
      c.customer_table_sk IS NULL
   OR e.employee_durable_sk IS NULL
   OR sh.shipper_durable_sk IS NULL
  );
