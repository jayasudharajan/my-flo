import sys
from typing import ClassVar, Optional

import icd_provisioner_sdk as sdk
import plumbum.cli

from . import subcommand


async def get_lock_script(device_id: str, tier: sdk.Tier, proxy: Optional[str] = None) -> str:
    device: sdk.DeviceClient = sdk.DeviceClient(device_id)
    device.proxy = proxy
    await device.import_registry(tier)
    return await sdk.make_remote_lock_script(device.attribute)


async def get_unlock_script(device_id: str, tier: sdk.Tier, proxy: Optional[str] = None) -> str:
    device: sdk.DeviceClient = sdk.DeviceClient(device_id)
    device.proxy = proxy
    await device.import_registry(tier, credentials_only=True)
    return await sdk.make_remote_unlock_script(device.attribute)


async def lock(device_id: str, tier: sdk.Tier, ip: Optional[str] = None, proxy: Optional[str] = None):
    device: sdk.DeviceClient = sdk.DeviceClient(device_id)
    device.proxy = proxy
    await device.import_registry(tier)
    await device.replace_hostname_with_ip(ip)
    await device.ssh.lock(stdout_stream=sys.stdout, stderr_stream=sys.stderr)


class LockCommand(subcommand.ICDProvisionerSubApp):
    """Lock the target device"""

    COMMAND_NAME: str = "lock"

    dry_run: ClassVar[plumbum.cli.Flag] = plumbum.cli.Flag(
        ["-n", "--dry-run"],
        help="Only show the lock script that will be run on the device but not actually locking")

    ip: ClassVar[plumbum.cli.SwitchAttr] = plumbum.cli.SwitchAttr(
        ["--ip"],
        help="Manually set the IP of the target device")

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

        if self.dry_run:
            print(sdk.asyncio_run(get_lock_script(device_id, sdk.Tier[self.tier.upper()], self.proxy)))
        else:
            sdk.asyncio_run(lock(device_id, sdk.Tier[self.tier.upper()], self.ip, self.proxy))

        return sdk.ExitStatus.EX_OK


async def unlock(device_id: str, tier: sdk.Tier, ip: Optional[str] = None, proxy: Optional[str] = None):
    device: sdk.DeviceClient = sdk.DeviceClient(device_id)
    device.proxy = proxy
    await device.import_registry(tier, credentials_only=True)
    await device.replace_hostname_with_ip(ip)
    await device.ssh.unlock(stdout_stream=sys.stdout, stderr_stream=sys.stderr)


class UnlockCommand(subcommand.ICDProvisionerSubApp):
    """Unlock the target device"""

    COMMAND_NAME: str = "unlock"

    dry_run: ClassVar[plumbum.cli.Flag] = plumbum.cli.Flag(
        ["-n", "--dry-run"],
        help="Only show the unlock script that will be run on the device but not actually unlocking")

    ip: ClassVar[plumbum.cli.SwitchAttr] = plumbum.cli.SwitchAttr(
        ["--ip"],
        help="Manually set the IP of the target device")

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

        if self.dry_run:
            print(sdk.asyncio_run(get_unlock_script(device_id, sdk.Tier[self.tier.upper()], self.proxy)))
        else:
            sdk.asyncio_run(unlock(device_id, sdk.Tier[self.tier.upper()], self.ip, self.proxy))

        return sdk.ExitStatus.EX_OK
