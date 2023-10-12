import argparse
import dataclasses
import enum
import importlib.resources
import logging
import os
from typing import Any, ClassVar, Dict, IO, List, Optional

import dacite
import icd_provisioner_sdk as sdk
import toml
import xdg

from .. import report

CONFIG_VERSION: int = 12


def get_default_config_path() -> str:
    config_folder: str = os.path.join(
        os.environ['APPDATA'] if os.name == 'nt' else xdg.XDG_CONFIG_HOME, 'Flo', 'icd-provisioner-desktop')
    if not os.path.exists(config_folder):
        os.makedirs(config_folder)
    return os.path.join(config_folder, 'config.toml')


class Argument(metaclass=sdk.Singleton):
    def __init__(self):
        parser: argparse.ArgumentParser = \
            argparse.ArgumentParser(description='icd-provisioner desktop')

        parser.add_argument(
            '-c', '--config',
            default=get_default_config_path(),
            help='Path to the config.toml')

        args: argparse.Namespace = parser.parse_args()

        self.config: str = args.config


class ProductVariant(enum.Enum):
    US_075_02: ClassVar[str] = 'US 0.75″ - 02'
    US_100_02: ClassVar[str] = 'US 1.00″ - 02'
    US_125_02: ClassVar[str] = 'US 1.25" - 02'
    US_075_03: ClassVar[str] = 'US 0.75″ - 03'
    US_100_03: ClassVar[str] = 'US 1.00″ - 03'
    US_125_03: ClassVar[str] = 'US 1.25″ - 03'
    US_075_04: ClassVar[str] = 'US 0.75″ - 04'
    US_100_04: ClassVar[str] = 'US 1.00″ - 04'
    US_125_04: ClassVar[str] = 'US 1.25″ - 04'

PRODUCT_VARIANT_SYMBOL: Dict = {
    ProductVariant.US_075_02: 'B',
    ProductVariant.US_100_02: 'G',
    ProductVariant.US_125_02: 'C',
    ProductVariant.US_075_03: 'H',
    ProductVariant.US_100_03: 'J',
    ProductVariant.US_125_03: 'K',
    ProductVariant.US_075_04: 'L',
    ProductVariant.US_100_04: 'M',
    ProductVariant.US_125_04: 'N',
}

@dataclasses.dataclass
class VtechReporterConfig:
    path: str = r'C:\temp\temp.txt'


@dataclasses.dataclass
class ReporterConfig:
    enabled_reporters: List[str] = dataclasses.field(
        default_factory=lambda: [report.ReporterEnum.BUILTIN.name])
    vtech_reporter: VtechReporterConfig = VtechReporterConfig()


@dataclasses.dataclass
class FAConfig:
    wifi_signal_lower_threshold: float = -50


@dataclasses.dataclass
class RegConfig:
    print: bool = False
    wait_for_printing: bool = False


@dataclasses.dataclass
class CloudConfig:
    proxy: Optional[str] = None
    tier: str = sdk.Tier.PROD.name


@dataclasses.dataclass
class Config:
    name: str = __package__.replace('_', '-')
    data_version: int = CONFIG_VERSION
    active_tab: int = 1
    cloud: CloudConfig = CloudConfig()
    lang: str = 'en_US'
    mfg_sn_count: int = 0
    product_variants: List[str] = dataclasses.field(
        default_factory=lambda: [variant.value for variant in ProductVariant])
    report: ReporterConfig = ReporterConfig()
    fa: FAConfig = FAConfig()
    reg: RegConfig = RegConfig()


def get_config() -> Config:
    global config

    if not config:
        external_config_path: str = Argument().config
        if os.path.exists(external_config_path):
            try:
                external_config: Config = dacite.from_dict(
                    data_class=Config,
                    data=toml.load(external_config_path),
                    config=dacite.Config(strict=True))
                if external_config.data_version == CONFIG_VERSION:
                    config_dict: Dict[str, Any] = dataclasses.asdict(Config())
                    custom_config_dict: Dict[str, Any] = dataclasses.asdict(external_config)
                    sdk.dict_dict_update(config_dict, custom_config_dict)
                    config = dacite.from_dict(
                        data_class=Config,
                        data=config_dict,
                        config=dacite.Config(strict=True))
                    save_config()
            except dacite.DaciteError as e:
                logging.getLogger(__package__).exception(e)

    if not config:
        try:
            config_dict: Dict = toml.loads(importlib.resources.read_text(__package__, 'built-in.toml'))
            config = dacite.from_dict(data_class=Config, data=config_dict)
        except (FileNotFoundError, TypeError) as e:
            logging.getLogger(__package__).exception(e)
            config = Config()
        save_config()

    return config


def save_config():
    if not config:
        raise RuntimeError("Config is not initialized yet")

    config_path: str = Argument().config
    f: IO
    with open(config_path, 'w', encoding='utf-8') as f:
        toml.dump(dataclasses.asdict(config), f)


config: Optional[Config] = None
