import enum
import json
import logging
import os
import subprocess
import threading
import time
from typing import ClassVar, Dict, IO, List

import icd_provisioner_sdk as sdk
import xdg

from .model import ModelQRunnable, ModelQRunnableState, ModelTask
from .. import config

printer_lock: threading.Lock = threading.Lock()


class LookUpModelTask(ModelTask):
    def __init__(self, device_id: str, product_variant):
        super().__init__(RegTask.LOOK_UP)
        self.device_id: str = device_id
        self.product_variant = product_variant

    def run(self):
        # TODO: auto progress animation
        self.notify_progress(ModelQRunnableState.STARTED.value)

        try:
            cmds: List[str] = ['icd-provisioner', 'look-up', self.device_id]
            logging.getLogger(__package__).info(" ".join(cmds))

            cp: subprocess.CompletedProcess = sdk.subprocess_run_hidden(
                cmds, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True, timeout=self.timeout)
            logging.getLogger(__package__).info(cp.stdout)

            if cp.returncode:
                raise RuntimeError(cp.stdout.splitlines()[-1])

            cmds = ['icd-provisioner', 'ssh']
            if config.get_config().cloud.proxy:
                cmds += ['--proxy', config.get_config().cloud.proxy]
            cmds += ['--tier', config.get_config().cloud.tier, self.device_id, 'cat /etc/mender/artifact_info']
            logging.getLogger(__package__).info(" ".join(cmds))

            cp: subprocess.CompletedProcess = sdk.subprocess_run_hidden(
                cmds, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True, timeout=self.timeout)
            logging.getLogger(__package__).info(cp.stdout)

            if cp.returncode:
                raise RuntimeError(cp.stdout.splitlines()[-1])

            versionStr: str = cp.stdout.strip()[cp.stdout.strip().find('=')+1:]
            
            # Return value error if a -02 unit has firmware not matching 7.0.15
            if (self.product_variant == config.PRODUCT_VARIANT_SYMBOL[config.ProductVariant.US_075_02] \
                or self.product_variant == config.PRODUCT_VARIANT_SYMBOL[config.ProductVariant.US_100_02] \
                or self.product_variant == config.PRODUCT_VARIANT_SYMBOL[config.ProductVariant.US_125_02]) \
                and (versionStr != '7.0.15'):
                raise ValueError(f"Firmware Version for -02 SKU must be 7.0.15 (was {versionStr})")

            # Extract suffix from version string
            version: str = versionStr.split('.')
            suffix = version[2].split('-',1)
            version[2] = suffix[0]
            if len(suffix) > 1:
                suffix = suffix[1]
            else:
                suffix = ''

            # Return value error if a -03 unit has firmware below 7.1.5 or does not contain 'univar'
            if (self.product_variant == config.PRODUCT_VARIANT_SYMBOL[config.ProductVariant.US_075_03] \
                or self.product_variant == config.PRODUCT_VARIANT_SYMBOL[config.ProductVariant.US_100_03] \
                or self.product_variant == config.PRODUCT_VARIANT_SYMBOL[config.ProductVariant.US_125_03]):
                if (int(version[0]) < 7 or (int(version[0]) == 7 and (int(version[1]) < 1 or (int(version[1]) == 1 and int(version[2]) < 5)))):
                    raise ValueError(f"Firmware Version for -03 SKU should not be below 7.1.5 (was {versionStr})")
                if suffix != 'univar':
                    raise ValueError(f"Firmware Version for -03 SKU must contain 'univar' (was {versionStr})")
            elif 'univar' in suffix:
                    raise ValueError(f"'univar' keyword reserved for -03 SKU Firmware Version (selected SKU was {self.product_variant})")

            # Return value error if a -04 unit has firmware below 7.1.5
            if (self.product_variant == config.PRODUCT_VARIANT_SYMBOL[config.ProductVariant.US_075_04] \
                or self.product_variant == config.PRODUCT_VARIANT_SYMBOL[config.ProductVariant.US_100_04] \
                or self.product_variant == config.PRODUCT_VARIANT_SYMBOL[config.ProductVariant.US_125_04]):
                if (int(version[0]) < 7 or (int(version[0]) == 7 and (int(version[1]) < 1 or (int(version[1]) == 1 and int(version[2]) < 5)))):
                    raise ValueError(f"Firmware Version for -04 SKU should not be below 7.1.5 (was {versionStr})")

            return versionStr
        except subprocess.TimeoutExpired as e:
            logging.getLogger(__package__).info(e)
            raise
        except Exception as e:
            logging.getLogger(__package__).exception(e)
            raise


