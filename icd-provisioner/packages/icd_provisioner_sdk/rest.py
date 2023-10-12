import abc
import dataclasses
from typing import Any, Dict, Final, final, Optional, Type, TypeVar

import aiohttp

T: Type = TypeVar('T', bound='RestClient')
U: Type = TypeVar('U', bound='RestClientConfig')
V: Type = TypeVar('V', bound='RestClientMethod')


class Header:
    Authorization: Final[Dict[str, str]] = {'Authorization': 'Bearer {token}'}
    ContentType_ApplicationJSON: Final[Dict[str, str]] = {'Content-Type': 'Application/JSON'}


class RestClient:
    def __init__(self, session: aiohttp.ClientSession, config: U):
        self.session: Final[aiohttp.ClientSession] = session
        self.config: Final[U] = config

    @final
    def register_method(self, method_class: Type[V]):
        setattr(self, method_class.METHOD_NAME, method_class(self).run)


@dataclasses.dataclass
class RestClientConfig:
    base_url: str = ''
    proxy: Optional[str] = None

    def load(self, info: Dict[str, str]):
        if info.get('base-url'):
            self.base_url = info.get('base-url')
        if info.get('proxy'):
            self.proxy = info.get('proxy')


class RestClientMethod(metaclass=abc.ABCMeta):
    METHOD_NAME: str = '{method_name}'

    def __init__(self, rest_client: T):
        self.client: Final[T] = rest_client

    @abc.abstractmethod
    def run(self, *args, **kwargs) -> Any:
        raise NotImplementedError
