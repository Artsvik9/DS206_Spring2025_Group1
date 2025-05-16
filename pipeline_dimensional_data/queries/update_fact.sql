USE ORDER_DDS;
GO

-- Parameters
DECLARE @start_date DATE = '2022-01-01';
DECLARE @end_date DATE = '2025-12-31';

-- Get SOR_SK for stg_raw_Orders
DECLARE @sor_sk INT;
SELECT @sor_sk = sor_sk FROM Dim_SOR WHERE source_table_name = 'stg_raw_Orders';

-- Insert into Fact_Orders
INSERT INTO Fact_Orders (
    order_nk,
    customer_sk,
    employee_sk,
    shipper_sk,
    order_date,
    shipped_date,
    freight,
    staging_raw_id_sk,
    sor_sk
)
SELECT
    s.OrderID,
    c.customer_table_sk,
    e.employee_durable_sk,
    sh.shipper_durable_sk,
    s.OrderDate,
    s.ShippedDate,
    s.Freight,
    s.staging_raw_id_sk,
    @sor_sk
FROM stg_raw_Orders s
JOIN Dim_Customers c
    ON s.CustomerID = c.customer_nk
    AND c.current_flag = 1
JOIN Dim_Employees e
    ON s.EmployeeID = e.employee_nk
JOIN Dim_Shippers sh
    ON s.ShipVia = sh.shipper_nk
WHERE s.OrderDate BETWEEN @start_date AND @end_date;

