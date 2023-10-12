import abc
import enum
import functools
import logging
from typing import Callable, ClassVar, Iterator, List, Optional

from PySide6.QtCore import QRunnable, QThreadPool


class Model(metaclass=abc.ABCMeta):
    @abc.abstractmethod
    def start(self, *args, **kwargs):
        pass

    @abc.abstractmethod
    def stop(self, *args, **kwargs):
        pass


class TaskChainModel(Model):
    def __init__(
            self,
            model_qrunnables: List['ModelQRunnable'],
            on_done_listener: Optional[Callable[[enum.Enum, str, str], type(None)]] = None,
            progress_listener: Optional[Callable[[enum.Enum, str], type(None)]] = None):
        self.model_qrunnables: List[ModelQRunnable] = model_qrunnables
        model_qrunnable: ModelQRunnable
        for model_qrunnable in self.model_qrunnables:
            if on_done_listener:
                model_qrunnable.add_on_done_listener(on_done_listener)
            if progress_listener:
                model_qrunnable.add_progress_listener(progress_listener)

    def chain_model_qrunnables(self):

        def call_next_model_qrunnable_on_success(
                next_model_qrunnable: ModelQRunnable,
                done_model_qrunnable: ModelQRunnable,
                result: str,
                error: str):
            if not error:
                QThreadPool.globalInstance().start(next_model_qrunnable)

        if not self.model_qrunnables:
            return

        next_model_qrunnable_iter: Iterator = iter(self.model_qrunnables)
        next(next_model_qrunnable_iter)
        model_qrunnable: ModelQRunnable
        next_model_qrunnable: ModelQRunnable
        for model_qrunnable, next_model_qrunnable in zip(
                iter(self.model_qrunnables), next_model_qrunnable_iter):
            model_qrunnable.add_on_done_listener(functools.partial(
                call_next_model_qrunnable_on_success, next_model_qrunnable))

    def start(self):
        if not self.model_qrunnables:
            return

        self.chain_model_qrunnables()
        QThreadPool.globalInstance().start(self.model_qrunnables[0])

    def stop(self):
        # TODO: implementation
        pass


class SingleTaskModel(Model):
    def __init__(
            self, model_qrunnable: 'ModelQRunnable',
            on_done_listener: Callable[[enum.Enum, str, str], type(None)],
            progress_listener: Callable[[enum.Enum, str], type(None)]):
        self.model_qrunnable: ModelQRunnable = model_qrunnable
        self.model_qrunnable.add_on_done_listener(on_done_listener)
        self.model_qrunnable.add_progress_listener(progress_listener)

    def start(self):
        QThreadPool.globalInstance().start(self.model_qrunnable)

    def stop(self):
        self.model_qrunnable.stop()


class ModelQRunnable(QRunnable):
    def __init__(self, task: 'ModelTask'):
        super().__init__()
        self.task: ModelTask = task

        self.error: str = ''
        self.progress: str = ''
        self.result: str = ''

        self.on_done_listeners: List[Callable[[enum.Enum, str, str], type(None)]] = list()
        self.progress_listeners: List[Callable[[enum.Enum, str], type(None)]] = list()

        self.task.add_progress_listener(self.task_progress_listener)

    def run(self):
        try:
            self.result = self.task.run()
        except Exception as e:
            logging.getLogger(__package__).info(e)
            self.error = str(e)
        finally:
            done_listener: Callable[[enum.Enum, str, str], type(None)]
            for done_listener in self.on_done_listeners:
                try:
                    done_listener(self.task.task_enum, self.result, self.error)
                except Exception as ee:
                    logging.getLogger(__package__).info(ee)

    def add_on_done_listener(self, listener: Callable[[enum.Enum, str, str], type(None)]):
        self.on_done_listeners.append(listener)

    def add_progress_listener(self, listener: Callable[[enum.Enum, str], type(None)]):
        self.progress_listeners.append(listener)

    def task_progress_listener(self, progress: str):
        self.progress = progress
        progress_listener: Callable[[enum.Enum, str], type(None)]
        for progress_listener in self.progress_listeners:
            try:
                progress_listener(self.task.task_enum, self.progress)
            except Exception as e:
                logging.getLogger(__package__).info(e)

    def stop(self):
        # TODO: implementation
        pass


class ModelQRunnableState(enum.Enum):
    FAILED: ClassVar[str] = 'FAILED'
    FINISHED: ClassVar[str] = 'FINISHED'
    STARTED: ClassVar[str] = 'STARTED'
    TIMEOUT: ClassVar[str] = 'TIMEOUT'
    INTERACT: ClassVar[str] = 'INTERACT'


class ModelTask(metaclass=abc.ABCMeta):
    def __init__(self, task_enum: enum.Enum, timeout: int = 10):
        self.task_enum: enum.Enum = task_enum
        self.timeout: int = timeout
        self.progress_listeners: List[Callable[[str], type(None)]] = list()

    def add_progress_listener(self, progress_listener: Callable[[str], type(None)]):
        self.progress_listeners.append(progress_listener)

    @abc.abstractmethod
    def run(self) -> str:
        raise NotImplementedError

    def notify_progress(self, progress: str):
        progress_listener: Callable[[str], type(None)]
        for progress_listener in self.progress_listeners:
            try:
                progress_listener(progress)
            except Exception as e:
                logging.getLogger(__package__).exception(e)
