import pyodbc

import uuid

def generate_execution_id():
    return str(uuid.uuid4())

def execute_sql_file(file_path, connection):
    """
    Reads a SQL script from the file and executes it using the given database connection.
    """
    try:
        with open(file_path, 'r') as file:
            sql_script = file.read()

        cursor = connection.cursor()
        cursor.execute(sql_script)
        connection.commit()
        print(f"✅ Successfully executed: {file_path}")
    except Exception as e:
        print(f"❌ Failed to execute {file_path}: {str(e)}")

def get_db_connection():
    connection_str = (
        "Driver={ODBC Driver 18 for SQL Server};"
        "Server=localhost;"
        "Database=ORDER_DDS;"
        "Trusted_Connection=yes;"
    )
    return pyodbc.connect(connection_str)


