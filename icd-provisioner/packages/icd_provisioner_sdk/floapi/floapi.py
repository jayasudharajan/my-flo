import dataclasses
import enum
import importlib.resources
from typing import ClassVar, Dict, Union

import aiohttp
import toml

from . import config
from . import method
from .. import rest


class Tier(enum.Enum):
    DEV: ClassVar[str] = 'DEV'
    PROD: ClassVar[str] = 'PROD'


@dataclasses.dataclass
class DevAPIClientConfig(rest.RestClientConfig):
    client_id: str = ''
    client_secret: str = ''

    def __post_init__(self):
        self.load(toml.loads(importlib.resources.read_text(config.__package__, 'dev.toml')))

    def load(self, info: Dict[str, str]):
        super().load(info)
        if info.get('client-id'):
            self.client_id = info.get('client-id')
        if info.get('client-secret'):
            self.client_secret = info.get('client-secret')


@dataclasses.dataclass
class ProdAPIClientConfig(rest.RestClientConfig):
    client_id: str = ''
    client_secret: str = ''

    def __post_init__(self):
        self.load(toml.loads(importlib.resources.read_text(config.__package__, 'prod.toml')))

    def load(self, info: Dict[str, str]):
        super().load(info)
        if info.get('client-id'):
            self.client_id = info.get('client-id')
        if info.get('client-secret'):
            self.client_secret = info.get('client-secret')


class Flo(rest.RestClient):
    def __init__(
            self,
            session: aiohttp.ClientSession,
            rest_config: Union[DevAPIClientConfig, ProdAPIClientConfig]):
        super().__init__(session, rest_config)
        self.oauth_token: str = ''

        method_class: rest.RestClientMethod
        for method_class in [
            method.DeleteSerialNumberMethod,
            method.GenerateSerialNumberMethod,
            method.GetSerialNumberMethod,
            method.OAuthMethod,
            method.QRCodeMethod,
            method.RegisterMethod,
            method.RegistryMethod,
        ]:
            self.register_method(method_class)
