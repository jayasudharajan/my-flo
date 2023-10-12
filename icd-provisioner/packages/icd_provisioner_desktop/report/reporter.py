import abc
import dataclasses
import datetime
import io
import os
from typing import Optional

import icd_provisioner_sdk as sdk
import xdg


@dataclasses.dataclass
class Report:
    content: str
    device_id: str
    mfg_sn: str = ''
    operator_id: str = ''
    timestamp: Optional[datetime.datetime] = None


class Reporter(metaclass=abc.ABCMeta):
    @abc.abstractmethod
    def report(self, rpt: Report):
        pass


class BuiltinReporter(Reporter, metaclass=sdk.SingletonABCMeta):
    def __init__(self):
        self.report_folder: str = os.path.join(
            os.environ['LOCALAPPDATA'] if os.name == 'nt' else xdg.XDG_DATA_HOME,
            'Flo', 'icd-provisioner', 'Logs')
        if not os.path.exists(self.report_folder):
            os.makedirs(self.report_folder)

    def report(self, rpt: Report):
        dt: datetime.datetime = rpt.timestamp or datetime.datetime.now()
        report_file: str = os.path.join(
            self.report_folder, f'{rpt.device_id}.txt' if rpt.device_id else 'no-device-id.txt')
        f: io.TextIOBase
        with open(report_file, 'a', encoding='utf-8') as f:
            f.write(
                f'{dt.utcnow()}\t{rpt.device_id}\t{rpt.mfg_sn}\t'
                f'{rpt.operator_id}\t{rpt.content}\t{os.linesep}')
