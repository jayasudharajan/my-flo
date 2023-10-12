import dataclasses
import logging
from typing import Dict, Optional

import aiohttp

from ... import rest


class RegisterMethod(rest.RestClientMethod):
    METHOD_NAME = 'register'

    async def run(self, request_data: 'RegisterRequestData') -> bool:
        headers: Dict[str, str] = {
            next(iter(rest.Header.Authorization)): self.client.oauth_token,
            **rest.Header.ContentType_ApplicationJSON,
        }
        resp: aiohttp.ClientResponse
        async with self.client.session.post(
                f'{self.client.config.base_url}/stockicds/generate',
                headers=headers,
                json=dataclasses.asdict(request_data),
                proxy=self.client.config.proxy) as resp:
            logging.getLogger(__package__).info(resp)
            if not 200 <= resp.status < 300:
                raise RuntimeError
        return resp.status == 200


@dataclasses.dataclass
class RegisterRequestData:
    device_id: str
    icd_login_token: str
    sku: str
    ssh_private_key: str
    websocket_cert: str
    websocket_key: str
    wifi_ssid: str
    wlan_mac_id: str
    wifi_password: Optional[str] = None


@dataclasses.dataclass
class Registry(RegisterRequestData):
    pass


class RegistryMethod(rest.RestClientMethod):
    METHOD_NAME = 'registry'

    async def run(self, device_id: str) -> Registry:
        headers: Dict[str, str] = {
            next(iter(rest.Header.Authorization)): self.client.oauth_token,
            **rest.Header.ContentType_ApplicationJSON,
        }
        resp: aiohttp.ClientResponse
        async with self.client.session.get(
                f'{self.client.config.base_url}/stockicds/registration/device/{device_id}',
                headers=headers, proxy=self.client.config.proxy) as resp:
            logging.getLogger(__package__).info(resp)
            if resp.status != 200:
                raise RuntimeError
            return Registry(**await resp.json())
