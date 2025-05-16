import logging

def get_logger(execution_id):
    logger = logging.getLogger(f"DimensionalFlow_{execution_id}")
    logger.setLevel(logging.INFO)

    # Prevent duplicate handlers if function is called multiple times
    if not logger.handlers:
        file_handler = logging.FileHandler("logs/logs_dimensional_data_pipeline.txt")
        formatter = logging.Formatter(
            f"%(asctime)s | %(levelname)s | execution_id: {execution_id} | %(message)s"
        )
        file_handler.setFormatter(formatter)
        logger.addHandler(file_handler)

    return logger
