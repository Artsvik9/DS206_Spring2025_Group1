USE ORDER_DDS;
GO
-- DimCustomers → SCD2
CREATE TABLE Dim_Customers (
    customer_table_sk INT IDENTITY(1,1) PRIMARY KEY,  -- unique row ID
    customer_durable_sk INT,                          -- constant per real-world customer
    customer_nk NVARCHAR(10),                         -- from staging: CustomerID
    company_name NVARCHAR(100),
    contact_name NVARCHAR(100),
    contact_title NVARCHAR(100),
    address NVARCHAR(255),
    city NVARCHAR(100),
    region NVARCHAR(100),
    postal_code NVARCHAR(20),
    country NVARCHAR(50),
    phone NVARCHAR(50),
    fax NVARCHAR(50),
    effective_date DATETIME,
    ineffective_date DATETIME,
    current_flag BIT,
    staging_raw_id_sk INT,
    sor_sk INT
);

-- DimCategories → SCD1 + Delete
CREATE TABLE Dim_Categories (
    category_durable_sk INT IDENTITY(1,1) PRIMARY KEY,  -- durable SK
    category_nk INT,                                     -- natural key (CategoryID)
    category_name NVARCHAR(100),
    description NVARCHAR(MAX),
    staging_raw_id_sk INT,
    sor_sk INT
);

-- DimEmployees → SCD1 + Delete
CREATE TABLE Dim_Employees (
    employee_durable_sk INT IDENTITY(1,1) PRIMARY KEY,
    employee_nk INT,  -- EmployeeID from source
    last_name NVARCHAR(100),
    first_name NVARCHAR(100),
    title NVARCHAR(100),
    title_of_courtesy NVARCHAR(100),
    birth_date DATETIME,
    hire_date DATETIME,
    address NVARCHAR(255),
    city NVARCHAR(100),
    region NVARCHAR(100),
    postal_code NVARCHAR(20),
    country NVARCHAR(50),
    home_phone NVARCHAR(50),
    extension NVARCHAR(10),
    photo IMAGE,
    notes NVARCHAR(MAX),
    reports_to INT, 
    photo_path NVARCHAR(255),
    staging_raw_id_sk INT,
    sor_sk INT
);

-- DimProducts → SCD4 
CREATE TABLE Dim_Products (
    product_durable_sk INT IDENTITY(1,1) PRIMARY KEY,
    product_nk INT,  -- ProductID
    product_name NVARCHAR(100),
    supplier_nk INT,
    category_nk INT,
    product_profile_sk INT,  -- FK to mini-dimension
    discontinued BIT,
    staging_raw_id_sk INT,
    sor_sk INT
);

CREATE TABLE Dim_Products_Profile (
    product_profile_sk INT IDENTITY(1,1) PRIMARY KEY,
    quantity_per_unit NVARCHAR(100),
    unit_price DECIMAL(10,2),
    units_in_stock SMALLINT,
    units_on_order SMALLINT,
    reorder_level SMALLINT
);

-- DimRegion → SCD1 
CREATE TABLE Dim_Region (
    region_durable_sk INT IDENTITY(1,1) PRIMARY KEY,
    region_nk INT,  -- RegionID
    region_description NVARCHAR(100),
    staging_raw_id_sk INT,
    sor_sk INT
);

-- DimShippers → SCD3
CREATE TABLE Dim_Shippers (
    shipper_durable_sk INT IDENTITY(1,1) PRIMARY KEY,
    shipper_nk INT,  -- ShipperID
    company_name NVARCHAR(100),
    current_phone NVARCHAR(50),
    previous_phone NVARCHAR(50),
    staging_raw_id_sk INT,
    sor_sk INT
);

-- DimSuppliers → SCD4

CREATE TABLE Dim_Suppliers (
    supplier_durable_sk INT IDENTITY(1,1) PRIMARY KEY,
    supplier_nk INT,  -- SupplierID from source
    company_name NVARCHAR(100),
    contact_name NVARCHAR(100),
    contact_title NVARCHAR(100),
    address NVARCHAR(255),
    city NVARCHAR(100),
    region NVARCHAR(100),
    postal_code NVARCHAR(20),
    country NVARCHAR(50),
    supplier_profile_sk INT,  -- FK to mini-dimension
    staging_raw_id_sk INT,
    sor_sk INT
);

CREATE TABLE Dim_Suppliers_Profile (
    supplier_profile_sk INT IDENTITY(1,1) PRIMARY KEY,
    phone NVARCHAR(50),
    fax NVARCHAR(50),
    homepage NVARCHAR(MAX)
);


-- DimTerritories → SCD3

CREATE TABLE Dim_Territories (
    territory_durable_sk INT IDENTITY(1,1) PRIMARY KEY,
    territory_nk INT,  -- TerritoryID from source
    region_nk INT,     -- RegionID (for later FK)
    current_description NVARCHAR(100),
    previous_description NVARCHAR(100),
    staging_raw_id_sk INT,
    sor_sk INT
);

-- FactOrders → SNAPSHOT

CREATE TABLE Fact_Orders (
    order_snapshot_sk INT IDENTITY(1,1) PRIMARY KEY,
    order_nk INT,  -- OrderID from source
    order_date DATETIME,
    required_date DATETIME,
    shipped_date DATETIME,
    product_sk INT,
    customer_sk INT,
    employee_sk INT,
    shipper_sk INT,
    territory_sk INT,
    category_sk INT,
    supplier_sk INT,
    quantity SMALLINT,
    unit_price DECIMAL(10, 2),
    discount FLOAT,
    freight DECIMAL(10, 2),
    staging_raw_id_sk INT,
    sor_sk INT
);


CREATE TABLE Dim_SOR (
    sor_sk INT IDENTITY(1,1) PRIMARY KEY,
    source_table_name NVARCHAR(100)
);


-- TASK 6
USE ORDER_DDS;
GO

INSERT INTO Dim_SOR (source_table_name) VALUES
('stg_raw_Categories'),
('stg_raw_Customers'),
('stg_raw_Employees'),
('stg_raw_OrderDetails'),
('stg_raw_Orders'),
('stg_raw_Products'),
('stg_raw_Region'),
('stg_raw_Shippers'),
('stg_raw_Suppliers'),
('stg_raw_Territories');


-- Created fact error for task 9
USE ORDER_DDS;
GO

CREATE TABLE fact_error (
    error_id INT IDENTITY(1,1) PRIMARY KEY,
    order_nk INT,
    customer_nk NVARCHAR(10),
    employee_nk INT,
    shipper_nk INT,
    order_date DATE,
    shipped_date DATE,
    freight DECIMAL(10,2),
    staging_raw_id_sk INT,
    sor_sk INT,
    error_timestamp DATETIME DEFAULT GETDATE()
);
