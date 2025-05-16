USE ORDER_DDS;
GO

DECLARE @start_date DATE;
DECLARE @end_date DATE;
DECLARE @sor_sk INT;

SELECT @sor_sk = sor_sk 
FROM Dim_SOR 
WHERE staging_table_name = 'Staging_Products';

INSERT INTO DimProducts (
    product_sk_durable,
    product_id_nk,
    product_name,
    supplier_id,
    category_id,
    quantity_per_unit,
    unit_price,
    units_in_stock,
    units_on_order,
    reorder_level,
    discontinued,
    snapshot_date,
    staging_raw_id_sk,
    sor_sk
)
SELECT
    ABS(CHECKSUM(p.ProductID)),         
    p.ProductID,
    p.ProductName,
    p.SupplierID,
    p.CategoryID,
    p.QuantityPerUnit,
    TRY_CAST(p.UnitPrice AS DECIMAL(18,2)),
    p.UnitsInStock,
    p.UnitsOnOrder,
    p.ReorderLevel,
    p.Discontinued,
    GETDATE() AS snapshot_date,
    p.Staging_Raw_ID,
    @sor_sk
FROM Staging_Products p
WHERE NOT EXISTS (
    SELECT 1
    FROM DimProducts d
    WHERE d.product_id_nk = p.ProductID
      AND d.snapshot_date = CAST(GETDATE() AS DATE)
);
