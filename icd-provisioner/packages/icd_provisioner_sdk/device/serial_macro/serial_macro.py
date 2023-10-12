import enum
from typing import ClassVar


class DeviceSerialMacro(enum.Enum):
    FACTORY_PCBA_5_2_11: ClassVar[str] = 'factory-pcba-station-5.2.11.tsv'
    FACTORY_PCBA_5_2_12: ClassVar[str] = 'factory-pcba-station-5.2.12.tsv'


class DevicePCBAStationProcedure(enum.Enum):
    BOOTING: ClassVar[str] = 'BOOTING'
    LOGGING_IN: ClassVar[str] = 'LOGGING IN'
    LOGGED_IN: ClassVar[str] = 'LOGGED IN'
    MAC: ClassVar[str] = 'MAC: '
    DETECTING_BUTTON_CLICK: ClassVar[str] = 'DETECTING BUTTON CLICK'
    DETECTED_BUTTON_CLICK: ClassVar[str] = 'DETECTED BUTTON CLICK'
    DETECTING_HALL_EVENT: ClassVar[str] = 'DETECTING HALL EFFECT SENSOR EVENT'
    DETECTED_HALL_EVENT: ClassVar[str] = 'DETECTED HALL EFFECT SENSOR EVENT'
    CONFIGURING_WIFI: ClassVar[str] = 'CONFIGURING WI-FI'
    CONFIGURED_WIFI: ClassVar[str] = 'CONFIGURED WI-FI'
    DONE: ClassVar[str] = 'DONE'
