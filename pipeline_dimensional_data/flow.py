from pipeline_dimensional_data.tasks import (

    create_tables_task,
    populate_dim_sor_task,
    update_all_dimensions_task,
    update_fact_task,
    update_fact_error_task
)
from utils import execute_sql_file, generate_execution_id
from logging import get_logger


class DimensionalDataFlow:
    def __init__(self, connection):
        self.execution_id = generate_execution_id()
        self.logger = get_logger(self.execution_id)
        self.connection = connection

    def exec(self, start_date, end_date):
        self.logger.info(f"🔁 Starting DimensionalDataFlow run: {self.execution_id}")

        if not create_tables_task(self.connection)["success"]:
            self.logger.error("❌ Aborted: create_tables_task failed")
            return

        self.logger.info("✅ Tables created successfully.")

        if not populate_dim_sor_task(self.connection)["success"]:
            self.logger.error("❌ Aborted: populate_dim_sor_task failed")
            return

        self.logger.info("✅ Dim_SOR populated successfully.")

        if not update_all_dimensions_task(self.connection)["success"]:
            self.logger.error("❌ Aborted: update_all_dimensions_task failed")
            return

        self.logger.info("✅ All dimensions updated successfully.")

        if not update_fact_task(self.connection, start_date, end_date)["success"]:
            self.logger.error("❌ Aborted: update_fact_task failed")
            return

        self.logger.info("✅ Fact table updated successfully.")

        if not update_fact_error_task(self.connection, start_date, end_date)["success"]:
            self.logger.error("❌ Aborted: update_fact_error_task failed")
            return

        self.logger.info("✅ Fact error table updated successfully.")
        self.logger.info("🎉 DimensionalDataFlow execution completed successfully.")
