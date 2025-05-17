import configparser
import os
import pyodbc
from custom_logging import logger


def get_db_config(config_file: str = './sql_server_config.cfg') -> dict:
    """
    Reads database connection details from a .cfg file.
    """
    config = configparser.ConfigParser()
    config.read(config_file)

    if 'SQL_SERVER' not in config:
        raise KeyError("'SQL_SERVER' section not found in the configuration file.")

    return {
        'driver': config['SQL_SERVER']['driver'],
        'server': config['SQL_SERVER']['server'],
        'database': config['SQL_SERVER']['database'],
        'user': config['SQL_SERVER']['user'],
        'password': config['SQL_SERVER']['password']
    }


def get_db_connection(default_db: str = None) -> pyodbc.Connection:
    """
    Connects to the database defined in the config (ORDER_DDS).
    """
    db_config = get_db_config()
    database = default_db or db_config['database']

    conn_str = (
        f"DRIVER={{{db_config['driver']}}};"
        f"SERVER={db_config['server']};"
        f"DATABASE={database};"
        f"UID={db_config['user']};"
        f"PWD={db_config['password']};"
        f"TrustServerCertificate=yes;"
    )
    return pyodbc.connect(conn_str)


def ensure_database_exists(db_creation_sql_path: str = 'infrastructure_initiation/dimensional_db_creation.sql') -> None:
    """
    Connects to master, drops and recreates ORDER_DDS using the SQL script.
    """
    if not os.path.exists(db_creation_sql_path):
        raise FileNotFoundError(f"Database creation script not found: {db_creation_sql_path}")

    db_config = get_db_config()
    master_conn_str = (
        f"DRIVER={{{db_config['driver']}}};"
        f"SERVER={db_config['server']};"
        f"DATABASE=master;"
        f"UID={db_config['user']};"
        f"PWD={db_config['password']};"
        f"TrustServerCertificate=yes;"
    )

    try:
        with pyodbc.connect(master_conn_str, autocommit=True) as conn:
            with conn.cursor() as cursor:
                with open(db_creation_sql_path, 'r', encoding='utf-8') as file:
                    script = file.read()
                cursor.execute(script)
                logger.info("Database creation script executed successfully.")
    except pyodbc.Error as e:
        logger.error(f"Database creation failed: {e}")
        raise