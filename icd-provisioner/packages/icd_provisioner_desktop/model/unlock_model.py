import enum
import logging
import subprocess
from typing import ClassVar, List

import icd_provisioner_sdk as sdk

from .model import ModelQRunnable, ModelQRunnableState, ModelTask
from .. import config


class UnlockTask(enum.Enum):
    UNLOCK: ClassVar[str] = 'UNLOCK'


class LookUpModelTask(ModelTask):
    def __init__(self, device_id: str):
        super().__init__(UnlockTask.LOOK_UP)
        self.device_id: str = device_id

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

            return cp.stdout.strip()[cp.stdout.strip().find('=')+1:]
        except subprocess.TimeoutExpired as e:
            logging.getLogger(__package__).info(e)
            raise
        except Exception as e:
            logging.getLogger(__package__).exception(e)
            raise


class UnlockModelTask(ModelTask):
    def __init__(self, device_id: str):
        super().__init__(UnlockTask.UNLOCK)
        self.device_id: str = device_id
        self.timeout = 30

    def run(self):
        self.notify_progress(ModelQRunnableState.STARTED.value)

        try:
            cmds: List[str] = ['icd-provisioner', 'unlock']
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


class UnlockTask(enum.Enum):
    LOOK_UP: ClassVar[str] = 'LOOK_UP'
    UNLOCK: ClassVar[str] = 'UNLOCK'


def get_unlock_model_qrunnables(device_id: str) -> List[ModelQRunnable]:
    qrunnables: List[ModelQRunnable] = [
        ModelQRunnable(LookUpModelTask(device_id)),
        ModelQRunnable(UnlockModelTask(device_id)),
    ]

    return qrunnables
