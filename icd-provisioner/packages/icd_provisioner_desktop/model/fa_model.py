import enum
import logging
import subprocess
import time
from typing import ClassVar, List

import icd_provisioner_sdk as sdk

from .model import ModelQRunnable, ModelQRunnableState, ModelTask
from .. import config


class LookUpModelTask(ModelTask):
    def __init__(self, device_id: str, product_variant: str):
        super().__init__(FATask.LOOK_UP)
        self.device_id: str = device_id
        self.product_variant: str = product_variant

    def run(self):
        self.notify_progress(ModelQRunnableState.STARTED.value)

        try:
            cmds: List[str] = ['icd-provisioner', 'look-up', self.device_id]
            logging.getLogger(__package__).info(" ".join(cmds))

            cp: subprocess.CompletedProcess = sdk.subprocess_run_hidden(
                cmds, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True, timeout=self.timeout)
            logging.getLogger(__package__).info(f"result: {cp.stdout}")

            if cp.returncode:
                raise RuntimeError(cp.stdout.splitlines()[-1])

            cmds = ['icd-provisioner', 'ssh', '--no-import-registry', self.device_id, 'cat /etc/mender/artifact_info']
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


class WiFiSignalModelTask(ModelTask):
    def __init__(self, device_id: str):
        super().__init__(FATask.WiFI_SIGNAL)
        self.device_id: str = device_id

    def run(self):
        self.notify_progress(ModelQRunnableState.STARTED.value)

        try:
            cmds: List[str] = ['icd-provisioner', 'wifi', '--no-import-registry', 'rssi', self.device_id]
            logging.getLogger(__package__).info(" ".join(cmds))

            cp: subprocess.CompletedProcess = sdk.subprocess_run_hidden(
                cmds, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True, timeout=self.timeout)
            logging.getLogger(__package__).info(cp.stdout)

            if cp.returncode:
                raise RuntimeError(cp.stdout.splitlines()[-1])

            rssi: float = float(cp.stdout.replace('dBm', ''))
            threshold: float = config.get_config().fa.wifi_signal_lower_threshold
            logging.getLogger(__package__).info(f"rssi: {rssi}, threshold: {threshold}")

            if rssi < threshold:
                raise ValueError(f"Device RSSI {rssi} dBm < threshold {threshold} dBm")

            return ModelQRunnableState.FINISHED.value
        except subprocess.TimeoutExpired as e:
            logging.getLogger(__package__).info(e)
            raise
        except Exception as e:
            logging.getLogger(__package__).exception(e)
            raise


