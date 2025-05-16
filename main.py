import argparse
from pipeline_dimensional_data.flow import DimensionalDataFlow
from utils import get_db_connection

def main():
    # Step 1: Parse command-line arguments
    parser = argparse.ArgumentParser(description="Run Dimensional Data Flow Pipeline")
    parser.add_argument("--start_date", required=True, help="Start date (YYYY-MM-DD)")
    parser.add_argument("--end_date", required=True, help="End date (YYYY-MM-DD)")
    args = parser.parse_args()

    # Step 2: Connect to DB
    connection = get_db_connection()

    # Step 3: Run the pipeline
    flow = DimensionalDataFlow(connection)
    flow.exec(start_date=args.start_date, end_date=args.end_date)

if __name__ == "__main__":
    main()
