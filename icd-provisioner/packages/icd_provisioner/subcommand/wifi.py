import logging
from typing import ClassVar, Optional

import icd_provisioner_sdk as sdk
import plumbum.cli

from . import subcommand


class WiFiCommand(subcommand.ICDProvisionerSubApp):
    """Deal with Wi-Fi related functions"""

    COMMAND_NAME: str = "wifi"

    iface: ClassVar[plumbum.cli.SwitchAttr] = plumbum.cli.SwitchAttr(
        ["-i", "--interface"],
        default="wlan0",
        help="The Wi-Fi interface on the device")

    ip: ClassVar[plumbum.cli.SwitchAttr] = plumbum.cli.SwitchAttr(
        ["--ip"],
        help="Manually set the IP of the target device")

    no_import_registry: ClassVar[plumbum.cli.Flag] = plumbum.cli.Flag(
        ["--no-import-registry"],
        help="Do not import registry from the cloud")

    proxy: ClassVar[plumbum.cli.SwitchAttr] = plumbum.cli.SwitchAttr(
        ["--proxy"],
        help="Specify the proxy for the HTTP protocol")

    tier: ClassVar[plumbum.cli.SwitchAttr] = plumbum.cli.SwitchAttr(
        ["-t", "--tier"],
        plumbum.cli.Set(sdk.Tier.DEV.value, sdk.Tier.PROD.value),
        default=sdk.Tier.DEV.value,
        help="The target tier")

    def main(self, *args, **kwargs) -> int:
        if args:
            print(f"Unknown command {args[0]!r}")
            return sdk.ExitStatus.EX_UNAVAILABLE
        if not self.nested_command:
            self.help()
            return sdk.ExitStatus.EX_OK


async def get_rssi(
        device_id: str,
        tier: sdk.Tier,
        ip: Optional[str] = None,
        no_import_registry: bool = False,
        proxy: Optional[str] = None) -> int:
    device: sdk.DeviceClient = sdk.DeviceClient(device_id)
    if not no_import_registry:
        try:
            device.proxy = proxy
            await device.import_registry(tier)
        except Exception as e:
            logging.getLogger(__package__).debug(e)
    await device.replace_hostname_with_ip(ip)
    return await device.ssh.get_rssi()


class GetRssiCommand(subcommand.ICDProvisionerSubApp):
    """Get RSSI"""

    COMMAND_NAME: str = "rssi"

    def main(self, device_id: str) -> int:
        dbm: str = sdk.asyncio_run(get_rssi(
            sdk.formalize_device_id(device_id),
            sdk.Tier[self.parent.tier.upper()],
            self.parent.ip,
            self.parent.no_import_registry,
            self.parent.proxy))
        print(f'{dbm} dBm')
        return sdk.ExitStatus.EX_OK


WiFiCommand.subcommand(GetRssiCommand.COMMAND_NAME, GetRssiCommand)