class ButtonModelTask(ModelTask):
    def __init__(self, device_id: str, product_variant: str):
        super().__init__(FATask.BUTTON)
        self.device_id: str = device_id
        self.product_variant: str = product_variant
        self.timeout = 60

    def run(self):
        self.notify_progress(ModelQRunnableState.STARTED.value)

        try:
            cmds: List[str] =\
                ['icd-provisioner', 'listen-button', '--no-import-registry', '--only-copy-script', '--timeout', '60', self.device_id]
            logging.getLogger(__package__).info(" ".join(cmds))
            cp: subprocess.CompletedProcess = sdk.subprocess_run_hidden(
                cmds, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True, timeout=self.timeout)
            logging.getLogger(__package__).info(cp.stdout)
            if cp.returncode:
                raise RuntimeError(cp.stdout.splitlines()[-1])

            cmds = ['icd-provisioner', 'listen-button', '--no-copy-script', '--no-import-registry', '--timeout', '60', self.device_id]
            logging.getLogger(__package__).info(" ".join(cmds))
            p: subprocess.Popen = sdk.subprocess_popen_hidden(
                cmds, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
            time.sleep(10)
            self.notify_progress(ModelQRunnableState.INTERACT.value)
            stdout: str

            if (self.product_variant == config.PRODUCT_VARIANT_SYMBOL[config.ProductVariant.US_075_03] \
                or self.product_variant == config.PRODUCT_VARIANT_SYMBOL[config.ProductVariant.US_100_03] \
                or self.product_variant == config.PRODUCT_VARIANT_SYMBOL[config.ProductVariant.US_125_03]):
                cmds = ['icd-provisioner', 'listen-button', '--bin-command', '--no-import-registry', '--timeout', '60', self.device_id]
                logging.getLogger(__package__).info(" ".join(cmds))
                p: subprocess.Popen = sdk.subprocess_popen_hidden(
                    cmds, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
                time.sleep(10)
                self.notify_progress(ModelQRunnableState.INTERACT.value)
                stdout: str


            try:
                stdout, _ = p.communicate(timeout=self.timeout)
            except subprocess.TimeoutExpired:
                p.kill()
                stdout, _ = p.communicate(timeout=self.timeout)
            logging.getLogger(__package__).info(stdout)
            if p.returncode:
                raise RuntimeError(stdout.splitlines()[-1])

            return ModelQRunnableState.FINISHED.value
        except subprocess.TimeoutExpired as e:
            logging.getLogger(__package__).info(e)
            raise
        except Exception as e:
            logging.getLogger(__package__).exception(e)
            raise


class ValveModelTask(ModelTask):
    def __init__(self, device_id: str):
        super().__init__(FATask.VALVE)
        self.device_id: str = device_id

    def run(self):
        self.notify_progress(ModelQRunnableState.STARTED.value)

        try:
            cmds: List[str] = ['icd-provisioner', 'valve', '--no-import-registry', self.device_id, 'OPEN']
            logging.getLogger(__package__).info(" ".join(cmds))

            cp: subprocess.CompletedProcess = sdk.subprocess_run_hidden(
                cmds, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True, timeout=self.timeout)
            logging.getLogger(__package__).info(cp.stdout)

            if cp.returncode:
                raise RuntimeError(cp.stdout.splitlines()[-1])

            cmds: List[str] = ['icd-provisioner', 'valve', '--no-import-registry', self.device_id, 'CLOSED']
            logging.getLogger(__package__).info(" ".join(cmds))

            cp: subprocess.CompletedProcess = sdk.subprocess_run_hidden(
                cmds, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True, timeout=self.timeout)
            logging.getLogger(__package__).info(cp.stdout)

            if cp.returncode:
                raise RuntimeError(cp.stdout.splitlines()[-1])

            cmds: List[str] = ['icd-provisioner', 'valve', '--no-import-registry', self.device_id, 'OPEN']
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


class SerialNumberModelTask(ModelTask):
    def __init__(self, device_id: str, product_variant: str):
        super().__init__(FATask.SERIAL_NUMBER)
        self.device_id: str = device_id
        self.product_variant: str = product_variant

    def run(self):
        self.notify_progress(ModelQRunnableState.STARTED.value)

        try:
            cmds: List[str] = ['icd-provisioner', 'serial-number']
            if config.get_config().cloud.proxy:
                cmds += ['--proxy', config.get_config().cloud.proxy]
            cmds += [
                '--tier', config.get_config().cloud.tier,
                'generate',
                '--ignore-conflict',
                '--pcba', 'D',
                '--product', self.product_variant,
                '--site', 'D',
                '--sub-assembly', 'A',
                self.device_id,
            ]
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


class FATask(enum.Enum):
    LOOK_UP: ClassVar[str] = 'LOOK_UP'
    WiFI_SIGNAL: ClassVar[str] = 'WIFI_SIGNAL'
    BUTTON: ClassVar[str] = 'BUTTON'
    VALVE: ClassVar[str] = 'VALVE'
    SERIAL_NUMBER: ClassVar[str] = 'SERIAL_NUMBER'


def get_fa_model_qrunnables(device_id: str, product_variant: str) -> List[ModelQRunnable]:
    return [
        ModelQRunnable(LookUpModelTask(device_id, product_variant)),
        ModelQRunnable(WiFiSignalModelTask(device_id)),
        ModelQRunnable(ButtonModelTask(device_id, product_variant)),
        ModelQRunnable(ValveModelTask(device_id)),
        ModelQRunnable(SerialNumberModelTask(device_id, product_variant)),
    ]
