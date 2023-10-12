from typing import List, Optional, Type, TypeVar

from .. import view_model

T: Type = TypeVar('T', bound='View')


class View:
    def __init__(self, parent: Optional[T] = None):
        self.parent: Optional[T] = parent
        self.children: List[View] = list()

    def bind(self, vm: view_model.ViewModel) -> T:
        pass

    def inflate(self, ui_path: str) -> T:
        pass
