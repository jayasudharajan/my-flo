from typing import ClassVar, Optional

import aiohttp
import icd_provisioner_sdk as sdk
import plumbum.cli

from . import subcommand


class QRCodeCommand(subcommand.ICDProvisionerSubApp):
    """Get the QR code of the target device"""

    COMMAND_NAME: str = "qr-code"

    decode: ClassVar[plumbum.cli.Flag] = plumbum.cli.Flag(
        ["-d", "--decode"],
        help="Decode the content in the QR code")

    proxy: ClassVar[plumbum.cli.SwitchAttr] = plumbum.cli.SwitchAttr(
        ["--proxy"],
        help="Specify the proxy for the HTTP protocol")

    tier: ClassVar[plumbum.cli.SwitchAttr] = plumbum.cli.SwitchAttr(
        ["-t", "--tier"],
        plumbum.cli.Set(sdk.Tier.DEV.value, sdk.Tier.PROD.value),
        default=sdk.Tier.DEV.value,
        help="The target tier")

    def main(self, device_id: str) -> int:
        device_id = sdk.formalize_device_id(device_id)
        print(sdk.asyncio_run(get_qr_code(device_id, self.decode, sdk.Tier[self.tier.upper()], self.proxy)))
        return sdk.ExitStatus.EX_OK


async def get_qr_code(device_id: str, decode: bool, tier: sdk.Tier, proxy: Optional[str]) -> str:
    session: aiohttp.ClientSession
    async with aiohttp.ClientSession() as session:
        flo: sdk.Flo = sdk.Flo(
            session,
            sdk.DevAPIClientConfig(proxy=proxy) if tier is sdk.Tier.DEV else sdk.ProdAPIClientConfig(proxy=proxy))
        await flo.oauth()
        return (await flo.qr_code(device_id, decode)).strip()
