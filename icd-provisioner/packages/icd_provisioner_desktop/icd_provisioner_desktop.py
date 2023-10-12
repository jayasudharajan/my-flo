import importlib.resources
import logging
import logging.handlers
import os
import pathlib
import sys

from PySide6.QtCore import Qt, QCoreApplication, QThreadPool
from PySide6.QtWidgets import QApplication
import xdg

from . import config
from . import ui
from . import view
from . import view_model


def init_logging():
    formatter = logging.Formatter(fmt='%(levelname)s: %(asctime)s %(name)s %(message)s')

    log_path: str = os.path.join(
        os.environ['LOCALAPPDATA'] if os.name == 'nt' else xdg.XDG_DATA_HOME,
        'Flo', 'icd-provisioner', 'Logs', 'log.log')
    if not os.path.exists(os.path.dirname(log_path)):
        os.makedirs(os.path.dirname(log_path))
    file_handler = logging.handlers.RotatingFileHandler(log_path, maxBytes=1024**2, backupCount=9)
    file_handler.setFormatter(formatter)
    file_handler.setLevel(logging.INFO)

    stream_handler = logging.StreamHandler()
    stream_handler.setFormatter(formatter)
    stream_handler.setLevel(logging.INFO)

    logger = logging.getLogger()
    logger.addHandler(stream_handler)
    logger.addHandler(file_handler)
    logger.setLevel(logging.INFO)


def main():
    init_logging()
    config.Argument()

    number_of_children: int = 2
    QCoreApplication.setAttribute(Qt.AA_ShareOpenGLContexts)
    QThreadPool.globalInstance().setMaxThreadCount(number_of_children * 3)  # We have 3 active tabs
    app: QApplication = QApplication()

    main_window_ui: pathlib.Path
    with importlib.resources.path(ui.__package__, 'main_window.ui') as main_window_ui:
        v: view.MainWindowView = view.MainWindowView(number_of_children)
        v.inflate(str(main_window_ui))
        v.bind(view_model.MainWindowViewModel(app, number_of_children))
        v.show()

    sys.exit(app.exec_())
