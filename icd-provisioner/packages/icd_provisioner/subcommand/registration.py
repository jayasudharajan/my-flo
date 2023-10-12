import asyncio
import base64
import dataclasses
import json
from typing import Any, ClassVar, Dict, Optional

import aiohttp
import icd_provisioner_sdk as sdk
import plumbum.cli

from . import subcommand


async def register(req_data: sdk.RegisterRequestData, tier: sdk.Tier, proxy: Optional[str]):
    session: aiohttp.ClientSession
    async with aiohttp.ClientSession() as session:
        flo: sdk.Flo = sdk.Flo(
            session, sdk.DevAPIClientConfig(proxy=proxy) if tier is sdk.Tier.DEV else sdk.ProdAPIClientConfig(proxy=proxy))
        await flo.oauth()

        if not await flo.register(req_data):
            raise ConnectionError("failed on making the register call")

        # The cloud does not guarantee the whole registration process is successful even the register() endpoint
        # returns 200, so we have to make sure the process has gone through by ourselves.
        for _ in range(10):
            try:
                if await flo.registry(req_data.device_id):
                    break
            except Exception:
                pass
            await asyncio.sleep(1)
        else:
            raise AssertionError("failed on getting the registered info")
        for _ in range(10):
            try:
                if await flo.qr_code(req_data.device_id):
                    break
            except Exception:
                pass
            await asyncio.sleep(1)
        else:
            raise AssertionError("failed on getting the QR code")


class RegisterCommand(subcommand.ICDProvisionerSubApp):
    """Register the target device"""

    COMMAND_NAME: str = "register"

    proxy: ClassVar[plumbum.cli.SwitchAttr] = plumbum.cli.SwitchAttr(
        ["--proxy"],
        help="Specify the proxy for the HTTP protocol")

    sku: ClassVar[plumbum.cli.SwitchAttr] = plumbum.cli.SwitchAttr(
        ["--sku"], default='',
        help="The sku, we’re currently using this column storing the calibration value into the Flo cloud")

    tier: ClassVar[plumbum.cli.SwitchAttr] = plumbum.cli.SwitchAttr(
        ["-t", "--tier"],
        plumbum.cli.Set(sdk.Tier.DEV.value, sdk.Tier.PROD.value),
        default=sdk.Tier.DEV.value,
        help="The target tier")

    def main(self, device_id: str) -> int:
        try:
            sdk.asyncio_run(register(sdk.make_device_register_request_data(
                sdk.formalize_device_id(device_id), self.sku), sdk.Tier[self.tier.upper()], self.proxy))
            return sdk.ExitStatus.EX_OK
        except (AssertionError, ConnectionError) as e:
            sdk.print_error(e)
        return sdk.ExitStatus.EX_UNAVAILABLE


async def registry(device_id: str, tier: sdk.Tier, proxy: Optional[str]) -> sdk.Registry:
    session: aiohttp.ClientSession
    async with aiohttp.ClientSession() as session:
        flo: sdk.Flo = sdk.Flo(
            session, sdk.DevAPIClientConfig(proxy=proxy) if tier is sdk.Tier.DEV else sdk.ProdAPIClientConfig(proxy=proxy))
        await flo.oauth()
        return await flo.registry(device_id)


class RegistryCommand(subcommand.ICDProvisionerSubApp):
    """Get the registered information of the target device"""

    COMMAND_NAME: str = "registry"

    proxy: ClassVar[plumbum.cli.SwitchAttr] = plumbum.cli.SwitchAttr(
        ["--proxy"],
        help="Specify the proxy for the HTTP protocol")

    tier: ClassVar[plumbum.cli.SwitchAttr] = plumbum.cli.SwitchAttr(
        ["-t", "--tier"],
        plumbum.cli.Set(sdk.Tier.DEV.value, sdk.Tier.PROD.value),
        default=sdk.Tier.DEV.value,
        help="The target tier")

    def main(self, device_id: str) -> int:
        reg: sdk.Registry = sdk.asyncio_run(registry(
            sdk.formalize_device_id(device_id), sdk.Tier[self.tier.upper()], self.proxy))

        res: Dict[str, Any] = dataclasses.asdict(reg)
        res['sku'] = ''
        if reg.sku:
            try:
                res['sku'] = json.loads(reg.sku)
            except json.JSONDecodeError:
                pass
            # except TypeError as e:
            #     print("Error: ", e)
            #     print("Response: ", res)
        res['ssh_private_key'] = base64.standard_b64decode(reg.ssh_private_key.encode()).decode()
        res['websocket_cert'] = base64.standard_b64decode(reg.websocket_cert.encode()).decode()
        res['websocket_key'] = base64.standard_b64decode(reg.websocket_key.encode()).decode()
        print(json.dumps(res, indent=2, sort_keys=True))

        return sdk.ExitStatus.EX_OK
