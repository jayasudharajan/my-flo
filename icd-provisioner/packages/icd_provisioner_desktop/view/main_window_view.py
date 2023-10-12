import enum
import functools
from typing import Callable, Optional, List

import icd_provisioner_sdk as sdk
from PySide6.QtCore import Qt, QFile
from PySide6.QtUiTools import QUiLoader
from PySide6.QtWidgets import \
    QCheckBox, \
    QComboBox, \
    QLabel, \
    QLineEdit, \
    QMainWindow, \
    QPushButton, \
    QTabWidget, \
    QTableWidget

from .qpopup_hookable_combo_box import QPopupHookableComboBox
from .qselect_all_on_focus_line_edit import QSelectAllOnFocusLineEdit
from .qno_scroll_combo_box import QNoScrollComboBox
from .view import View
from .. import config
from .. import listen
from .. import view_model


def make_pcba_combo_box_show_popup_listener(pcba_vm: view_model.PCBAViewModel) \
        -> Callable[[QPopupHookableComboBox], type(None)]:
    def listener(combo_box: QPopupHookableComboBox):
        pcba_vm.parent.update_ports()
        combo_box.clear()
        combo_box.addItems(pcba_vm.ports.get_value())
    return listener


class MainWindowView(View):
    def __init__(self, number_of_children: int):
        super().__init__()

        self.number_of_children: int = number_of_children
        self.main_window: Optional[QMainWindow] = None
        self.main_window_view_model: Optional[view_model.MainWindowViewModel] = None

        self.tab_widget: Optional[QTabWidget] = None

        self.lang_combo_box: Optional[QComboBox] = None
        self.mfg_sn_count_line_edit: Optional[QLineEdit] = None
        self.proxy_line_edit: Optional[QLineEdit] = None

        self.pcba_combo_boxes: List[QPopupHookableComboBox] = list()
        self.pcba_pv_combo_boxes: List[QNoScrollComboBox] = list()
        self.pcba_device_id_line_edits: List[QLineEdit] = list()
        self.pcba_info_labels: List[QLabel] = list()
        self.pcba_info_str_signal_wrappers: List[sdk.StrSignalWrapper] = list()
        self.pcba_mfg_sn_line_edits: List[QLineEdit] = list()
        self.pcba_operator_id_line_edit: Optional[QLineEdit] = None
        self.pcba_start_push_buttons: List[QPushButton] = list()
        self.pcba_status_labels: List[QLabel] = list()
        self.pcba_table_widgets: List[QTableWidget] = list()
        self.pcba_task_status_str_signal_wrappers: List[sdk.StrSignalWrapper] = list()

        self.fa_combo_boxes: List[QNoScrollComboBox] = list()
        self.fa_device_id_line_edits: List[QLineEdit] = list()
        self.fa_info_labels: List[QLabel] = list()
        self.fa_info_str_signal_wrappers: List[sdk.StrSignalWrapper] = list()
        self.fa_mfg_sn_line_edits: List[QLineEdit] = list()
        self.fa_operator_id_line_edit: Optional[QLineEdit] = None
        self.fa_start_push_buttons: List[QPushButton] = list()
        self.fa_status_labels: List[QLabel] = list()
        self.fa_table_widgets: List[QTableWidget] = list()
        self.fa_task_status_str_signal_wrappers: List[sdk.StrSignalWrapper] = list()

        self.reg_pv_combo_boxes: List[QNoScrollComboBox] = list()
        self.reg_device_id_line_edits: List[QLineEdit] = list()
        self.reg_mfg_sn_line_edits: List[QLineEdit] = list()
        self.reg_operator_id_line_edit: Optional[QLineEdit] = None
        self.reg_start_push_buttons: List[QPushButton] = list()
        self.reg_status_labels: List[QLabel] = list()
        self.reg_print_check_box: Optional[QCheckBox] = None
        self.reg_table_widgets: List[QTableWidget] = list()
        self.reg_task_status_str_signal_wrappers: List[sdk.StrSignalWrapper] = list()
        self.reg_wait_for_printing_check_box: Optional[QCheckBox] = None

        self.unlock_device_id_line_edits: List[QLineEdit] = list()
        self.unlock_mfg_sn_line_edits: List[QLineEdit] = list()
        self.unlock_operator_id_line_edit: Optional[QLineEdit] = None
        self.unlock_start_push_buttons: List[QPushButton] = list()
        self.unlock_status_labels: List[QLabel] = list()
        self.unlock_table_widgets: List[QTableWidget] = list()
        self.unlock_task_status_str_signal_wrappers: List[sdk.StrSignalWrapper] = list()

    def on_active_tab_changed_listener(self, tab_index: int):
        config.get_config().active_tab = tab_index
        config.save_config()

    def on_prod_var_1_changed_listener(self, prod_var: str):
        pane_no = 0
        # self.main_window_view_model.prod_var_1.set_value(prod_var)
        self.main_window_view_model.fa_view_models[pane_no].product_variant.set_value(prod_var)
        self.main_window_view_model.pcba_view_models[pane_no].product_variant.set_value(prod_var)
        self.main_window_view_model.reg_view_models[pane_no].product_variant.set_value(prod_var)
        self.fa_combo_boxes[pane_no].setCurrentText(prod_var)
        self.pcba_pv_combo_boxes[pane_no].setCurrentText(prod_var)
        self.reg_pv_combo_boxes[pane_no].setCurrentText(prod_var)

    def on_prod_var_2_changed_listener(self, prod_var: str):
        pane_no = 1
        # self.main_window_view_model.prod_var_2.set_value(prod_var)
        self.main_window_view_model.fa_view_models[pane_no].product_variant.set_value(prod_var)
        self.main_window_view_model.pcba_view_models[pane_no].product_variant.set_value(prod_var)
        self.main_window_view_model.reg_view_models[pane_no].product_variant.set_value(prod_var)
        self.fa_combo_boxes[pane_no].setCurrentText(prod_var)
        self.pcba_pv_combo_boxes[pane_no].setCurrentText(prod_var)
        self.reg_pv_combo_boxes[pane_no].setCurrentText(prod_var)

    def on_lang_changed_listener(self, lang: str):
        self.main_window_view_model.lang.set_value(lang)

        for i in range(self.number_of_children):
            self.pcba_start_push_buttons[i].setText(
                self.main_window_view_model.translate('Start'))
            self.fa_start_push_buttons[i].setText(
                self.main_window_view_model.translate('Start'))
            self.reg_start_push_buttons[i].setText(
                self.main_window_view_model.translate('Start'))
            self.unlock_start_push_buttons[i].setText(
                self.main_window_view_model.translate('Unlock'))

    def on_fa_device_id_changed_listener(self, pane_no: int, device_id: str):
        self.main_window_view_model.fa_view_models[pane_no].device_id.set_value(device_id)
        mfg_sn_count: int = 0 if config.get_config().mfg_sn_count is None else config.get_config().mfg_sn_count
        if mfg_sn_count > 0 and sdk.is_valid_device_id(device_id):
            self.fa_mfg_sn_line_edits[pane_no].setFocus()
            self.fa_mfg_sn_line_edits[pane_no].selectAll()

    def on_fa_started_changed_listener(self, pane_no: int, started: bool):
        self.fa_device_id_line_edits[pane_no].setEnabled(not started)
        self.fa_mfg_sn_line_edits[pane_no].setEnabled(not started)
        if not started:
            self.fa_device_id_line_edits[pane_no].setFocus()
            self.fa_device_id_line_edits[pane_no].selectAll()

    def on_fa_info_changed_listener(self, pane_no: int, info: str):
        self.fa_info_labels[pane_no].setText(info)
        self.fa_info_labels[pane_no].setVisible(bool(info))

    def on_pcba_info_changed_listener(self, pane_no: int, info: str):
        self.pcba_info_labels[pane_no].setText(info)
        self.pcba_info_labels[pane_no].setVisible(bool(info))

    def on_reg_device_id_changed_listener(self, pane_no: int, device_id: str):
        self.main_window_view_model.reg_view_models[pane_no].device_id.set_value(device_id)
        mfg_sn_count: int = 0 if config.get_config().mfg_sn_count is None else config.get_config().mfg_sn_count
        if mfg_sn_count > 0 and sdk.is_valid_device_id(device_id):
            self.reg_mfg_sn_line_edits[pane_no].setFocus()
            self.reg_mfg_sn_line_edits[pane_no].selectAll()

    def on_reg_started_changed_listener(self, pane_no: int, started: bool):
        self.reg_device_id_line_edits[pane_no].setEnabled(not started)
        self.reg_mfg_sn_line_edits[pane_no].setEnabled(not started)
        if not started:
            self.reg_device_id_line_edits[pane_no].setFocus()
            self.reg_device_id_line_edits[pane_no].selectAll()

    def on_unlock_device_id_changed_listener(self, pane_no: int, device_id: str):
        self.main_window_view_model.unlock_view_models[pane_no].device_id.set_value(device_id)
        mfg_sn_count: int = 0 if config.get_config().mfg_sn_count is None else config.get_config().mfg_sn_count
        if mfg_sn_count > 0 and sdk.is_valid_device_id(device_id):
            self.unlock_mfg_sn_line_edits[pane_no].setFocus()
            self.unlock_mfg_sn_line_edits[pane_no].selectAll()

    def on_unlock_started_changed_listener(self, pane_no: int, started: bool):
        self.unlock_device_id_line_edits[pane_no].setEnabled(not started)
        self.unlock_mfg_sn_line_edits[pane_no].setEnabled(not started)
        if not started:
            self.unlock_device_id_line_edits[pane_no].setFocus()
            self.unlock_device_id_line_edits[pane_no].selectAll()

    def bind(self, main_window_view_model: view_model.MainWindowViewModel) -> 'MainWindowView':
        self.main_window_view_model = main_window_view_model
        self.main_window.setWindowTitle(f'{self.main_window.windowTitle()} {self.main_window_view_model.version}')

        self.tab_widget = getattr(self.main_window, 'tabWidget')
        self.tab_widget.setCurrentIndex(config.get_config().active_tab)
        self.tab_widget.currentChanged.connect(self.on_active_tab_changed_listener)

        # Reg {{{
        self.reg_print_check_box = getattr(self.main_window, 'regPrintCheckBox')
        self.reg_print_check_box.stateChanged.connect(self.main_window_view_model.reg_print.set_value)
        self.reg_print_check_box.setChecked(2 if config.get_config().reg.print else 0)

        self.reg_wait_for_printing_check_box = getattr(self.main_window, 'regWaitForPrintingCheckBox')
        self.reg_wait_for_printing_check_box.stateChanged.connect(
            self.main_window_view_model.reg_wait_for_printing.set_value)
        self.reg_wait_for_printing_check_box.setChecked(2 if config.get_config().reg.wait_for_printing else 0)
        # }}} Reg

        self.mfg_sn_count_line_edit = getattr(self.main_window, 'mfgSNCountLineEdit')
        self.mfg_sn_count_line_edit.textChanged.connect(self.main_window_view_model.mfg_sn_count.set_value)
        mfg_sn_count: Optional[int] = config.get_config().mfg_sn_count
        if mfg_sn_count is not None:
            self.mfg_sn_count_line_edit.setText(str(mfg_sn_count))

        self.proxy_line_edit = getattr(self.main_window, 'proxyLineEdit')
        self.proxy_line_edit.textChanged.connect(self.main_window_view_model.proxy.set_value)
        proxy: Optional[str] = config.get_config().cloud.proxy
        if proxy:
            self.proxy_line_edit.setText(proxy)

        for i in range(self.number_of_children):
            # PRODUCT VARIANT COMBO BOX {{{
            self.pcba_pv_combo_boxes.append(getattr(self.main_window, f'pcbaPVComboBox{i + 1}'))
            self.pcba_pv_combo_boxes[i].addItems([''] + [variant for variant in config.get_config().product_variants])

            self.fa_combo_boxes.append(getattr(self.main_window, f'faPVComboBox{i + 1}'))
            self.fa_combo_boxes[i].addItems([''] + [variant for variant in config.get_config().product_variants])

            self.reg_pv_combo_boxes.append(getattr(self.main_window, f'regPVComboBox{i + 1}'))
            self.reg_pv_combo_boxes[i].addItems([''] + [variant for variant in config.get_config().product_variants])

            self.fa_combo_boxes[i].currentTextChanged.connect(getattr(self, f'on_prod_var_{i+1}_changed_listener'))
            self.pcba_pv_combo_boxes[i].currentTextChanged.connect(getattr(self, f'on_prod_var_{i+1}_changed_listener'))
            self.reg_pv_combo_boxes[i].currentTextChanged.connect(getattr(self, f'on_prod_var_{i+1}_changed_listener'))
            # }}}
            # PCBA {{{
            self.pcba_device_id_line_edits.append(getattr(self.main_window, f'pcbaDeviceIDLineEdit{i + 1}'))
            self.main_window_view_model.pcba_view_models[i].device_id.add_on_value_changed_listener(
                self.pcba_device_id_line_edits[i].setText)

            self.pcba_info_str_signal_wrappers.append(sdk.StrSignalWrapper())
            self.pcba_info_str_signal_wrappers[i].signal.connect(
                functools.partial(self.on_pcba_info_changed_listener, i))
            self.pcba_info_labels.append(getattr(self.main_window, f'pcbaInfoLabel{i + 1}'))
            self.pcba_info_labels[i].setStyleSheet("background-color: rgba(255, 255, 255, 200);")
            self.pcba_info_labels[i].setVisible(False)
            self.main_window_view_model.pcba_view_models[i].billboard.add_on_value_changed_listener(
                self.pcba_info_str_signal_wrappers[i].signal.emit)

            self.pcba_mfg_sn_line_edits.append(getattr(self.main_window, f'pcbaMfgSNLineEdit{i + 1}'))
            self.pcba_mfg_sn_line_edits[i].textChanged.connect(
                self.main_window_view_model.pcba_view_models[i].mfg_sn.set_value)
            self.main_window_view_model.pcba_view_models[i].mfg_sn.add_on_value_changed_listener(
                self.pcba_mfg_sn_line_edits[i].setText)

            self.pcba_combo_boxes.append(getattr(self.main_window, f'pcbaComboBox{i + 1}'))
            self.pcba_combo_boxes[i].currentTextChanged.connect(
                self.main_window_view_model.pcba_view_models[i].port.set_value)
            self.pcba_combo_boxes[i].add_on_show_popup_listener(
                make_pcba_combo_box_show_popup_listener(self.main_window_view_model.pcba_view_models[i]))

            self.pcba_operator_id_line_edit = getattr(self.main_window, 'pcbaOperatorIDLineEdit')
            self.pcba_operator_id_line_edit.textChanged.connect(
                self.main_window_view_model.pcba_operator_id.set_value)

            self.main_window_view_model.pcba_view_models[i].started.add_on_value_changed_listener(
                listen.make_optional_bool_listener_to_listeners_tunnel(
                    [], [self.pcba_combo_boxes[i].setEnabled, self.pcba_mfg_sn_line_edits[i].setEnabled]))

            self.pcba_start_push_buttons.append(getattr(self.main_window, f'pcbaStartPushButton{i + 1}'))
            self.pcba_start_push_buttons[i].clicked.connect(
                listen.make_optional_bool_listener_to_listeners_tunnel(
                    [self.main_window_view_model.pcba_view_models[i].started.set_value], []))
            self.main_window_view_model.pcba_view_models[i].startable.add_on_value_changed_listener(
                listen.make_optional_bool_listener_to_listeners_tunnel(
                    [self.pcba_start_push_buttons[i].setEnabled], []))

            self.pcba_status_labels.append(getattr(self.main_window, f'pcbaStatusLabel{i + 1}'))
            self.pcba_task_status_str_signal_wrappers.append(sdk.StrSignalWrapper())
            self.pcba_task_status_str_signal_wrappers[i].signal.connect(self.pcba_status_labels[i].setText)
            self.main_window_view_model.pcba_view_models[i].tasks_status.add_on_value_changed_listener(
                self.pcba_task_status_str_signal_wrappers[i].signal.emit)

            self.pcba_table_widgets.append(getattr(self.main_window, f'pcbaTableWidget{i + 1}'))
            progress_enum: enum.Enum
            for progress_enum in view_model.PCBAProgress:
                self.main_window_view_model.pcba_view_models[i].progress[progress_enum] = sdk.Listenable()
                self.main_window_view_model.pcba_view_models[i].progress[progress_enum].add_on_value_changed_listener(
                    self.pcba_table_widgets[i].item(sdk.get_enum_index(progress_enum), 1).setText)
            # }}} PCBA

            # FA {{{
            self.fa_device_id_line_edits.append(getattr(self.main_window, f'faDeviceIDLineEdit{i + 1}'))
            self.fa_device_id_line_edits[i].textChanged.connect(
                functools.partial(self.on_fa_device_id_changed_listener, i))
            self.main_window_view_model.fa_view_models[i].device_id.add_on_value_changed_listener(
                self.fa_device_id_line_edits[i].setText)

            self.fa_info_str_signal_wrappers.append(sdk.StrSignalWrapper())
            self.fa_info_str_signal_wrappers[i].signal.connect(
                functools.partial(self.on_fa_info_changed_listener, i))
            self.fa_info_labels.append(getattr(self.main_window, f'faInfoLabel{i + 1}'))
            self.fa_info_labels[i].setStyleSheet("background-color: rgba(255, 255, 255, 200);")
            self.fa_info_labels[i].setVisible(False)
            self.main_window_view_model.fa_view_models[i].billboard.add_on_value_changed_listener(
                self.fa_info_str_signal_wrappers[i].signal.emit)

            self.fa_mfg_sn_line_edits.append(getattr(self.main_window, f'faMfgSNLineEdit{i + 1}'))
            self.fa_mfg_sn_line_edits[i].textChanged.connect(
                self.main_window_view_model.fa_view_models[i].mfg_sn.set_value)
            self.main_window_view_model.fa_view_models[i].mfg_sn.add_on_value_changed_listener(
                self.fa_mfg_sn_line_edits[i].setText)

            self.fa_operator_id_line_edit = getattr(self.main_window, 'faOperatorIDLineEdit')
            self.fa_operator_id_line_edit.textChanged.connect(
                self.main_window_view_model.fa_operator_id.set_value)

            self.main_window_view_model.fa_view_models[i].started.add_on_value_changed_listener(
                functools.partial(self.on_fa_started_changed_listener, i))

            self.fa_status_labels.append(getattr(self.main_window, f'faStatusLabel{i + 1}'))
            self.fa_task_status_str_signal_wrappers.append(sdk.StrSignalWrapper())
            self.fa_task_status_str_signal_wrappers[i].signal.connect(self.fa_status_labels[i].setText)
            self.main_window_view_model.fa_view_models[i].tasks_status.add_on_value_changed_listener(
                self.fa_task_status_str_signal_wrappers[i].signal.emit)

            self.fa_start_push_buttons.append(getattr(self.main_window, f'faStartPushButton{i + 1}'))
            self.fa_start_push_buttons[i].clicked.connect(
                listen.make_optional_bool_listener_to_listeners_tunnel(
                    [self.main_window_view_model.fa_view_models[i].started.set_value], []))
            self.main_window_view_model.fa_view_models[i].startable.add_on_value_changed_listener(
                listen.make_optional_bool_listener_to_listeners_tunnel(
                    [self.fa_start_push_buttons[i].setEnabled], []))

            self.fa_table_widgets.append(getattr(self.main_window, f'faTableWidget{i + 1}'))
            task_enum: enum.Enum
            for task_enum in view_model.FATask:
                self.main_window_view_model.fa_view_models[i].progress[task_enum] = sdk.Listenable()
                self.main_window_view_model.fa_view_models[i].progress[task_enum].add_on_value_changed_listener(
                    self.fa_table_widgets[i].item(sdk.get_enum_index(task_enum), 1).setText)
            # }}} FA

            # Reg {{{
            self.reg_device_id_line_edits.append(getattr(self.main_window, f'regDeviceIDLineEdit{i + 1}'))
            self.reg_device_id_line_edits[i].textChanged.connect(
                functools.partial(self.on_reg_device_id_changed_listener, i))
            self.main_window_view_model.reg_view_models[i].device_id.add_on_value_changed_listener(
                self.reg_device_id_line_edits[i].setText)

            self.reg_mfg_sn_line_edits.append(getattr(self.main_window, f'regMfgSNLineEdit{i + 1}'))
            self.reg_mfg_sn_line_edits[i].textChanged.connect(
                self.main_window_view_model.reg_view_models[i].mfg_sn.set_value)
            self.main_window_view_model.reg_view_models[i].mfg_sn.add_on_value_changed_listener(
                self.reg_mfg_sn_line_edits[i].setText)

            self.main_window_view_model.reg_view_models[i].started.add_on_value_changed_listener(
                functools.partial(self.on_reg_started_changed_listener, i))

            self.reg_operator_id_line_edit = getattr(self.main_window, 'regOperatorIDLineEdit')
            self.reg_operator_id_line_edit.textChanged.connect(
                self.main_window_view_model.reg_operator_id.set_value)

            self.reg_start_push_buttons.append(getattr(self.main_window, f'regStartPushButton{i + 1}'))
            self.reg_start_push_buttons[i].clicked.connect(
                listen.make_optional_bool_listener_to_listeners_tunnel(
                    [self.main_window_view_model.reg_view_models[i].started.set_value], []))
            self.main_window_view_model.reg_view_models[i].startable.add_on_value_changed_listener(
                listen.make_optional_bool_listener_to_listeners_tunnel(
                    [self.reg_start_push_buttons[i].setEnabled], []))

            self.reg_status_labels.append(getattr(self.main_window, f'regStatusLabel{i + 1}'))
            self.reg_task_status_str_signal_wrappers.append(sdk.StrSignalWrapper())
            self.reg_task_status_str_signal_wrappers[i].signal.connect(self.reg_status_labels[i].setText)
            self.main_window_view_model.reg_view_models[i].tasks_status.add_on_value_changed_listener(
                self.reg_task_status_str_signal_wrappers[i].signal.emit)

            self.reg_table_widgets.append(getattr(self.main_window, f'regTableWidget{i + 1}'))
            for task_enum in view_model.RegTask:
                self.main_window_view_model.reg_view_models[i].progress[task_enum] = sdk.Listenable()
                self.main_window_view_model.reg_view_models[i].progress[task_enum].add_on_value_changed_listener(
                    self.reg_table_widgets[i].item(sdk.get_enum_index(task_enum), 1).setText)
            # }}} Reg

            # {{{ Unlock
            self.unlock_device_id_line_edits.append(getattr(self.main_window, f'unlockDeviceIDLineEdit{i + 1}'))
            self.unlock_device_id_line_edits[i].textChanged.connect(
                functools.partial(self.on_unlock_device_id_changed_listener, i))
            self.main_window_view_model.unlock_view_models[i].device_id.add_on_value_changed_listener(
                self.unlock_device_id_line_edits[i].setText)

            self.unlock_mfg_sn_line_edits.append(getattr(self.main_window, f'unlockMfgSNLineEdit{i + 1}'))
            self.unlock_mfg_sn_line_edits[i].textChanged.connect(
                self.main_window_view_model.unlock_view_models[i].mfg_sn.set_value)
            self.main_window_view_model.unlock_view_models[i].mfg_sn.add_on_value_changed_listener(
                self.unlock_mfg_sn_line_edits[i].setText)

            self.main_window_view_model.unlock_view_models[i].started.add_on_value_changed_listener(
                functools.partial(self.on_unlock_started_changed_listener, i))

            self.unlock_operator_id_line_edit = getattr(self.main_window, 'unlockOperatorIDLineEdit')
            self.unlock_operator_id_line_edit.textChanged.connect(
                self.main_window_view_model.unlock_operator_id.set_value)

            self.unlock_start_push_buttons.append(getattr(self.main_window, f'unlockStartPushButton{i + 1}'))
            self.unlock_start_push_buttons[i].clicked.connect(
                listen.make_optional_bool_listener_to_listeners_tunnel(
                    [self.main_window_view_model.unlock_view_models[i].started.set_value], []))
            self.main_window_view_model.unlock_view_models[i].startable.add_on_value_changed_listener(
                listen.make_optional_bool_listener_to_listeners_tunnel(
                    [self.unlock_start_push_buttons[i].setEnabled], []))

            self.unlock_status_labels.append(getattr(self.main_window, f'unlockStatusLabel{i + 1}'))
            self.unlock_task_status_str_signal_wrappers.append(sdk.StrSignalWrapper())
            self.unlock_task_status_str_signal_wrappers[i].signal.connect(self.unlock_status_labels[i].setText)
            self.main_window_view_model.unlock_view_models[i].tasks_status.add_on_value_changed_listener(
                self.unlock_task_status_str_signal_wrappers[i].signal.emit)

            self.unlock_table_widgets.append(getattr(self.main_window, f'unlockTableWidget{i + 1}'))
            for task_enum in view_model.UnlockTask:
                self.main_window_view_model.unlock_view_models[i].progress[task_enum] = sdk.Listenable()
                self.main_window_view_model.unlock_view_models[i].progress[task_enum].add_on_value_changed_listener(
                    self.unlock_table_widgets[i].item(sdk.get_enum_index(task_enum), 1).setText)
            # }}}

        self.lang_combo_box = getattr(self.main_window, 'languageComboBox')
        self.lang_combo_box.currentTextChanged.connect(self.on_lang_changed_listener)
        self.lang_combo_box.setCurrentIndex(self.lang_combo_box.findText(
            view_model.Language[config.get_config().lang].value, flags=Qt.MatchExactly))

        return self

    def inflate(self, main_window_ui: str) -> 'MainWindowView':
        main_window_ui_qfile: QFile = QFile(main_window_ui)
        main_window_ui_qfile.open(QFile.ReadOnly)
        qui_loader: QUiLoader = QUiLoader()
        qui_loader.registerCustomWidget(QPopupHookableComboBox)
        qui_loader.registerCustomWidget(QSelectAllOnFocusLineEdit)
        qui_loader.registerCustomWidget(QNoScrollComboBox)
        self.main_window = qui_loader.load(main_window_ui_qfile)
        main_window_ui_qfile.close()
        self.main_window.setFixedSize(self.main_window.size())
        return self

    def show(self) -> 'MainWindowView':
        self.main_window.show()
        return self
