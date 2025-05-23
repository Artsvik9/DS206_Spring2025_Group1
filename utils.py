import os
import pyodbc
import uuid
import pandas as pd
from custom_logging import logger
from pipeline_dimensional_data.config import get_db_config, ensure_database_exists
import numpy as np
from decimal import Decimal

# Generate unique UUID for task execution tracking
def generate_uuid() -> str:
    """
    Generates a unique UUID string.
    Returns:
        str: A unique UUID string.
    """
    return str(uuid.uuid4())

# Database connection handler
# def get_db_connection():
#     """Establishes a database connection using config."""
#     ensure_database_exists()
#     db_config = get_db_config()
#     connection_string = (
#         f"Driver={db_config['driver']};"
#         f"Server={db_config['server']};"
#         f"Database={db_config['database']};"
#         f"UID={db_config['user']};"
#         f"PWD={db_config['password']};"
#         f"TrustServerCertificate=yes;"
#     )
#     return pyodbc.connect(connection_string)

import configparser
import pyodbc
from custom_logging import logger

def get_db_connection(target_db=None):
    config = configparser.ConfigParser()
    config.read("sql_server_config.cfg")

    db_name = target_db if target_db else config.get("SQL_SERVER", "database")

    conn_str = (
        f"DRIVER={config.get('SQL_SERVER', 'driver')};"
        f"SERVER={config.get('SQL_SERVER', 'server')};"
        f"DATABASE={db_name};"
        f"UID={config.get('SQL_SERVER', 'user')};"
        f"PWD={config.get('SQL_SERVER', 'password')};"
        "TrustServerCertificate=yes;"
    )

    try:
        connection = pyodbc.connect(conn_str)
        return connection
    except Exception as e:
        logger.error(f"Database connection failed: {e}")
        raise


def ensure_database_exists():
    """
    Ensures that the 'DimensionalPipeline' database exists.
    If not, creates it. Returns a connection to that DB.
    """
    try:
        logger.info("Ensuring DimensionalPipeline database exists...")
        conn = get_db_connection(target_db="master")
        conn.autocommit = True  
        cursor = conn.cursor()

        cursor.execute("""
            IF NOT EXISTS (
                SELECT name 
                FROM sys.databases 
                WHERE name = 'DimensionalPipeline'
            )
            BEGIN
                CREATE DATABASE DimensionalPipeline;
            END
        """)

        logger.info("DimensionalPipeline database ensured.")

        # Return connection to DimensionalPipeline
        return get_db_connection(target_db="DimensionalPipeline")

    except Exception as e:
        logger.error(f"Failed to ensure database exists: {e}", exc_info=True)
        raise


# SQL execution utility
def execute_sql_script_from_file(file_path: str, config_file='sql_server_config.cfg'):
    """
    Reads an SQL script from a file and executes it using a database connection.

    Args:
        file_path (str): Path to the .sql file.
        config_file (str): Path to the configuration file.

    Returns:
        None: Executes the SQL script without returning a result.
    """
    ensure_database_exists()

    db_config = get_db_config(config_file)

    connection_string = (
        f"Driver={db_config['driver']};"
        f"Server={db_config['server']};"
        f"Database={db_config['database']};"
        f"UID={db_config['user']};"
        f"PWD={db_config['password']};"
        f"TrustServerCertificate=yes;"
    )

    try:
        logger.info("Connecting to the database...")
        with pyodbc.connect(connection_string, autocommit=True) as conn:
            logger.info("Connection established successfully.")

            with open(file_path, 'r', encoding='utf-8') as sql_file:
                sql_script = sql_file.read()
                logger.info(f"Loaded SQL script from: {file_path}")

            sql_statements = sql_script.split(';')
            logger.info(f"SQL script contains {len(sql_statements)} statements.")

            with conn.cursor() as cursor:
                for i, statement in enumerate(sql_statements):
                    statement = statement.strip()
                    if statement:
                        logger.debug(f"Executing statement {i + 1}: {statement[:50]}...")
                        try:
                            cursor.execute(statement)
                            logger.info(f"Statement {i + 1} executed successfully.")
                        except pyodbc.Error as e:
                            logger.error(f"Error executing statement {i + 1}: {str(e)}", exc_info=True)

            logger.info(f"All statements executed successfully from: {file_path}")

    except FileNotFoundError:
        logger.error(f"File not found: {file_path}", exc_info=True)
    except pyodbc.Error as e:
        logger.error(f"Database connection or execution failed: {str(e)}", exc_info=True)
    except Exception as e:
        logger.error(f"An unexpected error occurred: {str(e)}", exc_info=True)

