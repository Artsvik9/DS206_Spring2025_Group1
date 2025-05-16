USE ORDER_DDS;
GO

-- Optional date filtering
DECLARE @start_date DATE;
DECLARE @end_date DATE;

-- Insert distinct product profiles (only if they don’t already exist)
INSERT INTO Dim_Products_Profile (
    quantity_per_unit,
    unit_price,
    units_in_stock,
    units_on_order,
    reorder_level
)
SELECT DISTINCT
    QuantityPerUnit,
    UnitPrice,
    UnitsInStock,
    UnitsOnOrder,
    ReorderLevel
FROM stg_raw_Products p
WHERE NOT EXISTS (
    SELECT 1
    FROM Dim_Products_Profile d
    WHERE d.quantity_per_unit = p.QuantityPerUnit
      AND d.unit_price = p.UnitPrice
      AND d.units_in_stock = p.UnitsInStock
      AND d.units_on_order = p.UnitsOnOrder
      AND d.reorder_level = p.ReorderLevel
);