class RegisterModelTask(ModelTask):
    def __init__(self, device_id: str):
        super().__init__(RegTask.REGISTER)
        self.device_id: str = device_id

    def run(self):
        self.notify_progress(ModelQRunnableState.STARTED.value)

        try:
            cmds: List[str] = ['icd-provisioner', 'calibration']
            if config.get_config().cloud.proxy:
                cmds += ['--proxy', config.get_config().cloud.proxy]
            cmds += ['--tier', config.get_config().cloud.tier, self.device_id]
            logging.getLogger(__package__).info(" ".join(cmds))

            sku: str = sdk.subprocess_run_hidden(
                cmds, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True, timeout=self.timeout).stdout.strip()
            logging.getLogger(__package__).info(f"sku: {sku}")

            cmds = ['icd-provisioner', 'register']
            if config.get_config().cloud.proxy:
                cmds += ['--proxy', config.get_config().cloud.proxy]
            cmds += ['--sku', sku, '--tier', config.get_config().cloud.tier, self.device_id]
            logging.getLogger(__package__).info(" ".join(cmds))

            cp: subprocess.CompletedProcess = sdk.subprocess_run_hidden(
                cmds, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True, timeout=self.timeout)
            logging.getLogger(__package__).info(cp.stdout)

            if cp.returncode:
                raise RuntimeError(cp.stdout.splitlines()[-1])

            return ModelQRunnableState.FINISHED.value
        except subprocess.TimeoutExpired as e:
            logging.getLogger(__package__).info(e)
            raise
        except Exception as e:
            logging.getLogger(__package__).exception(e)
            raise


class LockModelTask(ModelTask):
    def __init__(self, device_id: str):
        super().__init__(RegTask.LOCK)
        self.device_id: str = device_id
        self.timeout = 30

    def run(self):
        self.notify_progress(ModelQRunnableState.STARTED.value)

        try:
            cmds: List[str] = ['icd-provisioner', 'lock']
            if config.get_config().cloud.proxy:
                cmds += ['--proxy', config.get_config().cloud.proxy]
            cmds += ['--tier', config.get_config().cloud.tier, self.device_id]
            logging.getLogger(__package__).info(" ".join(cmds))

            cp: subprocess.CompletedProcess = sdk.subprocess_run_hidden(
                cmds, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True, timeout=self.timeout)
            logging.getLogger(__package__).info(cp.stdout)

            if cp.returncode:
                raise RuntimeError(cp.stdout.splitlines()[-1])

            return ModelQRunnableState.FINISHED.value
        except subprocess.TimeoutExpired as e:
            logging.getLogger(__package__).info(e)
            raise
        except Exception as e:
            logging.getLogger(__package__).exception(e)
            raise


class ModeModelTask(ModelTask):
    def __init__(self, device_id: str):
        super().__init__(RegTask.MODE)
        self.device_id: str = device_id
        self.timeout = 30

    def run(self):
        self.notify_progress(ModelQRunnableState.STARTED.value)

        try:
            cmds: List[str] = ['icd-provisioner', 'mode']
            if config.get_config().cloud.proxy:
                cmds += ['--proxy', config.get_config().cloud.proxy]
            cmds += ['--tier', config.get_config().cloud.tier, self.device_id]
            logging.getLogger(__package__).info(" ".join(cmds))

            cp: subprocess.CompletedProcess = sdk.subprocess_run_hidden(
                cmds, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True, timeout=self.timeout)
            logging.getLogger(__package__).info(cp.stdout)

            if cp.returncode:
                raise RuntimeError(cp.stdout.splitlines()[-1])

            if sdk.Mode.BUILDER.name != cp.stdout.strip():
                raise RuntimeError("Not on BUILDER mode")

            return ModelQRunnableState.FINISHED.value
        except subprocess.TimeoutExpired as e:
            logging.getLogger(__package__).info(e)
            raise
        except Exception as e:
            logging.getLogger(__package__).exception(e)
            raise