def execute_sql_inserts(df, table_name, conn):
    cursor = conn.cursor()

    try:
        cursor.execute("USE ORDER_DDS;")
    except Exception as e:
        logger.warning(f"Could not switch database context: {e}", exc_info=True)

    for index, row in df.iterrows():
        try:
            cleaned_row = []
            for col, x, dtype in zip(df.columns, row, df.dtypes):
                if table_name == "Staging_Customers" and col == "CustomerID":
                    cleaned_row.append(str(x).strip() if pd.notnull(x) else None)
                elif table_name == "Staging_Employees" and col in ["EmployeeID", "ReportsTo"]:
                    cleaned_row.append(int(x) if pd.notnull(x) else None)
                elif table_name == "Staging_Employees" and col in ["BirthDate", "HireDate"]:
                    cleaned_row.append(pd.to_datetime(x, errors='coerce') if pd.notnull(x) else None)
                elif table_name == "Staging_OrderDetails" and col in ["OrderID", "ProductID", "Quantity"]:
                    cleaned_row.append(int(x) if pd.notnull(x) else None)
                elif table_name == "Staging_Orders" and col in ["OrderDate", "ShippedDate", "RequiredDate"]:
                    cleaned_row.append(pd.to_datetime(x, errors='coerce') if pd.notnull(x) else None)
                elif dtype.kind == 'i':
                    cleaned_row.append(int(x) if pd.notnull(x) else None)
                elif dtype.kind == 'f':
                    cleaned_row.append(Decimal(str(x)).quantize(Decimal("0.00")) if pd.notnull(x) else None)
                elif dtype.kind == 'O':
                    cleaned_row.append(str(x).strip() if pd.notnull(x) else None)
                elif table_name == "Staging_Categories" and col == "CategoryID":
                    cleaned_row.append(int(x) if pd.notnull(x) else None)
                elif table_name == "Staging_Categories" and col in ["CategoryName", "Description"]:
                    cleaned_row.append(str(x).strip() if pd.notnull(x) else None)
                else:
                    cleaned_row.append(None)

            placeholders = ", ".join(["?" for _ in cleaned_row])
            insert_query = f"INSERT INTO {table_name} ({', '.join(df.columns)}) VALUES ({placeholders})"

            try:
                cursor.execute(insert_query, tuple(cleaned_row))
            except pyodbc.ProgrammingError as e:
                if "Invalid object name" in str(e):
                    logger.warning(f"Skipping insert: Table not found - likely already processed.")
                    continue
                else:
                    raise

        except Exception as e:
            logger.error(f"Failed to insert row {index} into {table_name}: {e}", exc_info=True)

    conn.commit()
    logger.info(f"Inserted {len(df)} rows into {table_name}.")

