import datetime
import enum
from typing import Optional

import icd_provisioner_sdk as sdk

from .view_model import StoppableViewModel, TasksStatus, VM
from .. import config
from .. import listen
from .. import model
from .. import report


class UnlockViewModel(StoppableViewModel):
    def __init__(self, parent: Optional[VM] = None):
        super().__init__(False, True, parent)
        self.startable.set_value(False)
        self.device_id: listen.DuplicationFreeListenable = listen.DuplicationFreeListenable()
        self.device_id.add_on_value_changed_listener(self.on_device_id_changed_listener)
        self.mfg_sn: listen.DuplicationFreeListenable = listen.DuplicationFreeListenable('')
        self.mfg_sn.add_on_value_changed_listener(self.on_mfg_sn_changed_listener)

    def on_device_id_changed_listener(self, device_id: str):
        self.clear_progresses()
        mfg_sn_count: int = 0 if config.get_config().mfg_sn_count is None else config.get_config().mfg_sn_count
        self.startable.set_value(sdk.is_valid_device_id(device_id) and len(self.mfg_sn.get_value()) == mfg_sn_count)

    def on_mfg_sn_changed_listener(self, mfg_sn: str):
        self.clear_progresses()
        mfg_sn_count: int = 0 if config.get_config().mfg_sn_count is None else config.get_config().mfg_sn_count
        self.startable.set_value(sdk.is_valid_device_id(self.device_id.get_value()) and len(mfg_sn) == mfg_sn_count)
        if mfg_sn_count > 0 and self.startable.get_value():
            self.started.set_value(True)

    def on_started_changed_listener(self, started: bool):
        super().on_started_changed_listener(started)
        if started:
            self.clear_progresses()
            self.start_process()

    def on_model_progress_listener(self, unlock_task_enum: enum.Enum, progress: str):
        if unlock_task_enum in self.progress:
            self.progress[unlock_task_enum].set_value(progress)

    def on_model_done_listener(self, unlock_task_enum: enum.Enum, result: str, error: str):
        if unlock_task_enum in self.progress:
            self.progress[unlock_task_enum].set_value(error if error else result)

        if error or sdk.is_final_enum(unlock_task_enum):
            if self.started.get_value():
                self.started.set_value(False)
            self.tasks_status.set_value(TasksStatus.FAILED.value if error else TasksStatus.PASSED.value)
            report.report(report.Report(
                device_id=self.device_id.get_value(),
                mfg_sn=self.mfg_sn.get_value(),
                operator_id=self.parent.unlock_operator_id.get_value(),
                content=TasksStatus.FAILED.name if error else TasksStatus.PASSED.name,
                timestamp=datetime.datetime.now()))

    def start_process(self):
        self.tasks_status.set_value(TasksStatus.PROCESSING.value)
        unlock_model: model = model.TaskChainModel(
            model.get_unlock_model_qrunnables(self.device_id.get_value()),
            self.on_model_done_listener,
            self.on_model_progress_listener)
        unlock_model.start()
