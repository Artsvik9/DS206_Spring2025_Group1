import configparser
import os
import pyodbc
from custom_logging import logger


def get_db_config(config_file: str = './sql_server_config.cfg') -> dict:
    """
    Reads database connection details from a .cfg file.

    Args:
        config_file (str): Path to the config file.

    Returns:
        dict: Dictionary of DB connection parameters.
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
    Establishes a connection to the specified database or the default one from config.

    Args:
        default_db (str, optional): Name of the DB to connect to. Defaults to configured DB.

    Returns:
        pyodbc.Connection: Active DB connection object.
    """
    db_config = get_db_config()
    database = default_db or db_config['database']

    conn_str = (
        f"Driver={db_config['driver']};"
        f"Server={db_config['server']};"
        f"Database={database};"
        f"UID={db_config['user']};"
        f"PWD={db_config['password']};"
        f"TrustServerCertificate=yes;"
    )

    return pyodbc.connect(conn_str)


def ensure_database_exists(db_creation_sql_path: str = 'infrastructure_initiation/dimensional_db_creation.sql') -> None:
    """
    Ensures the target database exists. Creates it using the provided SQL script if needed.

    Args:
        db_creation_sql_path (str): Path to SQL file that creates the DB.
    """
    if not os.path.exists(db_creation_sql_path):
        raise FileNotFoundError(f"Database creation script not found: {db_creation_sql_path}")

    db_config = get_db_config()
    master_conn_str = (
        f"Driver={db_config['driver']};"
        f"Server={db_config['server']};"
        f"Database=master;"
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
