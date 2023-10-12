from PySide6.QtCore import QObject, Signal


# Ref: https://stackoverflow.com/questions/36559713/pyside-qtcore-signal-object-has-no-attribute-connect
class StrSignalWrapper(QObject):
    signal = Signal(str)