class PrintQRCodeModelTask(ModelTask):
    def __init__(self, device_id: str, wait_for_printing: bool):
        super().__init__(RegTask.PRINT_QR_CODE)
        self.device_id: str = device_id
        self.wait_for_printing: bool = wait_for_printing
        self.label_dir: str = os.path.join(
            os.environ['LOCALAPPDATA'] if os.name == 'nt' else xdg.XDG_DATA_HOME,
            'Flo', 'icd-provisioner', 'Labels')
        if not os.path.exists(self.label_dir):
            os.makedirs(self.label_dir)

    def run(self):
        self.notify_progress(ModelQRunnableState.STARTED.value)

        try:
            cmds: List[str] = ['icd-provisioner', 'qr-code', '--decode']
            if config.get_config().cloud.proxy:
                cmds += ['--proxy', config.get_config().cloud.proxy]
            cmds += ['--tier', config.get_config().cloud.tier, self.device_id]
            logging.getLogger(__package__).info(" ".join(cmds))

            cp: subprocess.CompletedProcess = sdk.subprocess_run_hidden(
                cmds, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True, timeout=self.timeout)
            logging.getLogger(__package__).info(cp.stdout)

            if cp.returncode:
                raise RuntimeError(cp.stdout.splitlines()[-1])

            qr_code: str = cp.stdout.strip()

            cmds = ['icd-provisioner', 'serial-number']
            if config.get_config().cloud.proxy:
                cmds += ['--proxy', config.get_config().cloud.proxy]
            cmds += ['--tier', config.get_config().cloud.tier, 'read-cloud', self.device_id]
            logging.getLogger(__package__).info(" ".join(cmds))

            cp = sdk.subprocess_run_hidden(
                cmds, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True, timeout=self.timeout)
            logging.getLogger(__package__).info(cp.stdout)

            if cp.returncode:
                raise RuntimeError(cp.stdout.splitlines()[-1])

            serial_number: str = json.loads(cp.stdout)['sn']

            target: str = os.path.join(self.label_dir, f'{self.device_id}.json')

            with printer_lock:
                if self.wait_for_printing:
                    fname: str
                    while any(fname.endswith('.json') for fname in os.listdir(self.label_dir)):
                        time.sleep(1)
                        continue
                f: IO[str]
                with open(target, 'w', encoding='utf-8') as f:
                    d: Dict[str, str] = {
                        'device_id': self.device_id,
                        'qr_code_decoded': qr_code,
                        'serial_number': serial_number,
                    }
                    logging.getLogger(__package__).info(d)
                    json.dump(d, f)

            return ModelQRunnableState.FINISHED.value
        except subprocess.TimeoutExpired as e:
            logging.getLogger(__package__).info(e)
            raise
        except Exception as e:
            logging.getLogger(__package__).exception(e)
            raise


class RegTask(enum.Enum):
    LOOK_UP: ClassVar[str] = 'LOOK_UP'
    MODE: ClassVar[str] = 'MODE'
    REGISTER: ClassVar[str] = 'REGISTER'
    LOCK: ClassVar[str] = 'LOCK'
    PRINT_QR_CODE: ClassVar[str] = 'PRINT_QR_CODE'


def get_reg_model_qrunnables(device_id: str, print: bool, wait_for_printing: bool, product_variant: str) -> List[ModelQRunnable]:
    qrunnables: List[ModelQRunnable] = [
        ModelQRunnable(LookUpModelTask(device_id, product_variant)),
        ModelQRunnable(ModeModelTask(device_id)),
        ModelQRunnable(RegisterModelTask(device_id)),
        ModelQRunnable(LockModelTask(device_id)),
    ]

    if print:
        qrunnables.append(ModelQRunnable(PrintQRCodeModelTask(device_id, wait_for_printing)))

    return qrunnables
