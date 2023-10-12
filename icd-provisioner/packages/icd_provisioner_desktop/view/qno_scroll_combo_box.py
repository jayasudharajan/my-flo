from PySide6.QtWidgets import QComboBox
from PySide6.QtGui import QKeyEvent

class QNoScrollComboBox(QComboBox):
    def wheelEvent(self, *args, **kwargs):
        return True
    def keyPressEvent(self, e: QKeyEvent) -> None:
        return True
    