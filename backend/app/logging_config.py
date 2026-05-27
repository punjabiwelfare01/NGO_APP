import logging
import logging.handlers
from pathlib import Path

LOG_DIR = Path(__file__).parent.parent / "logs"
LOG_DIR.mkdir(exist_ok=True)

_FMT = "%(asctime)s | %(levelname)-8s | %(name)-30s | %(message)s"
_DATE = "%Y-%m-%d %H:%M:%S"


def setup_logging(level: str = "INFO") -> None:
    root = logging.getLogger()
    root.setLevel(getattr(logging, level.upper(), logging.INFO))

    if root.handlers:
        return  # already configured (e.g. uvicorn already set up handlers)

    formatter = logging.Formatter(_FMT, datefmt=_DATE)

    # ── console ────────────────────────────────────────────────────────────────
    console = logging.StreamHandler()
    console.setFormatter(formatter)
    root.addHandler(console)

    # ── app.log  (INFO+, 5 MB, 5 backups) ─────────────────────────────────────
    app_file = logging.handlers.RotatingFileHandler(
        LOG_DIR / "app.log",
        maxBytes=5 * 1024 * 1024,
        backupCount=5,
        encoding="utf-8",
    )
    app_file.setFormatter(formatter)
    root.addHandler(app_file)

    # ── error.log  (ERROR+ only, 5 MB, 3 backups) ─────────────────────────────
    err_file = logging.handlers.RotatingFileHandler(
        LOG_DIR / "error.log",
        maxBytes=5 * 1024 * 1024,
        backupCount=3,
        encoding="utf-8",
    )
    err_file.setLevel(logging.ERROR)
    err_file.setFormatter(formatter)
    root.addHandler(err_file)

    # ── suppress noisy third-party loggers ────────────────────────────────────
    logging.getLogger("uvicorn.access").setLevel(logging.WARNING)
    logging.getLogger("sqlalchemy.engine").setLevel(logging.WARNING)
    logging.getLogger("passlib").setLevel(logging.WARNING)


logger = logging.getLogger("careskill")
