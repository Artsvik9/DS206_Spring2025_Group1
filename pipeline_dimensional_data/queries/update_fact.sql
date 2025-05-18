USE ORDER_DDS;
GO

DECLARE @start_date DATE = '1996-01-01';
DECLARE @end_date DATE = '1998-12-31';
DECLARE @sor_sk INT;

SELECT @sor_sk = sor_sk 
FROM Dim_SOR 
WHERE staging_table_name = 'Staging_Orders';

INSERT INTO FactOrders (
    order_id_nk,
    customer_sk_table,
    employee_sk_table,
    shipper_sk_table,
    product_sk_table,
    order_date,
    quantity,
    total_amount,
    discount,
    snapshot_date
)
SELECT
    o.OrderID,                          
    c.customer_sk_table,              
    e.employee_sk_table,                
    sh.shipper_sk_table,               
    p.product_sk_table,                
    TRY_CAST(o.OrderDate AS DATE),     
    od.Quantity,                        
    od.UnitPrice * od.Quantity,        
    od.Discount,                       
    GETDATE() AS snapshot_date
FROM Staging_Orders o
JOIN Staging_OrderDetails od
    ON o.OrderID = od.OrderID
JOIN DimCustomers c
    ON o.CustomerID = c.customer_id_nk
JOIN DimEmployees e
    ON o.EmployeeID = e.employee_id_nk
JOIN DimShippers sh
    ON o.ShipVia = sh.shipper_id_nk
JOIN DimProducts p
    ON od.ProductID = p.product_id_nk
WHERE TRY_CAST(o.OrderDate AS DATE) BETWEEN @start_date AND @end_date;
