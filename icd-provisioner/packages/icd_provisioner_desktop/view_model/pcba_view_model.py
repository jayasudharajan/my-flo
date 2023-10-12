import datetime
import enum
from typing import ClassVar, Dict, Optional

import icd_provisioner_sdk as sdk

from .view_model import StoppableViewModel, TasksStatus, VM
from .. import config
from .. import listen
from .. import model
from .. import report


class PCBATasksStatus(enum.Enum):
    WAITING_FOR_THE_BUTTON: ClassVar[str] = '<font color="blue">WAITING FOR THE BUTTON</font>'
    WAITING_FOR_THE_HALL_EFFECT_SENSOR: ClassVar[str] = '<font color="blue">WAITING FOR THE HALL SENSOR</font>'


class PCBAViewModel(StoppableViewModel):
    def __init__(self, parent: Optional[VM] = None):
        super().__init__(False, True, parent)
        self.startable.set_value(False)
        self.device_id: listen.DuplicationFreeListenable = listen.DuplicationFreeListenable()
        self.billboard: listen.DuplicationFreeListenable = listen.DuplicationFreeListenable()
        self.mfg_sn: listen.DuplicationFreeListenable = listen.DuplicationFreeListenable('')
        self.mfg_sn.add_on_value_changed_listener(self.on_mfg_sn_changed_listener)
        self.port: listen.DuplicationFreeListenable = listen.DuplicationFreeListenable()
        self.port.add_on_value_changed_listener(self.on_port_changed_listener)
        self.ports: sdk.Listenable = sdk.Listenable()
        self.progress: Dict[enum.Enum, sdk.Listenable] = dict()
        self.product_variant: listen.DuplicationFreeListenable = listen.DuplicationFreeListenable('')
        self.product_variant.add_on_value_changed_listener(self.on_product_variant_changed_listener)

    def on_available_ports_changed_listener(self, ports: Dict[str, 'PCBAViewModel']):
        port: str
        selected: bool
        self.ports.set_value([''] + list(sorted(
            port for port, selected_by in ports.items() if not selected_by or selected_by is self)))

    def on_model_done_listener(self, pcba_progress_enum: enum.Enum, result: str, error: str):
        self.progress[pcba_progress_enum].set_value(error if error else result)
        self.billboard.set_value("")

        if error or sdk.is_final_enum(pcba_progress_enum):
            self.started.set_value(False)
            self.tasks_status.set_value(TasksStatus.FAILED.value if error else TasksStatus.PASSED.value)
            report.report(report.Report(
                device_id=self.device_id.get_value(),
                mfg_sn=self.mfg_sn.get_value(),
                operator_id=self.parent.pcba_operator_id.get_value(),
                content=TasksStatus.FAILED.name if error else TasksStatus.PASSED.name,
                timestamp=datetime.datetime.now()))

    def on_model_progress_listener(self, pcba_progress_enum: enum.Enum, progress: str):
        if PCBASimpleProgress.TIMEOUT.value in progress:
            progress = PCBASimpleProgress.TIMEOUT.value
        elif PCBASimpleProgress.DETECTING.value in progress:
            if 'BUTTON' in progress:
                self.tasks_status.set_value(PCBATasksStatus.WAITING_FOR_THE_BUTTON.value)
                self.billboard.set_value(PCBATasksStatus.WAITING_FOR_THE_BUTTON.value)
            elif 'HALL' in progress:
                self.tasks_status.set_value(PCBATasksStatus.WAITING_FOR_THE_HALL_EFFECT_SENSOR.value)
                self.billboard.set_value(PCBATasksStatus.WAITING_FOR_THE_HALL_EFFECT_SENSOR.value)
            progress = PCBASimpleProgress.DETECTING.value
        elif PCBASimpleProgress.DETECTED.value in progress:
            progress = PCBASimpleProgress.DETECTED.value
            self.tasks_status.set_value(TasksStatus.PROCESSING.value)
            self.billboard.set_value("")
        elif PCBASimpleProgress.MAC.value in progress:
            progress = progress.replace(PCBASimpleProgress.MAC.value, '')
            self.device_id.set_value(progress.replace(':', '').strip().lower())
        self.progress[pcba_progress_enum].set_value(progress)

    def on_product_variant_changed_listener(self, product_variant: str):
        self.clear_progresses()
        mfg_sn_count: int = 0 if config.get_config().mfg_sn_count is None else config.get_config().mfg_sn_count
        self.startable.set_value(bool(
            bool(self.port.get_value())
            and len(self.mfg_sn.get_value()) == mfg_sn_count
            and product_variant))

    def on_mfg_sn_changed_listener(self, mfg_sn: str):
        self.clear_progresses()
        mfg_sn_count: int = 0 if config.get_config().mfg_sn_count is None else config.get_config().mfg_sn_count
        self.startable.set_value(len(mfg_sn) == mfg_sn_count 
            and bool(self.port.get_value())
            and bool(len(self.product_variant.get_value())))
        if mfg_sn_count > 0 and self.startable.get_value():
            self.started.set_value(True)

    def on_port_changed_listener(self, port: str):
        self.clear_progresses()
        self.device_id.set_value('')
        mfg_sn_count: int = 0 if config.get_config().mfg_sn_count is None else config.get_config().mfg_sn_count
        self.startable.set_value(len(self.mfg_sn.get_value()) == mfg_sn_count 
            and bool(port)
            and bool(len(self.product_variant.get_value())))

    def on_started_changed_listener(self, started: bool):
        super().on_started_changed_listener(started)
        if started:
            self.device_id.set_value('')
            self.clear_progresses()
            self.start_process()

    def start_process(self):
        self.tasks_status.set_value(TasksStatus.PROCESSING.value)
        pcba_model: model = model.SingleTaskModel(
            model.get_pcba_model_qrunnable(
                self.port.get_value(), 
                config.PRODUCT_VARIANT_SYMBOL[config.ProductVariant(self.product_variant.get_value())]),
            self.on_model_done_listener,
            self.on_model_progress_listener)
        pcba_model.start()


class PCBASimpleProgress(enum.Enum):
    DETECTING: ClassVar[str] = 'DETECTING'
    DETECTED: ClassVar[str] = 'DETECTED'
    LOGGING_IN: ClassVar[str] = 'LOGGING IN'
    LOGGED_IN: ClassVar[str] = 'LOGGED IN'
    MAC: ClassVar[str] = 'MAC: '
    TIMEOUT: ClassVar[str] = 'TIMEOUT'
