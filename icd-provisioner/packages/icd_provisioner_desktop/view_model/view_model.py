import enum
from typing import ClassVar, Dict, Optional, Type, TypeVar

import icd_provisioner_sdk as sdk

from .. import listen

VM: Type = TypeVar('T', bound='ViewModel')


class ViewModel:
    def __init__(self, parent: Optional[VM] = None):
        self.parent: Optional[VM] = parent


class TaskViewModel(ViewModel):
    def __init__(self, parent: Optional[VM]):
        super().__init__(parent)

        self.tasks_status: sdk.Listenable = sdk.Listenable()
        self.progress: Dict[enum.Enum, sdk.Listenable] = dict()

    def clear_progresses(self):
        listenable: sdk.Listenable
        for listenable in self.progress.values():
            listenable.set_value("")


class StartableViewModel(TaskViewModel):
    def __init__(self, started: bool, parent: Optional[VM]):
        super().__init__(parent)
        self.startable: listen.DuplicationFreeListenable = listen.DuplicationFreeListenable(not started)

        self.started: listen.DuplicationFreeListenable = listen.DuplicationFreeListenable(started)
        self.started.add_on_value_changed_listener(self.on_started_changed_listener)

    def on_started_changed_listener(self, started: bool):
        self.startable.set_value(not started)


class StoppableViewModel(StartableViewModel):
    def __init__(self, started: bool, stopped: bool, parent: Optional[VM]):
        super().__init__(started, parent)
        self.stoppable: listen.DuplicationFreeListenable = listen.DuplicationFreeListenable(not stopped)

    def on_started_changed_listener(self, started: bool):
        super().on_started_changed_listener(started)
        self.stoppable.set_value(started)


class TasksStatus(enum.Enum):
    FAILED: ClassVar[str] = '<font color="red">FAILED</font>'
    PASSED: ClassVar[str] = '<font color="green">PASSED</font>'
    PROCESSING: ClassVar[str] = 'PROCESSING'
