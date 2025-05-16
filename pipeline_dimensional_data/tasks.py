from utils import execute_sql_file

def create_tables_task(connection):
    try:
        execute_sql_file("infrastructure_initiation/dimensional_db_table_creation.sql", connection)
        return {"success": True}
    except Exception as e:
        print(f"❌ Failed to create tables: {str(e)}")
        return {"success": False}

def populate_dim_sor_task(connection):
    try:
        execute_sql_file("infrastructure_initiation/dim_sor_population.sql", connection)
        return {"success": True}
    except Exception as e:
        print(f"❌ Failed to populate Dim_SOR: {str(e)}")
        return {"success": False}

def update_all_dimensions_task(connection):
    try:
        dim_files = [
            "update_dim_categories.sql",
            "update_dim_customers.sql",
            "update_dim_employees.sql",
            "update_dim_products_profile.sql",
            "update_dim_products.sql",
            "update_dim_region.sql",
            "update_dim_shippers.sql",
            "update_dim_suppliers_profile.sql",
            "update_dim_suppliers.sql",
            "update_dim_territories.sql"
        ]
        
        for file in dim_files:
            path = f"pipeline_dimensional_data/queries/{file}"
            execute_sql_file(path, connection)

        return {"success": True}
    except Exception as e:
        print(f"❌ Failed updating dimensions: {str(e)}")
        return {"success": False}

def update_fact_task(connection, start_date, end_date):
    try:
        with open("pipeline_dimensional_data/queries/update_fact.sql", "r") as file:
            sql = file.read()
            sql = sql.replace("@start_date", f"'{start_date}'").replace("@end_date", f"'{end_date}'")
        
        cursor = connection.cursor()
        cursor.execute(sql)
        connection.commit()
        return {"success": True}
    except Exception as e:
        print(f"❌ Failed to update fact table: {str(e)}")
        return {"success": False}

def update_fact_error_task(connection, start_date, end_date):
    try:
        with open("pipeline_dimensional_data/queries/update_fact_error.sql", "r") as file:
            sql = file.read()
            sql = sql.replace("@start_date", f"'{start_date}'").replace("@end_date", f"'{end_date}'")
        
        cursor = connection.cursor()
        cursor.execute(sql)
        connection.commit()
        return {"success": True}
    except Exception as e:
        print(f"❌ Failed to update fact_error: {str(e)}")
        return {"success": False}