#Loading raw data in db
def load_raw_data_to_staging(raw_data_source: str):
    """
    Loads raw data from an Excel file into staging tables in the database.
    """
    conn = get_db_connection()
    try:
        # Load data from Excel sheets
        df_products = pd.read_excel(raw_data_source, sheet_name='Products')
        df_region = pd.read_excel(raw_data_source, sheet_name='Region')
        df_shippers = pd.read_excel(raw_data_source, sheet_name='Shippers')
        df_suppliers = pd.read_excel(raw_data_source, sheet_name='Suppliers')
        df_suppliers.sort_values(by='Phone', ascending=True, na_position='first', inplace=True)
        df_suppliers['Phone'] = df_suppliers['Phone'].astype(str)
        df_suppliers.replace({np.nan: None, np.inf: None, -np.inf: None}, inplace=True)
        df_territories = pd.read_excel(raw_data_source, sheet_name='Territories')
        df_orders = pd.read_excel(raw_data_source, sheet_name='Orders')
        df_customers = pd.read_excel(raw_data_source, sheet_name='Customers')
        df_employees = pd.read_excel(raw_data_source, sheet_name='Employees')
        df_order_details = pd.read_excel(raw_data_source, sheet_name='OrderDetails')
        df_categories = pd.read_excel(raw_data_source, sheet_name='Categories')

        # Insert data into respective tables
        execute_sql_inserts(df_products, 'Staging_Products', conn)
        execute_sql_inserts(df_region, 'Staging_Region', conn)
        execute_sql_inserts(df_shippers, 'Staging_Shippers', conn)
        execute_sql_inserts(df_suppliers, 'Staging_Suppliers', conn)
        execute_sql_inserts(df_territories, 'Staging_Territories', conn)
        execute_sql_inserts(df_orders, 'Staging_Orders', conn)
        execute_sql_inserts(df_customers, 'Staging_Customers', conn)
        execute_sql_inserts(df_employees, 'Staging_Employees', conn)
        execute_sql_inserts(df_order_details, 'Staging_OrderDetails', conn)
        execute_sql_inserts(df_categories, 'Staging_Categories', conn)

    except Exception as e:
        logger.error(f"Error loading raw data to staging: {e}", exc_info=True)
    finally:
        if conn:
            conn.close()
            logger.info("Database connection closed.")



def update_dimensional_tables(query_directory: str = "pipeline_dimensional_data/queries"):
    """
    Automatically updates dimensional tables by executing all SQL scripts in the specified directory.

    Args:
        query_directory (str): Path to the directory containing SQL query files.
    """
    conn = get_db_connection()
    try:
        sql_files = [
            os.path.join(query_directory, file)
            for file in os.listdir(query_directory)
            if file.endswith('.sql')
        ]

        if not sql_files:
            logger.warning(f"No SQL scripts found in directory: {query_directory}")
            return

        for script_path in sql_files:
            try:
                logger.info(f"Executing script: {script_path}")

                with open(script_path, 'r', encoding='utf-8') as sql_file:
                    sql_script = sql_file.read()

                cursor = conn.cursor()
                cursor.execute(sql_script)
                conn.commit()

                logger.info(f"Successfully executed script: {script_path}")

            except FileNotFoundError:
                logger.error(f"File not found: {script_path}", exc_info=True)
            except pyodbc.Error as e:
                logger.error(f"Error executing script {script_path}: {str(e)}", exc_info=True)
            except Exception as e:
                logger.error(f"An unexpected error occurred while executing {script_path}: {str(e)}", exc_info=True)

    except Exception as e:
        logger.error(f"Error during the update process: {str(e)}", exc_info=True)

    finally:
        if conn:
            conn.close()
            logger.info("Database connection closed.")


def update_fact_orders(start_date, end_date):
    """
    Updates the FactOrders table based on data in the staging and dimension tables.
    The SQL logic is read from an external file for better separation of concerns.
    """
    conn = get_db_connection()

    try:
        cursor = conn.cursor()

        if not start_date or not end_date:
            logger.warning("No valid date range provided. Skipping FactOrders update.")
            return
        
        # Load SQL file and format with dynamic dates
        sql_file_path = os.path.join("pipeline_dimensional_data", "queries", "update_fact.sql")
        
        with open(sql_file_path, "r", encoding="utf-8") as file:
            fact_orders_query = file.read().format(start_date=start_date, end_date=end_date)

        # Execute the query
        logger.info("Updating FactOrders table...")
        cursor.execute(fact_orders_query)
        conn.commit()
        logger.info("FactOrders table updated successfully.")

    except FileNotFoundError:
        logger.error(f"SQL file not found: {sql_file_path}", exc_info=True)
    except Exception as e:
        logger.error(f"Failed to update FactOrders table: {e}", exc_info=True)
    
    finally:
        if conn:
            conn.close()
            logger.info("Database connection closed.")

