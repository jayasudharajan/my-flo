import logging
from typing import Dict

import aiohttp

from ... import rest


class OAuthMethod(rest.RestClientMethod):
    METHOD_NAME = 'oauth'

    async def run(self) -> bool:
        headers: Dict[str, str] = {
            **rest.Header.ContentType_ApplicationJSON,
        }
        resp: aiohttp.ClientResponse
        async with self.client.session.post(
                f'{self.client.config.base_url}/oauth2/token',
                headers=headers,
                json={
                    'client_id': self.client.config.client_id,
                    'client_secret': self.client.config.client_secret,
                    'grant_type': 'client_credentials'},
                proxy=self.client.config.proxy) as resp:
            logging.getLogger(__package__).info(resp)
            if resp.status != 200:
                raise RuntimeError
            self.client.oauth_token = 'Bearer ' + (await resp.json())['access_token']
            return True
