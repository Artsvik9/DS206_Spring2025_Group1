USE ORDER_DDS;
GO

DECLARE @start_date DATE;
DECLARE @end_date DATE;

-- Get the SOR_SK for stg_raw_Products
DECLARE @sor_sk INT;
SELECT @sor_sk = sor_sk FROM Dim_SOR WHERE source_table_name = 'stg_raw_Products';

-- Insert or update Dim_Products by linking to profile SK
MERGE Dim_Products AS target
USING (
    SELECT
        ProductID,
        ProductName,
        SupplierID,
        CategoryID,
        Discontinued,
        staging_raw_id_sk,
        ppf.product_profile_sk
    FROM stg_raw_Products p
    JOIN Dim_Products_Profile ppf
      ON p.QuantityPerUnit = ppf.quantity_per_unit
     AND p.UnitPrice = ppf.unit_price
     AND p.UnitsInStock = ppf.units_in_stock
     AND p.UnitsOnOrder = ppf.units_on_order
     AND p.ReorderLevel = ppf.reorder_level
) AS source
ON target.product_nk = source.ProductID
WHEN MATCHED AND (
    target.product_name != source.ProductName OR
    target.supplier_nk != source.SupplierID OR
    target.category_nk != source.CategoryID OR
    target.product_profile_sk != source.product_profile_sk OR
    target.discontinued != source.Discontinued
)
THEN UPDATE SET
    product_name        = source.ProductName,
    supplier_nk         = source.SupplierID,
    category_nk         = source.CategoryID,
    product_profile_sk  = source.product_profile_sk,
    discontinued        = source.Discontinued,
    staging_raw_id_sk   = source.staging_raw_id_sk,
    sor_sk              = @sor_sk
WHEN NOT MATCHED BY TARGET
THEN INSERT (
    product_nk,
    product_name,
    supplier_nk,
    category_nk,
    product_profile_sk,
    discontinued,
    staging_raw_id_sk,
    sor_sk
)
VALUES (
    source.ProductID,
    source.ProductName,
    source.SupplierID,
    source.CategoryID,
    source.product_profile_sk,
    source.Discontinued,
    source.staging_raw_id_sk,
    @sor_sk
);
