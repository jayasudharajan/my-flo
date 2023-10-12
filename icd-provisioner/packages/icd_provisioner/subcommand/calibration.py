import json
import logging
from typing import Any, ClassVar, Dict, Optional

import icd_provisioner_sdk as sdk
import plumbum.cli

from . import subcommand


class CalibrateCommand(subcommand.ICDProvisionerSubApp):
    """Write calibration data to the device"""

    COMMAND_NAME: str = "calibrate"

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

    def main(self, device_id: str, calibration: str) -> int:
        sdk.asyncio_run(set_calibration(
            sdk.formalize_device_id(device_id),
            sdk.Tier[self.tier.upper()],
            calibration,
            self.ip,
            self.no_import_registry,
            self.proxy))
        return sdk.ExitStatus.EX_OK


async def set_calibration(
        device_id: str,
        tier: sdk.Tier,
        calibration: str,
        ip: Optional[str] = None,
        no_import_registry: bool = False,
        proxy: Optional[str] = None) -> Dict[str, Any]:
    device: sdk.DeviceClient = sdk.DeviceClient(device_id)
    if not no_import_registry:
        try:
            device.proxy = proxy
            await device.import_registry(tier)
        except Exception as e:
            logging.getLogger(__package__).debug(e)
    await device.replace_hostname_with_ip(ip)
    return await device.ssh.set_calibration(json.dumps(json.loads(calibration)))


class CalibrationCommand(subcommand.ICDProvisionerSubApp):
    """Read calibration data from the device"""

    COMMAND_NAME: str = "calibration"

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

    def main(self, device_id: str) -> int:
        try:
            print(json.dumps(json.loads(sdk.asyncio_run(get_calibration(
            sdk.formalize_device_id(device_id),
            sdk.Tier[self.tier.upper()],
            self.ip,
            self.no_import_registry,
            self.proxy)))))
        except json.decoder.JSONDecodeError as e:
            print(e.msg)
        return sdk.ExitStatus.EX_OK


async def get_calibration(
        device_id: str,
        tier: sdk.Tier,
        ip: Optional[str] = None,
        no_import_registry: bool = False,
        proxy: Optional[str] = None) -> Dict[str, Any]:
    device: sdk.DeviceClient = sdk.DeviceClient(device_id)
    if not no_import_registry:
        try:
            device.proxy = proxy
            await device.import_registry(tier)
        except Exception as e:
            logging.getLogger(__package__).debug(e)
    await device.replace_hostname_with_ip(ip)
    return await device.ssh.get_calibration()
