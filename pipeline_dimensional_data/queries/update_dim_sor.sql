USE ORDER_DDS;

-- Insert missing mappings into Dim_SOR
INSERT INTO Dim_SOR (staging_table_name, dimension_table_name)
SELECT DISTINCT
    src.staging_table_name,
    src.dimension_table_name
FROM (
    VALUES
        ('Staging_Categories', 'DimCategories'),
        ('Staging_Customers', 'DimCustomers'),
        ('Staging_Employees', 'DimEmployees'),
        ('Staging_Products', 'DimProducts'),
        ('Staging_Region', 'DimRegion'),
        ('Staging_Shippers', 'DimShippers'),
        ('Staging_Suppliers', 'DimSuppliers'),
        ('Staging_Territories', 'DimTerritories'),
        ('Staging_Orders', 'FactOrders'),
        ('Staging_OrderDetails', 'FactOrders')
) AS src(staging_table_name, dimension_table_name)
LEFT JOIN Dim_SOR dim
    ON src.staging_table_name = dim.staging_table_name
WHERE dim.staging_table_name IS NULL;
