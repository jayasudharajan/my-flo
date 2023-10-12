import logging
from typing import Any, ClassVar, Dict, Optional

import icd_provisioner_sdk as sdk
import plumbum.cli

from . import subcommand


class ListenButtonCommand(subcommand.ICDProvisionerSubApp):
    """Listen for button clicks"""

    COMMAND_NAME: str = "listen-button"

    ip: ClassVar[plumbum.cli.SwitchAttr] = plumbum.cli.SwitchAttr(
        ["--ip"],
        help="Manually set the IP of the target device")

    no_copy_script: ClassVar[plumbum.cli.Flag] = plumbum.cli.Flag(
        ["--no-copy-script"], excludes=["--only-copy-script"],
        help="Only to execute the test script on the device, assuming the script exists on the device already")

    no_import_registry: ClassVar[plumbum.cli.Flag] = plumbum.cli.Flag(
        ["--no-import-registry"],
        help="Do not import registry from the cloud")

    bin_command: ClassVar[plumbum.cli.Flag] = plumbum.cli.Flag(
        ["--bin-command"],
        help="Run button-listener bin command instead of copied executable button script")

    only_copy_script: ClassVar[plumbum.cli.Flag] = plumbum.cli.Flag(
        ["--only-copy-script"], excludes=["--no-copy-script"],
        help="Only to copy the test script to the device")

    proxy: ClassVar[plumbum.cli.SwitchAttr] = plumbum.cli.SwitchAttr(
        ["--proxy"],
        help="Specify the proxy for the HTTP protocol")

    tier: ClassVar[plumbum.cli.SwitchAttr] = plumbum.cli.SwitchAttr(
        ["-t", "--tier"],
        plumbum.cli.Set(sdk.Tier.DEV.value, sdk.Tier.PROD.value),
        default=sdk.Tier.DEV.value,
        help="The target tier")

    timeout: ClassVar[plumbum.cli.SwitchAttr] = plumbum.cli.SwitchAttr(
        ["--timeout"],
        argtype=int,
        default=30,
        help="The period of the expiration")

    def main(self, device_id: str) -> int:
        return sdk.asyncio_run(listen_button(
            sdk.formalize_device_id(device_id),
            sdk.Tier[self.tier.upper()],
            self.ip,
            self.no_import_registry,
            self.proxy,
            self.no_copy_script,
            self.only_copy_script,
            self.bin_command,
            self.timeout))


async def listen_button(
        device_id: str,
        tier: sdk.Tier,
        ip: Optional[str] = None,
        no_import_registry: bool = False,
        proxy: Optional[str] = None,
        no_copy_script: bool = False,
        only_copy_script: bool = False,
        bin_command: bool = False,
        timeout: int = 30) -> Dict[str, Any]:
    device: sdk.DeviceClient = sdk.DeviceClient(device_id)
    if not no_import_registry:
        try:
            device.proxy = proxy
            await device.import_registry(tier)
        except Exception as e:
            logging.getLogger(__package__).debug(e)
    await device.replace_hostname_with_ip(ip)
    return await device.ssh.listen_button_click(
        no_copy_script=no_copy_script, only_copy_script=only_copy_script, bin_command=bin_command, timeout=timeout)
