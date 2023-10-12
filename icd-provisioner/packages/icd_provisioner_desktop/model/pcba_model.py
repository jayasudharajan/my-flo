import enum
import logging
import queue
import subprocess
from typing import ClassVar, Dict, List

import icd_provisioner_sdk as sdk
import ipcq

from .. import config
from .model import ModelQRunnable, ModelQRunnableState, ModelTask


class PCBAModelTask(ModelTask):
    def __init__(self, port: str, product_variant: str):
        super().__init__(next(iter(PCBAProgress)))
        self.port: str = port
        self.product_variant: int = product_variant

    def run(self):
        self.notify_progress(ModelQRunnableState.STARTED.value)

        qmc: ipcq.QueueManagerServer
        with ipcq.QueueManagerServer(authkey=ipcq.AuthKey.DEFAULT) as qms:
            try:
                prod_var = self.product_variant
                logging.getLogger(__package__).info(f"Product Variant is {prod_var}")
                if prod_var == config.PRODUCT_VARIANT_SYMBOL[config.ProductVariant.US_075_02] \
                   or prod_var == config.PRODUCT_VARIANT_SYMBOL[config.ProductVariant.US_100_02] \
                   or prod_var == config.PRODUCT_VARIANT_SYMBOL[config.ProductVariant.US_125_02] \
                   or prod_var == config.PRODUCT_VARIANT_SYMBOL[config.ProductVariant.US_075_04] \
                   or prod_var == config.PRODUCT_VARIANT_SYMBOL[config.ProductVariant.US_100_04] \
                   or prod_var == config.PRODUCT_VARIANT_SYMBOL[config.ProductVariant.US_125_04]:
                    cmds: List[str] = ['icd-provisioner', 'serial', 'run', self.port, 'FACTORY_PCBA_5_2_11', qms.address]
                elif prod_var == config.PRODUCT_VARIANT_SYMBOL[config.ProductVariant.US_075_03] \
                   or prod_var == config.PRODUCT_VARIANT_SYMBOL[config.ProductVariant.US_100_03] \
                   or prod_var == config.PRODUCT_VARIANT_SYMBOL[config.ProductVariant.US_125_03]:
                    cmds: List[str] = ['icd-provisioner', 'serial', 'run', self.port, 'FACTORY_PCBA_5_2_12', qms.address]
                else:
                    raise ValueError(f"Invalid Product Variant (was {prod_var})")
                logging.getLogger(__package__).info(" ".join(cmds))
                proc: subprocess.Popen = subprocess.Popen(cmds)

                while proc.poll() is None or not qms.get_queue().empty():
                    try:
                        procedure: str = qms.get_queue().get(timeout=1)
                        self.task_enum = PROCEDURE_PROGRESS_MAP.get(procedure) or self.task_enum

                        if f'{sdk.DevicePCBAStationProcedure.MAC.value}' in procedure:
                            self.task_enum = PCBAProgress.GET_DEVICE_ID
                        self.notify_progress(procedure)
                    except queue.Empty:
                        continue

                if proc.returncode:
                    raise RuntimeError(f"Return code: {proc.returncode}")

                return ModelQRunnableState.FINISHED.value
            except subprocess.TimeoutExpired as e:
                logging.getLogger(__package__).info(e)
                raise
            except Exception as e:
                logging.getLogger(__package__).exception(e)
                raise


class PCBAProgress(enum.Enum):
    GET_DEVICE_ID: ClassVar[str] = 'GET_DEVICE_ID'
    BUTTON_CLICK: ClassVar[str] = 'BUTTON_CLICK'
    HALL_SENSOR: ClassVar[str] = 'HALL_SENSOR'
    CONFIG_WIFI: ClassVar[str] = 'CONFIG_WIFI'


PROCEDURE_PROGRESS_MAP: Dict[str, enum.Enum] = {
    sdk.DevicePCBAStationProcedure.BOOTING.value: PCBAProgress.GET_DEVICE_ID,
    sdk.DevicePCBAStationProcedure.LOGGING_IN.value: PCBAProgress.GET_DEVICE_ID,
    sdk.DevicePCBAStationProcedure.LOGGED_IN.value: PCBAProgress.GET_DEVICE_ID,
    sdk.DevicePCBAStationProcedure.MAC.value: PCBAProgress.GET_DEVICE_ID,
    sdk.DevicePCBAStationProcedure.DETECTING_BUTTON_CLICK.value: PCBAProgress.BUTTON_CLICK,
    sdk.DevicePCBAStationProcedure.DETECTED_BUTTON_CLICK.value: PCBAProgress.BUTTON_CLICK,
    sdk.DevicePCBAStationProcedure.DETECTING_HALL_EVENT.value: PCBAProgress.HALL_SENSOR,
    sdk.DevicePCBAStationProcedure.DETECTED_HALL_EVENT.value: PCBAProgress.HALL_SENSOR,
    sdk.DevicePCBAStationProcedure.CONFIGURING_WIFI.value: PCBAProgress.CONFIG_WIFI,
    sdk.DevicePCBAStationProcedure.CONFIGURED_WIFI.value: PCBAProgress.CONFIG_WIFI,
    sdk.DevicePCBAStationProcedure.DONE.value: PCBAProgress.CONFIG_WIFI,
}


def get_pcba_model_qrunnable(port: str, product_variant: str) -> ModelQRunnable:
    return ModelQRunnable(PCBAModelTask(port, product_variant))
