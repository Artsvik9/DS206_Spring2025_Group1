from pipeline_dimensional_data.tasks import (
    create_tables_task,
    load_raw_data_task,
    update_dimensional_tables_task,
    ingest_fact_table_task,
    ingest_fact_error_task,
    populate_dim_sor_task,
)
from utils import generate_uuid
from pipeline_dimensional_data.custom_logging import logger

class DimensionalDataFlow:
    """
    Orchestrates the ETL pipeline for the dimensional data warehouse.
    """

    def __init__(self):
        self.execution_id = generate_uuid()
        self.tasks_status = {}

    def exec(self, start_date: str, end_date: str):
        logger.info("Creating tables...", extra={'execution_id': self.execution_id})
        logger.error("Fact table ingestion failed.", extra={'execution_id': self.execution_id})

        try:
            self.tasks_status['create_tables'] = create_tables_task()
            if not self.tasks_status['create_tables']['success']:
                raise Exception("Create tables failed.")

            self.tasks_status['load_raw_data'] = load_raw_data_task("raw_data_source.xlsx")
            if not self.tasks_status['load_raw_data']['success']:
                raise Exception("Raw data load failed.")

            dim_query_dir = "pipeline_dimensional_data/queries"
            self.tasks_status['update_dim_tables'] = update_dimensional_tables_task(dim_query_dir)
            if not self.tasks_status['update_dim_tables']['success']:
                raise Exception("Update dimensional tables failed.")

            fact_file = f"{dim_query_dir}/update_fact.sql"
            self.tasks_status['ingest_fact'] = ingest_fact_table_task(fact_file, start_date, end_date)
            if not self.tasks_status['ingest_fact']['success']:
                raise Exception("Fact table ingestion failed.")

            fact_error_file = f"{dim_query_dir}/update_fact_error.sql"
            self.tasks_status['ingest_fact_error'] = ingest_fact_error_task(fact_error_file, start_date, end_date)
            if not self.tasks_status['ingest_fact_error']['success']:
                raise Exception("FactError table ingestion failed.")

            dim_sor_file = f"{dim_query_dir}/update_dim_sor.sql"
            self.tasks_status['populate_dim_sor'] = populate_dim_sor_task(dim_sor_file)
            if not self.tasks_status['populate_dim_sor']['success']:
                raise Exception("Dim_SOR population failed.")

            logger.info(f"[FLOW] Execution {self.execution_id} completed successfully.")
            return self.tasks_status

        except Exception as e:
            logger.error(f"[FLOW] Execution {self.execution_id} failed: {e}", exc_info=True)
            self.tasks_status['error'] = str(e)
            return self.tasks_status