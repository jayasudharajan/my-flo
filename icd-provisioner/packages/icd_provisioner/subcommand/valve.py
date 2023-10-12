import logging
from typing import ClassVar, Optional

import icd_provisioner_sdk as sdk
import plumbum.cli

from . import subcommand


async def get_valve_state(
        device_id: str,
        tier: sdk.Tier,
        ip: Optional[str] = None,
        no_import_registry: bool = False,
        proxy: Optional[str] = None) -> sdk.ValveState:
    device: sdk.DeviceClient = sdk.DeviceClient(device_id)
    if not no_import_registry:
        try:
            device.proxy = proxy
            await device.import_registry(tier)
        except Exception as e:
            logging.getLogger(__package__).debug(e)
    await device.replace_hostname_with_ip(ip)
    return await device.ssh.get_valve_state()


async def switch_valve(
        device_id: str,
        tier: sdk.Tier,
        dest_state: sdk.ValveState,
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
    if dest_state is sdk.ValveState.CLOSED:
        return await device.ssh.close_valve()
    elif dest_state is sdk.ValveState.OPEN:
        return await device.ssh.open_valve()
    else:
        raise ValueError


class ValveCommand(subcommand.ICDProvisionerSubApp):
    """Read serial number from the device"""

    COMMAND_NAME: str = "valve"

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
            dest_state: plumbum.cli.Set(sdk.ValveState.OPEN.value, sdk.ValveState.CLOSED.value) = '') -> int:
        res: int = sdk.ExitStatus.EX_SOFTWARE
        device_id = sdk.formalize_device_id(device_id)

        if dest_state:
            if sdk.asyncio_run(switch_valve(
                    device_id, sdk.Tier[self.tier.upper()],
                    sdk.ValveState[dest_state.upper()],
                    self.ip,
                    self.no_import_registry,
                    self.proxy)):
                res = sdk.ExitStatus.EX_OK
        else:
            ssh_res: sdk.ValveState
            if ssh_res := sdk.asyncio_run(get_valve_state(
                    device_id, sdk.Tier[self.tier.upper()], self.ip, self.no_import_registry, self.proxy)):
                print(ssh_res.value)
                res = sdk.ExitStatus.EX_OK

        return res
