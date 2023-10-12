import abc
import asyncio
import concurrent.futures
import enum
import importlib.metadata
import os
import select
import subprocess
import sys
import threading
from typing import \
    Any, \
    AnyStr, \
    Awaitable, \
    BinaryIO, \
    Callable, \
    Dict, \
    List, \
    Optional, \
    Sequence, \
    Set, \
    TextIO, \
    Type, \
    TypeVar, \
    Union

import serial.tools
import serial.tools.list_ports
import serial.tools.list_ports_common

T: Type = TypeVar('T')


class Listenable:
    def __init__(self, value: Optional[T] = None):
        self._value: Optional[T] = value
        self.on_value_changed_listeners: List[Callable[[Optional[T]], type(None)]] = list()

    def add_on_value_changed_listener(self, listener: Callable[[Optional[T]], type(None)]):
        self.on_value_changed_listeners.append(listener)

    def remove_on_value_changed_listener(self, listener: Callable[[Optional[T]], type(None)]):
        self.on_value_changed_listeners.remove(listener)

    def notify(self, value: Optional[T]):
        listener: Callable[[Optional[T]], type(None)]
        for listener in self.on_value_changed_listeners:
            listener(value)

    def get_value(self) -> Optional[T]:
        return self._value

    def set_value(self, value: Optional[T]) -> bool:
        self._value = value
        self.notify(self._value)
        return True


class ReferenceValuesWrapper:
    def __init__(self, value_dict: Dict[str, Any]):
        name: str
        value: Dict
        for name, value in value_dict.items():
            setattr(self, name, value)


class SingleReferenceValueWrapper:
    def __init__(self, value: Any):
        self.value: Any = value


class Singleton(type):
    _instances: Dict[Type[T], T] = dict()

    def __call__(cls: Type[T], *args, **kwargs) -> T:
        if cls not in cls._instances:
            cls._instances[cls] = super().__call__(*args, **kwargs)
        return cls._instances[cls]


class SingletonABCMeta(abc.ABCMeta):
    _instances: Dict[Type[T], T] = dict()

    def __call__(cls: Type[T], *args, **kwargs) -> T:
        if cls not in cls._instances:
            cls._instances[cls] = super().__call__(*args, **kwargs)
        return cls._instances[cls]


# Workaround for aiohttp ungraceful shutdown on Windows
# Refs: https://github.com/aio-libs/aiohttp/issues/4324
#       https://github.com/Azure/azure-sdk-for-python/issues/9060
def asyncio_run(aw: Awaitable, policy: Optional[asyncio.AbstractEventLoopPolicy] = None) -> Any:
    if policy:
        asyncio.set_event_loop_policy(policy)

    if os.name == 'nt':
        # FIXME: The following 2 lines are a workaround for: https://github.com/aio-libs/aiohttp/issues/3816
        if not policy:
            asyncio.set_event_loop_policy(asyncio.WindowsSelectorEventLoopPolicy())

        if threading.current_thread() is threading.main_thread():
            loop: asyncio.AbstractEventLoop = asyncio.get_event_loop()
        else:
            # asyncio.get_event_loop() cannot automatically create an event loop if needed on Windows
            loop = asyncio.new_event_loop()
            asyncio.set_event_loop(loop)

        res: Any = loop.run_until_complete(aw)

        if not threading.current_thread() is threading.main_thread():
            loop.close()
        return res
    return asyncio.run(aw)


def get_available_ports() -> Set[str]:
    port_info: serial.tools.list_ports_common.ListPortInfo
    return {port_info.device for port_info in serial.tools.list_ports.comports()}


def get_enum_index(enum_item: enum.Enum) -> int:
    res: int = -1
    enum_meta: enum.EnumMeta = type(enum_item)
    i: int
    e: enum.Enum
    for i, e in enumerate(enum_meta):
        if e == enum_item:
            res = i
            break
    return res


def is_final_enum(enum_item: enum.Enum) -> bool:
    enum_meta: enum.EnumMeta = type(enum_item)
    return len(enum_meta) - 1 == get_enum_index(enum_item)


def print_error(e: BaseException):
    print(str_error(e), file=sys.stderr)


def str_error(e: BaseException):
    return f"{type(e).__name__}: {e}"


def subprocess_popen_hidden(*args, **kwargs) -> subprocess.Popen:
    startupinfo: Optional[subprocess.STARTUPINFO()] = kwargs.get('startupinfo') or None
    if os.name == 'nt':
        if not startupinfo:
            startupinfo = subprocess.STARTUPINFO()
        startupinfo.dwFlags |= subprocess.STARTF_USESHOWWINDOW
    return subprocess.Popen(*args, **kwargs, startupinfo=startupinfo)


def subprocess_run_hidden(*args, **kwargs) -> subprocess.CompletedProcess:
    startupinfo: Optional[subprocess.STARTUPINFO()] = kwargs.get('startupinfo') or None
    if os.name == 'nt':
        if not startupinfo:
            startupinfo = subprocess.STARTUPINFO()
        startupinfo.dwFlags |= subprocess.STARTF_USESHOWWINDOW
    return subprocess.run(*args, **kwargs, startupinfo=startupinfo)


def version() -> str:
    return importlib.metadata.version('icd-provisioner')


U: Type = TypeVar('U', bound=Union[BinaryIO, TextIO])
V: Type = TypeVar('V', bound='asyncio.StreamReader')


async def redirect_async_stream_to_streams(
        src_async_stream: V, dest_streams: Sequence[U], stopper: Optional[SingleReferenceValueWrapper] = None):
    c: AnyStr
    stream: U
    while not src_async_stream.at_eof():
        c = await src_async_stream.read(1)
        for stream in dest_streams:
            stream.write(c)
            stream.flush()
        if stopper and stopper.value:
            return
    c = await src_async_stream.read()
    for stream in dest_streams:
        stream.write(c)
        stream.flush()


async def redirect_stream_to_async_streams(
        src_stream: U, dest_async_streams: Sequence[V], stopper: Optional[SingleReferenceValueWrapper] = None):
    def read() -> str:
        while True:
            if select.select([src_stream], [], [], 0.1)[0]:
                return src_stream.read(1)
            if src_stream.closed or (stopper and stopper.value):
                return ''

    stream: U
    pool: concurrent.futures.ThreadPoolExecutor
    with concurrent.futures.ThreadPoolExecutor(max_workers=1) as pool:
        while True:
            c: AnyStr = await asyncio.get_running_loop().run_in_executor(pool, read)
            if not c:
                break
            for stream in dest_async_streams:
                stream.write(c)
                await stream.drain()


def dict_dict_update(orig_dict: Dict, update_dict: Dict):
    k: Any
    v: Any
    for key, value in update_dict.items():
        if isinstance(value, dict):
            dict_dict_update(orig_dict.get(key, dict()), value)
        else:
            orig_dict[key] = value
