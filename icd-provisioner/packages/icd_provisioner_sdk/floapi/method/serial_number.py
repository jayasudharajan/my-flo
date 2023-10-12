import dataclasses
import logging
from typing import Dict, Optional

import aiohttp

from ... import rest


@dataclasses.dataclass
class SerialNumberRequestData:
    device_id: str
    pcba: str
    product: str
    site: str
    valve: str


# Reference: https://flotechnologies.atlassian.net/wiki/spaces/FLO/pages/741474308
@dataclasses.dataclass
class SerialNumber:
    day_of_year: int
    device_id: str
    pcba: str
    product: str
    site: str
    sn: str
    valve: str
    year: int
    created_at: Optional[str] = None


class DeleteSerialNumberMethod(rest.RestClientMethod):
    METHOD_NAME = 'delete_serial_number'

    async def run(self, device_id: str):
        headers: Dict[str, str] = {
            next(iter(rest.Header.Authorization)): self.client.oauth_token,
            **rest.Header.ContentType_ApplicationJSON,
        }
        resp: aiohttp.ClientResponse
        async with self.client.session.delete(
                f'{self.client.config.base_url}/stockicds/sn?device_id={device_id}',
                headers=headers, proxy=self.client.config.proxy) as resp:
            logging.getLogger(__package__).info(resp)
            if resp.status != 200:
                raise RuntimeError(resp)


class GenerateSerialNumberMethod(rest.RestClientMethod):
    METHOD_NAME = 'generate_serial_number'

    async def run(self, serial_number_request_data: SerialNumberRequestData) -> SerialNumber:
        headers: Dict[str, str] = {
            next(iter(rest.Header.Authorization)): self.client.oauth_token,
            **rest.Header.ContentType_ApplicationJSON,
        }
        resp: aiohttp.ClientResponse
        async with self.client.session.post(
                f'{self.client.config.base_url}/stockicds/sn',
                headers=headers,
                json=dataclasses.asdict(serial_number_request_data),
                proxy=self.client.config.proxy) as resp:
            print(dataclasses.asdict(serial_number_request_data))
            logging.getLogger(__package__).info(resp)
            if resp.status == 409:
                raise ValueError("the serial number corresponding to this device ID already exists")
            elif resp.status != 200:
                raise RuntimeError("failed on generating the serial number")
            return SerialNumber(**await resp.json())


class GetSerialNumberMethod(rest.RestClientMethod):
    METHOD_NAME = 'get_serial_number'

    async def run(self, device_id: str) -> SerialNumber:
        headers: Dict[str, str] = {
            next(iter(rest.Header.Authorization)): self.client.oauth_token,
            **rest.Header.ContentType_ApplicationJSON,
        }
        resp: aiohttp.ClientResponse
        async with self.client.session.get(
                f'{self.client.config.base_url}/stockicds/sn?device_id={device_id}',
                headers=headers, proxy=self.client.config.proxy) as resp:
            logging.getLogger(__package__).info(resp)
            if resp.status != 200:
                raise RuntimeError
            d: Dict[str, Dict] = await resp.json()
            if d and d.get('items'):
                return SerialNumber(**d.get('items')[0])
            raise FileNotFoundError
