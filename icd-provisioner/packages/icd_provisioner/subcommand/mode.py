import logging
from typing import ClassVar, Optional

import icd_provisioner_sdk as sdk
import plumbum.cli

from . import subcommand
from .. import icd_provisioner


async def get_mode(
        device_id: str,
        tier: sdk.Tier,
        ip: Optional[str] = None,
        no_import_registry: bool = False,
        proxy: Optional[str] = None) -> sdk.Mode:
    device: sdk.DeviceClient = sdk.DeviceClient(device_id)
    if not no_import_registry:
        try:
            device.proxy = proxy
            await device.import_registry(tier)
        except Exception as e:
            logging.getLogger(__package__).debug(e)
    await device.replace_hostname_with_ip(ip)
    return await device.ssh.get_mode()


async def set_mode(
        device_id: str,
        tier: sdk.Tier,
        mode: sdk.Mode,
        ip: Optional[str] = None,
        no_import_registry: bool = False,
        proxy: Optional[str] = None) -> bool:
    device: sdk.DeviceClient = sdk.DeviceClient(device_id)
    if not no_import_registry:
        try:
            device.proxy = proxy
            await device.import_registry(tier)
        except Exception as e:
            logging.getLogger(__package__).debug(e)
    await device.replace_hostname_with_ip(ip)
    return await device.ssh.set_mode(mode)


class ModeCommand(subcommand.ICDProvisionerSubApp):
    """Get and set the Mode"""

    COMMAND_NAME: str = "mode"

    USAGE: str = \
        f"    {icd_provisioner.__package__.replace('_', '-')} {COMMAND_NAME} [SWITCHES] device_id " \
        f"[mode={{{{{','.join(m.name for m in sdk.Mode)}}}}}]"

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

    def main(
            self,
            device_id: str,
            mode: plumbum.cli.Set(
                sdk.Mode.AUTORUN.name,
                sdk.Mode.HOME.name,
                sdk.Mode.AWAY.name,
                sdk.Mode.VACATION.name,
                sdk.Mode.LEARNING.name,
                sdk.Mode.MAINTENANCE.name,
                sdk.Mode.BUILDER.name) = '') -> int:
        res: int = sdk.ExitStatus.EX_SOFTWARE
        device_id = sdk.formalize_device_id(device_id)

        if mode:
            if sdk.asyncio_run(set_mode(
                    device_id, sdk.Tier[self.tier.upper()],
                    sdk.Mode[mode.upper()],
                    self.ip,
                    self.no_import_registry,
                    self.proxy)):
                res = sdk.ExitStatus.EX_OK
        else:
            ssh_res: sdk.Mode
            if ssh_res := sdk.asyncio_run(get_mode(
                    device_id, sdk.Tier[self.tier.upper()], self.ip, self.no_import_registry, self.proxy)):
                print(ssh_res.name)
                res = sdk.ExitStatus.EX_OK

        return res
