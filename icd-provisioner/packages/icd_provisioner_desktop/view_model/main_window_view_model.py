import enum
import importlib.resources
import pathlib
from typing import ClassVar, Dict, List, Union

import icd_provisioner_sdk as sdk
from PySide6.QtCore import QTranslator
from PySide6.QtWidgets import QApplication

from .fa_view_model import FAViewModel
from .pcba_view_model import PCBAViewModel
from .reg_view_model import RegViewModel
from .unlock_view_model import UnlockViewModel
from .view_model import ViewModel
from .. import config
from .. import listen
from .. import translation


class Language(enum.Enum):
    en_US: ClassVar[str] = 'English'
    zh_CN: ClassVar[str] = '简体中文'

class MainWindowViewModel(ViewModel, metaclass=sdk.Singleton):
    def __init__(self, application: QApplication,  number_of_children: int):
        super().__init__()
        self.application: QApplication = application
        self.number_of_children: int = number_of_children
        self.version: str = sdk.version()

        self.pcba_view_models: List[PCBAViewModel] = list()
        self.pcba_operator_id: listen.DuplicationFreeListenable = listen.DuplicationFreeListenable()
        self.pcba_available_ports: sdk.Listenable = sdk.Listenable()

        self.fa_view_models: List[FAViewModel] = list()
        self.fa_operator_id: listen.DuplicationFreeListenable = listen.DuplicationFreeListenable()

        self.reg_view_models: List[RegViewModel] = list()
        self.reg_operator_id: listen.DuplicationFreeListenable = listen.DuplicationFreeListenable()
        self.reg_print: listen.DuplicationFreeListenable = listen.DuplicationFreeListenable()
        self.reg_print.add_on_value_changed_listener(self.on_reg_print_changed_listener)
        self.reg_wait_for_printing: listen.DuplicationFreeListenable = listen.DuplicationFreeListenable()
        self.reg_wait_for_printing.add_on_value_changed_listener(self.on_reg_wait_for_printing_changed_listener)

        self.unlock_view_models: List[UnlockViewModel] = list()
        self.unlock_operator_id: listen.DuplicationFreeListenable = listen.DuplicationFreeListenable()

        self.lang: listen.DuplicationFreeListenable = listen.DuplicationFreeListenable()
        self.lang.add_on_value_changed_listener(self.on_lang_changed_listener)
        self.translator: QTranslator = QTranslator()

        self.mfg_sn_count: listen.DuplicationFreeListenable = listen.DuplicationFreeListenable()
        self.mfg_sn_count.add_on_value_changed_listener(self.on_mfg_sn_count_changed_listener)

        self.proxy: listen.DuplicationFreeListenable = listen.DuplicationFreeListenable()
        self.proxy.add_on_value_changed_listener(self.on_proxy_changed_listener)

        i: int
        for i in range(self.number_of_children):
            self.pcba_view_models.append(PCBAViewModel(self))
            self.pcba_available_ports.add_on_value_changed_listener(
                self.pcba_view_models[i].on_available_ports_changed_listener)

            self.fa_view_models.append(FAViewModel(self))
            self.reg_view_models.append(RegViewModel(self))
            self.unlock_view_models.append(UnlockViewModel(self))

    def on_lang_changed_listener(self, lang: str):
        config.get_config().lang = Language(lang).name
        config.save_config()
        self.application.removeTranslator(self.translator)
        self.lang.set_value(lang)
        translation_file: pathlib.Path
        with importlib.resources.path(
                translation.__package__, f'{Language(self.lang.get_value()).name}.qm') as translation_file:
            self.translator.load(str(translation_file))
            self.application.installTranslator(self.translator)

    @classmethod
    def on_mfg_sn_count_changed_listener(cls, mfg_sn_count: Union[int, str]):
        if isinstance(mfg_sn_count, str):
            try:
                mfg_sn_count = int(mfg_sn_count)
            except ValueError:
                mfg_sn_count = 0
        config.get_config().mfg_sn_count = mfg_sn_count
        config.save_config()

    @classmethod
    def on_proxy_changed_listener(cls, proxy: str):
        config.get_config().cloud.proxy = proxy
        config.save_config()

    @classmethod
    def on_reg_print_changed_listener(cls, state: int):
        config.get_config().reg.print = state > 0
        config.save_config()

    @classmethod
    def on_reg_wait_for_printing_changed_listener(cls, state: int):
        config.get_config().reg.wait_for_printing = state > 0
        config.save_config()

    def translate(self, string: str) -> str:
        return self.application.translate('mainWindow', string)

    def update_ports(self):
        selected_ports: Dict[str, 'PCBAViewModel'] = \
            {self.pcba_view_models[i].port.get_value(): self.pcba_view_models[i]
             for i in range(self.number_of_children)}
        port: str
        self.pcba_available_ports.set_value(
            {port: selected_ports.get(port) for port in sdk.get_available_ports()})
