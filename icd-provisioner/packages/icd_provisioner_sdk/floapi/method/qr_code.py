import logging
from typing import Dict

import aiohttp

from ... import rest


class QRCodeMethod(rest.RestClientMethod):
    METHOD_NAME = 'qr_code'

    async def run(self, device_id: str, decode: bool = False) -> str:
        headers: Dict[str, str] = {
            next(iter(rest.Header.Authorization)): self.client.oauth_token,
            **rest.Header.ContentType_ApplicationJSON,
        }
        resp: aiohttp.ClientResponse
        async with self.client.session.get(
                f'{self.client.config.base_url}/stockicds/device/{device_id}/{"qrdata" if decode else "qrcode"}',
                headers=headers, proxy=self.client.config.proxy) as resp:
            logging.getLogger(__package__).info(resp)
            if not 200 <= resp.status < 300:
                raise RuntimeError
            res: str = await resp.json() if decode else (await resp.json()).get('qr_code_data_svg')
            if res:
                return res
            raise RuntimeError
