import enum
from typing import ClassVar, List

from .reporter import BuiltinReporter, Report, Reporter
from .vtech_reporter import VtechReporter
from .. import config


class ReporterEnum(enum.Enum):
    BUILTIN: ClassVar[BuiltinReporter] = BuiltinReporter
    VTECH: ClassVar[VtechReporter] = VtechReporter


def get_reporters() -> List[Reporter]:
    reporter_name: str
    return [ReporterEnum[reporter_name].value() for reporter_name in config.get_config().report.enabled_reporters]


def report(rpt: Report):
    reporter: Reporter
    for reporter in get_reporters():
        reporter.report(rpt)
