import os
import logging
from logging import FileHandler, StreamHandler, Formatter, getLogger, DEBUG
from colorama import Fore, Style, init

init(autoreset=True)

LOG_PATH = "logs/logs_dimensional_data_pipeline.txt"
os.makedirs(os.path.dirname(LOG_PATH), exist_ok=True)

base_logger = getLogger("DimensionalDataFlow")
base_logger.setLevel(DEBUG)

if not base_logger.hasHandlers():
    file_handler = FileHandler(LOG_PATH, encoding="utf-8")
    file_handler.setLevel(DEBUG)

    stream_handler = StreamHandler()
    stream_handler.setLevel(DEBUG)

    file_formatter = Formatter(
        fmt="%(asctime)s - %(levelname)s - [ExecutionID: %(execution_id)s] - %(message)s",
        datefmt="%Y-%m-%d %H:%M:%S"
    )
    file_handler.setFormatter(file_formatter)
    stream_handler.setFormatter(file_formatter)

    base_logger.addHandler(file_handler)
    base_logger.addHandler(stream_handler)

logger = logging.LoggerAdapter(base_logger, {'execution_id': 'N/A'})


class ColoredFormatter(Formatter):
    def format(self, record):
        if not hasattr(record, 'execution_id'):
            record.execution_id = 'N/A'

        if record.levelname == "INFO":
            record.msg = f"{Fore.GREEN}{record.msg}{Style.RESET_ALL}"
        elif record.levelname == "ERROR":
            record.msg = f"{Fore.RED}{record.msg}{Style.RESET_ALL}"
        elif record.levelname == "DEBUG":
            record.msg = f"{Fore.YELLOW}{record.msg}{Style.RESET_ALL}"

        return super().format(record)