def update_fact_error_table():
    """
    Updates the FactError table by detecting faulty records in the FactOrders pipeline.
    Dynamically calculates the earliest and latest OrderDate from Staging_Orders.
    """
    conn = get_db_connection()

    try:
        # Determine date range
        date_query = """
        SELECT MIN(OrderDate) AS StartDate, MAX(OrderDate) AS EndDate
        FROM dbo.Staging_Orders;
        """
        cursor = conn.cursor()
        cursor.execute(date_query)
        start_date, end_date = cursor.fetchone()

        if not start_date or not end_date:
            logger.warning("No orders found in Staging_Orders. Skipping FactError update.")
            return

        fact_error_query = """
        INSERT INTO dbo.FactError (
            ErrorID, Staging_Raw_ID, OrderID, CustomerID, EmployeeID, 
            ShipVia, ProductID, OrderDate, Quantity, TotalAmount, Discount, ErrorReason
        )
        SELECT
            NEWID() AS ErrorID,
            so.Staging_Raw_ID,
            so.OrderID,
            so.CustomerID,
            so.EmployeeID,
            so.ShipVia,
            sod.ProductID,
            so.OrderDate,
            sod.Quantity,
            sod.UnitPrice * sod.Quantity AS TotalAmount,
            sod.Discount,
            CASE
                WHEN dc.CustomerKey IS NULL THEN 'Missing Customer'
                WHEN de.EmployeeKey IS NULL THEN 'Missing Employee'
                WHEN ds.ShipperKey IS NULL THEN 'Missing Shipper'
                WHEN dp.ProductKey IS NULL THEN 'Missing Product'
                WHEN sod.Quantity <= 0 THEN 'Invalid Quantity'
                WHEN sod.UnitPrice * sod.Quantity <= 0 THEN 'Invalid Amount'
                WHEN sod.Discount < 0 THEN 'Invalid Discount'
                ELSE 'Unknown Error'
            END AS ErrorReason
        FROM dbo.Staging_Orders so
        JOIN dbo.Staging_OrderDetails sod ON sod.OrderID = so.OrderID
        LEFT JOIN dbo.DimCustomers dc ON so.CustomerID = dc.CustomerID
        LEFT JOIN dbo.DimEmployees de ON so.EmployeeID = de.EmployeeID
        LEFT JOIN dbo.DimShippers ds ON so.ShipVia = ds.ShipperID
        LEFT JOIN dbo.DimProducts dp ON sod.ProductID = dp.ProductID
        WHERE so.OrderDate BETWEEN ? AND ?
        AND (
            dc.CustomerKey IS NULL OR
            de.EmployeeKey IS NULL OR
            ds.ShipperKey IS NULL OR
            dp.ProductKey IS NULL OR
            sod.Quantity <= 0 OR
            sod.UnitPrice * sod.Quantity <= 0 OR
            sod.Discount < 0
        );
        """

        logger.info("Inserting records into FactError table...")
        cursor.execute(fact_error_query, (start_date, end_date))
        conn.commit()
        logger.info("FactError table updated successfully.")

    except Exception as e:
        logger.error(f"Failed to update FactError table: {e}", exc_info=True)

    finally:
        if conn:
            conn.close()
            logger.info("Database connection closed.")


def populate_dim_sor():
    conn = get_db_connection()
    sql_file_path = os.path.join("pipeline_dimensional_data", "queries", "update_dim_sor.sql")
    
    try:
        with open(sql_file_path, "r", encoding="utf-8") as file:
            query = file.read()

        cursor = conn.cursor()
        cursor.execute(query)
        conn.commit()
        print("Dim_SOR table populated successfully.")
        
    except FileNotFoundError:
        print(f"SQL file not found: {sql_file_path}", exc_info=True)
        
    except Exception as e:
        print(f"Failed to populate Dim_SOR: {e}", exc_info=True)
        
    finally:
        conn.close()