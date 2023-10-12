import datetime
import enum
import io
import os
import threading
from typing import ClassVar

import icd_provisioner_sdk as sdk

from .reporter import Report, Reporter
from .. import config

lock: threading.Lock = threading.Lock()


class VtechTasksResult(enum.Enum):
    FAILED: ClassVar[str] = 'FAIL'
    PASSED: ClassVar[str] = 'PASS'


class VtechReporter(Reporter, metaclass=sdk.SingletonABCMeta):
    def __init__(self):
        self.path: str = config.get_config().report.vtech_reporter.path
        if not os.path.exists(os.path.dirname(self.path)):
            os.makedirs(os.path.dirname(self.path))

    def report(self, rpt: Report):
        with lock:
            dt: datetime.datetime = rpt.timestamp or datetime.datetime.now()
            f: io.TextIOBase
            with open(self.path, 'a', encoding='utf-8') as f:
                f.write((
                    f'{rpt.mfg_sn} {rpt.device_id} {dt:%Y%m%d%H%M%S} '
                    f'{VtechTasksResult[rpt.content].value} {rpt.operator_id}{os.linesep}'))
