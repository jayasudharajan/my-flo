from typing import Optional, Type, TypeVar

import icd_provisioner_sdk as sdk

T: Type = TypeVar('T')


class DuplicationFreeListenable(sdk.Listenable):
    def set_value(self, value: Optional[T]) -> bool:
        if value == self._value:
            return False
        self._value = value
        self.notify(self._value)
        return True
