import abc
import dataclasses
from typing import Any, AnyStr, AsyncContextManager, Awaitable, Final, final, List, \
    Optional, Set, Tuple, Type, TypeVar, Union

import asyncssh

T: Type = TypeVar('T', bound='SSHClient')
U: Type = TypeVar('U', bound='SSHClientConfig')
V: Type = TypeVar('V', bound='SSHClientMethod')


class SSHClient:
    def __init__(self, config: U, connection: asyncssh.SSHClientConnection = None):
        self.config: U = config
        self.connection: Optional[asyncssh.SSHClientConnection] = connection

    def connect(self, login_timeout: int = 10, **kwargs) \
            -> Union[AsyncContextManager[asyncssh.SSHClientConnection], Awaitable[asyncssh.SSHClientConnection]]:
        return asyncssh.connect(
            self.config.hostname,
            port=self.config.port,
            username=self.config.username,
            client_keys=self.config.keys,
            known_hosts=self.config.known_hosts,
            login_timeout=login_timeout, **kwargs)

    def import_private_key(self, data: AnyStr, passphrase: Optional[AnyStr] = None):
        self.config.keys.add(asyncssh.import_private_key(data, passphrase=passphrase))

    @final
    def register_method(self, method_class: Type[V]):
        setattr(self, method_class.METHOD_NAME, method_class(self).run)

    async def run(
            self,
            command: Optional[str] = None,
            timeout: Optional[Union[float, int]] = 10,
            **kwargs) -> asyncssh.SSHCompletedProcess:
        if self.connection:
            return await self.connection.run(command, timeout=timeout, **kwargs)

        conn: asyncssh.SSHClientConnection
        async with asyncssh.connect(
                self.config.hostname,
                port=self.config.port,
                username=self.config.username,
                client_keys=self.config.keys,
                known_hosts=self.config.known_hosts,
                login_timeout=timeout) as conn:
            return await conn.run(command=command, timeout=timeout, **kwargs)

    async def scp(
            self,
            source: Union['SSHRemotePath', str],
            destination: Union['SSHRemotePath', str],
            login_timeout: Optional[Union[float, int]] = 10,
            recursive: bool = False,
            **kwargs):
        converted_source: Tuple[Union[asyncssh.SSHClientConnection, Tuple[str, str]], str] = tuple()
        converted_destination: Tuple[Union[asyncssh.SSHClientConnection, Tuple[str, str]], str] = tuple()

        if isinstance(source, SSHRemotePath):
            converted_source = (
                self.connection if self.connection else (self.config.hostname, self.config.port),
                source.path if source.path else '.')
        if isinstance(destination, SSHRemotePath):
            converted_destination = (
                self.connection if self.connection else (self.config.hostname, self.config.port),
                destination.path if destination.path else '.')

        return await asyncssh.scp(
            converted_source if converted_source else source,
            converted_destination if converted_destination else destination,
            username=self.config.username,
            client_keys=self.config.keys,
            known_hosts=self.config.known_hosts,
            login_timeout=login_timeout,
            recurse=recursive,
            **kwargs)


class SSHClientMethod(metaclass=abc.ABCMeta):
    METHOD_NAME: str = '{method_name}'

    def __init__(self, ssh_client: T):
        self.client: Final[T] = ssh_client

    @abc.abstractmethod
    def run(self, *args, **kwargs) -> Any:
        raise NotImplementedError


@dataclasses.dataclass
class SSHClientConfig:
    hostname: str
    port: int = 22
    username: str = 'root'
    keys: Set[asyncssh.SSHKey] = dataclasses.field(default_factory=set)
    known_hosts: Optional[List[str]] = None


@dataclasses.dataclass
class SSHRemotePath:
    path: str
