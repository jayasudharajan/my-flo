import asyncio
import base64
import concurrent.futures
import dataclasses
import enum
import importlib.resources
import json
import pathlib
from typing import Dict, Generator, List, Optional, Type, Union

import aiohttp
import asyncssh
import toml

from . import attribute
from . import serial_macro
from . import ssh_config
from . import ssh_method
from .util import device_id_look_up, device_id_to_hostname
from .. import floapi
from ..serial import SerialMacroRunner
from ..ssh import SSHClient, SSHClientConfig, SSHClientMethod


class DeviceClient:
    def __init__(self, device_id: str):
        self.attribute: DeviceAttributes = DeviceAttributes(
            device_id=device_id,
            ssh_authorized_keys=toml.loads(importlib.resources.read_text(
                attribute.__package__, 'default.toml'))['ssh-authorized-keys'],
            ws_server_token=toml.loads(importlib.resources.read_text(
                attribute.__package__, 'default.toml'))['ws-server-token'])

        self.proxy: Optional[str] = None

        self.ssh: DeviceSSHClient = DeviceSSHClient(self, SSHClientConfig(device_id_to_hostname(device_id)))
        self.ssh.import_private_key(importlib.resources.read_binary(ssh_config.__package__, 'i2cd_rsa'))
        # TODO: self.websocket: DeviceWebSocketClient = DeviceWebSocketClient()

    # def import_websocket_credential(self, token, cert: Optional = None):
    #     self.websocket.import_credential(token, cert)

    async def import_registry(self, tier: floapi.Tier, credentials_only: bool = False):
        session: aiohttp.ClientSession
        async with aiohttp.ClientSession() as session:
            flo: floapi.Flo = floapi.Flo(
                session,
                floapi.DevAPIClientConfig(proxy=self.proxy) if tier is floapi.Tier.DEV
                else floapi.ProdAPIClientConfig(proxy=self.proxy))
            await flo.oauth()
            registry: floapi.Registry = await flo.registry(self.attribute.device_id)
            if not credentials_only:
                if registry.sku:
                    try:
                        self.attribute.calibration = json.loads(registry.sku)
                    except json.JSONDecodeError:
                        self.attribute.calibration = dict()
                    # except TypeError as e:
                    #     self.attribute.calibration = dict()
                    #     print("Error in sku json.loads: ", e)
                    #     print("registry value: ", registry)
                else:
                    self.attribute.calibration = dict()
                self.attribute.mqtt_host = toml.loads(importlib.resources.read_text(
                    attribute.__package__, 'dev.toml' if tier is floapi.Tier.DEV else 'prod.toml'))['mqtt-host']
                self.attribute.mqtt_port = toml.loads(importlib.resources.read_text(
                    attribute.__package__, 'dev.toml' if tier is floapi.Tier.DEV else 'prod.toml'))['mqtt-port']
                self.attribute.ssh_authorized_keys = asyncssh.import_private_key(base64.standard_b64decode(
                    registry.ssh_private_key.encode())).export_public_key().decode()
                self.attribute.ws_server_cert = base64.standard_b64decode(
                    registry.websocket_cert.encode()).decode()
                self.attribute.ws_server_key = base64.standard_b64decode(
                    registry.websocket_key.encode()).decode()
            self.attribute.ws_server_token = registry.icd_login_token
            self.ssh.import_private_key(base64.standard_b64decode(registry.ssh_private_key.encode()))
            # self.import_websocket_credential()

    async def replace_hostname_with_ip(self, ip: Optional[str] = None):
        if ip is None:
            ips: List[str] = list()
            for _ in range(10):
                executor: concurrent.futures.ThreadPoolExecutor
                with concurrent.futures.ThreadPoolExecutor() as executor:
                    ips = await asyncio.get_running_loop().run_in_executor(
                        executor, device_id_look_up, self.attribute.device_id)
                if ips:
                    break
            if not ips:
                raise FileNotFoundError
            ip: str = ips[0]
        self.ssh.config.hostname = ip
        # self.websocket.config.hostname = ip


@dataclasses.dataclass
class DeviceAttributes:
    device_id: str
    ssh_authorized_keys: str
    ws_server_token: str
    calibration: Dict[str, Union[float, int]] = dataclasses.field(default_factory=dict)
    mqtt_host: Optional[str] = None
    mqtt_port: Optional[int] = None
    ws_server_cert: Optional[str] = None
    ws_server_key: Optional[str] = None


class DeviceSerialMacroRunner:
    def __init__(self, serial_port: str):
        self.serial_port: str = serial_port

    async def run(self, macro_enum: enum.Enum) -> Generator[str, None, None]:
        path: pathlib.Path
        with importlib.resources.path(serial_macro.__package__, macro_enum.value) as path:
            runner: SerialMacroRunner = SerialMacroRunner(self.serial_port, str(path))
            message: str
            async for message in runner.run():
                yield message


class DeviceSSHClient(SSHClient):
    def __init__(self, device: DeviceClient, config: SSHClientConfig, *args, **kwargs):
        super().__init__(config, *args, **kwargs)
        self.device: DeviceClient = device

        method_class: Type[SSHClientMethod]
        for method_class in [
            ssh_method.CloseValveMethod,
            ssh_method.GetCalibrationMethod,
            ssh_method.GetModeMethod,
            ssh_method.GetRssiMethod,
            ssh_method.GetSerialMethod,
            ssh_method.GetValveStateMethod,
            ssh_method.ListenButtonClickMethod,
            ssh_method.LockMethod,
            ssh_method.OpenValveMethod,
            ssh_method.SetCalibrationMethod,
            ssh_method.SetModeMethod,
            ssh_method.SetSerialMethod,
            ssh_method.UnlockMethod,
        ]:
            self.register_method(method_class)
