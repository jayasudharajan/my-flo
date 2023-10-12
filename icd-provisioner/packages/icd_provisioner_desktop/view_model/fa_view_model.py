import datetime
import enum
from typing import ClassVar, Dict, Optional

import icd_provisioner_sdk as sdk

from .view_model import StoppableViewModel, TasksStatus, VM
from .. import config
from .. import listen
from .. import model
from .. import report


class FATasksStatus(enum.Enum):
    WAITING_FOR_THE_BUTTON: ClassVar[str] = '<font color="blue">WAITING FOR THE BUTTON</font>'


class FAViewModel(StoppableViewModel):
    def __init__(self, parent: Optional[VM] = None):
        super().__init__(False, True, parent)
        self.startable.set_value(False)
        self.device_id: listen.DuplicationFreeListenable = listen.DuplicationFreeListenable()
        self.device_id.add_on_value_changed_listener(self.on_device_id_changed_listener)
        self.billboard: listen.DuplicationFreeListenable = listen.DuplicationFreeListenable()
        self.mfg_sn: listen.DuplicationFreeListenable = listen.DuplicationFreeListenable('')
        self.mfg_sn.add_on_value_changed_listener(self.on_mfg_sn_changed_listener)
        self.product_variant: listen.DuplicationFreeListenable = listen.DuplicationFreeListenable('')
        self.product_variant.add_on_value_changed_listener(self.on_product_variant_changed_listener)

    def on_device_id_changed_listener(self, device_id: str):
        self.clear_progresses()
        mfg_sn_count: int = 0 if config.get_config().mfg_sn_count is None else config.get_config().mfg_sn_count
        self.startable.set_value(bool(
            sdk.is_valid_device_id(device_id)
            and len(self.mfg_sn.get_value()) == mfg_sn_count
            and len(self.product_variant.get_value())))

    def on_mfg_sn_changed_listener(self, mfg_sn: str):
        self.clear_progresses()
        mfg_sn_count: int = 0 if config.get_config().mfg_sn_count is None else config.get_config().mfg_sn_count
        self.startable.set_value(bool(
            sdk.is_valid_device_id(self.device_id.get_value())
            and len(mfg_sn) == mfg_sn_count
            and len(self.product_variant.get_value())))
        if mfg_sn_count > 0 and self.startable.get_value():
            self.started.set_value(True)

    def on_product_variant_changed_listener(self, product_variant: str):
        self.clear_progresses()
        mfg_sn_count: int = 0 if config.get_config().mfg_sn_count is None else config.get_config().mfg_sn_count
        self.startable.set_value(bool(
            sdk.is_valid_device_id(self.device_id.get_value())
            and len(self.mfg_sn.get_value()) == mfg_sn_count
            and product_variant))

    def on_model_done_listener(self, fa_task_enum: enum.Enum, result: str, error: str):
        self.billboard.set_value("")
        self.progress[fa_task_enum].set_value(error if error else result)

        if fa_task_enum is model.FATask.BUTTON and not error:
            self.tasks_status.set_value(TasksStatus.PROCESSING.value)

        if error or sdk.is_final_enum(fa_task_enum):
            self.started.set_value(False)
            self.tasks_status.set_value(TasksStatus.FAILED.value if error else TasksStatus.PASSED.value)
            report.report(report.Report(
                device_id=self.device_id.get_value(),
                mfg_sn=self.mfg_sn.get_value(),
                operator_id=self.parent.fa_operator_id.get_value(),
                content=TasksStatus.FAILED.name if error else TasksStatus.PASSED.name,
                timestamp=datetime.datetime.now()))

    def on_model_progress_listener(self, fa_task_enum: enum.Enum, progress: str):
        self.progress[fa_task_enum].set_value(progress)
        if fa_task_enum is model.FATask.BUTTON:
            if progress == model.ModelQRunnableState.INTERACT.value:
                self.tasks_status.set_value(FATasksStatus.WAITING_FOR_THE_BUTTON.value)
                self.billboard.set_value(FATasksStatus.WAITING_FOR_THE_BUTTON.value)
            else:
                self.billboard.set_value("")
        else:
            self.billboard.set_value("")

    def on_started_changed_listener(self, started: bool):
        super().on_started_changed_listener(started)
        if started:
            self.clear_progresses()
            self.start_process()

    def start_process(self):
        self.tasks_status.set_value(TasksStatus.PROCESSING.value)
        fa_model: model = model.TaskChainModel(
            model.get_fa_model_qrunnables(
                self.device_id.get_value(),
                config.PRODUCT_VARIANT_SYMBOL[config.ProductVariant(self.product_variant.get_value())]),
            self.on_model_done_listener,
            self.on_model_progress_listener)
        fa_model.start()
