USE ORDER_DDS;

-- Task 5

DROP TABLE IF EXISTS DimCategories;
DROP TABLE IF EXISTS DimCustomers;
DROP TABLE IF EXISTS DimEmployees;
DROP TABLE IF EXISTS DimProducts;
DROP TABLE IF EXISTS DimRegion;
DROP TABLE IF EXISTS DimShippers;
DROP TABLE IF EXISTS DimSuppliers;
DROP TABLE IF EXISTS DimTerritories;
DROP TABLE IF EXISTS FactOrders;
DROP TABLE IF EXISTS Dim_SOR;

-- DimCategories (SCD1 with delete)
CREATE TABLE DimCategories (
    category_sk_table INT IDENTITY(1,1) PRIMARY KEY,
    category_id_nk INT,
    category_name NVARCHAR(255),
    description NVARCHAR(MAX),
    is_deleted BIT DEFAULT 0,
    sor_sk INT,
    staging_raw_id_sk INT
);

-- DimCustomers (SCD2)
CREATE TABLE DimCustomers (
    customer_sk_table INT IDENTITY(1,1) PRIMARY KEY,
    customer_sk_durable INT,
    customer_id_nk NVARCHAR(10),
    customer_name NVARCHAR(255),
    contact_name NVARCHAR(255),
    contact_title NVARCHAR(255),
    address NVARCHAR(255),
    city NVARCHAR(255),
    region NVARCHAR(255),
    postal_code NVARCHAR(255),
    country NVARCHAR(255),
    phone NVARCHAR(255),
    fax NVARCHAR(255),
    valid_from DATE,
    valid_to DATE,
    sor_sk INT,
    staging_raw_id_sk INT
);

-- DimEmployees (SCD1 with delete)
CREATE TABLE DimEmployees (
    employee_sk_table INT IDENTITY(1,1) PRIMARY KEY,
    employee_id_nk INT,
    last_name NVARCHAR(255),
    first_name NVARCHAR(255),
    title NVARCHAR(255),
    title_of_courtesy NVARCHAR(255),
    birth_date DATE,
    hire_date DATE,
    address NVARCHAR(255),
    city NVARCHAR(255),
    region NVARCHAR(255),
    postal_code NVARCHAR(255),
    country NVARCHAR(255),
    home_phone NVARCHAR(255),
    extension INT,
    notes NVARCHAR(MAX),
    reports_to INT,
    photo_path NVARCHAR(255),
    is_deleted BIT DEFAULT 0,
    sor_sk INT,
    staging_raw_id_sk INT
);

-- DimProducts (SCD4)
CREATE TABLE DimProducts (
    product_sk_table INT IDENTITY(1,1) PRIMARY KEY,
    product_sk_durable INT,
    product_id_nk INT,
    product_name NVARCHAR(255),
    supplier_id INT,
    category_id INT,
    quantity_per_unit NVARCHAR(255),
    unit_price DECIMAL(18,2),
    units_in_stock INT,
    units_on_order INT,
    reorder_level INT,
    discontinued BIT,
    snapshot_date DATE,
    sor_sk INT,
    staging_raw_id_sk INT
);

-- DimRegion (SCD1)
CREATE TABLE DimRegion (
    region_sk_table INT IDENTITY(1,1) PRIMARY KEY,
    region_id_nk INT,
    region_description NVARCHAR(255),
    sor_sk INT,
    staging_raw_id_sk INT
);

-- DimShippers (SCD3 - 2 attributes, current and prior)
CREATE TABLE DimShippers (
    shipper_sk_table INT IDENTITY(1,1) PRIMARY KEY,
    shipper_id_nk INT,
    current_company_name NVARCHAR(255),
    current_phone NVARCHAR(50),
    previous_company_name NVARCHAR(255),
    previous_phone NVARCHAR(50),
    sor_sk INT,
    staging_raw_id_sk INT
);

-- DimSuppliers (SCD4)
CREATE TABLE DimSuppliers (
    supplier_sk_table INT IDENTITY(1,1) PRIMARY KEY,
    supplier_sk_durable INT,
    supplier_id_nk INT,
    company_name NVARCHAR(255),
    contact_name NVARCHAR(255),
    contact_title NVARCHAR(255),
    address NVARCHAR(255),
    city NVARCHAR(255),
    region NVARCHAR(255),
    postal_code NVARCHAR(255),
    country NVARCHAR(255),
    phone NVARCHAR(255),
    fax NVARCHAR(255),
    home_page NVARCHAR(255),
    snapshot_date DATE,
    sor_sk INT,
    staging_raw_id_sk INT
);

-- DimTerritories (SCD3)
CREATE TABLE DimTerritories (
    territory_sk_table INT IDENTITY(1,1) PRIMARY KEY,
    territory_id_nk INT,
    current_territory_description NVARCHAR(255),
    prior_territory_description NVARCHAR(255),
    region_id INT,
    sor_sk INT,
    staging_raw_id_sk INT
);

-- FactOrders (SNAPSHOT)
CREATE TABLE FactOrders (
    order_sk_table INT IDENTITY(1,1) PRIMARY KEY,
    order_id_nk INT,
    customer_sk_table INT,
    employee_sk_table INT,
    shipper_sk_table INT,
    product_sk_table INT,
    order_date DATE,
    quantity INT,
    total_amount DECIMAL(18,2),
    discount DECIMAL(18,2),
    snapshot_date DATE,
    sor_sk INT,
    staging_raw_id_sk INT,

    FOREIGN KEY (customer_sk_table) REFERENCES DimCustomers(customer_sk_table),
    FOREIGN KEY (employee_sk_table) REFERENCES DimEmployees(employee_sk_table),
    FOREIGN KEY (shipper_sk_table) REFERENCES DimShippers(shipper_sk_table),
    FOREIGN KEY (product_sk_table) REFERENCES DimProducts(product_sk_table)
);

-- Task 6

CREATE TABLE Dim_SOR (
    sor_sk INT IDENTITY(1,1) PRIMARY KEY,
    staging_table_name NVARCHAR(255),
    dimension_table_name NVARCHAR(255)
);

CREATE TABLE Fact_Error (
    fact_error_id INT IDENTITY(1,1) PRIMARY KEY,
    order_id_nk INT,
    customer_id_nk NVARCHAR(255),
    employee_id_nk INT,
    shipper_id_nk INT,
    order_date DATE,
    shipped_date DATE,
    freight MONEY,
    staging_raw_id_sk INT,
    sor_sk INT
);