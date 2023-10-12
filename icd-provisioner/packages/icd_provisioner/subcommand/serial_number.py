import dataclasses
import json
import logging
from typing import ClassVar, Optional

import aiohttp
import icd_provisioner_sdk as sdk
import plumbum.cli

from . import subcommand


class SerialNumberCommand(subcommand.ICDProvisionerSubApp):
    """Handle serial number related functions"""

    COMMAND_NAME: str = "serial-number"

    proxy: ClassVar[plumbum.cli.SwitchAttr] = plumbum.cli.SwitchAttr(
        ["--proxy"],
        help="Specify the proxy for the HTTP protocol")

    tier: ClassVar[plumbum.cli.SwitchAttr] = plumbum.cli.SwitchAttr(
        ["-t", "--tier"],
        plumbum.cli.Set(sdk.Tier.DEV.value, sdk.Tier.PROD.value),
        default=sdk.Tier.DEV.value,
        help="The target tier")


async def generate_serial_number(
        request_data: sdk.SerialNumberRequestData,
        tier: sdk.Tier,
        ignore_conflict: bool = False,
        proxy: Optional[str] = None) -> sdk.SerialNumber:
    session: aiohttp.ClientSession
    async with aiohttp.ClientSession() as session:
        flo: sdk.Flo = sdk.Flo(
            session,
            sdk.DevAPIClientConfig(proxy=proxy) if tier is sdk.Tier.DEV else sdk.ProdAPIClientConfig(proxy=proxy))
        await flo.oauth()
        if ignore_conflict:
            try:
                return await flo.get_serial_number(request_data.device_id)
            except Exception as e:
                logging.getLogger(__package__).debug(e)
        return await flo.generate_serial_number(request_data)


class GenerateSerialNumberCommand(subcommand.ICDProvisionerSubApp):
    """Generate serial number by the cloud"""

    COMMAND_NAME: str = "generate"

    ignore_conflict: ClassVar[plumbum.cli.Flag] = plumbum.cli.Flag(
        ["-i", "--ignore-conflict"],
        help="Ignore the conflict error when there already is a serial number for the target device")

    pcba: ClassVar[plumbum.cli.SwitchAttr] = plumbum.cli.SwitchAttr(
        ["-p", "--pcba"],
        plumbum.cli.Set(
            "A", "B", "D", "Z",
            case_sensitive=True),
        mandatory=True,
        help="The manufacturing site of the PCBA")

    product: ClassVar[plumbum.cli.SwitchAttr] = plumbum.cli.SwitchAttr(
        ["-f", "--product"],
        plumbum.cli.Set(
            "A", "B", "C", "D", "E", "G", "H", "J", "K", "L", "M", "N", "Z",
            case_sensitive=True),
        mandatory=True,
        help="The model/version/revision/sku of the product")

    site: ClassVar[plumbum.cli.SwitchAttr] = plumbum.cli.SwitchAttr(
        ["-m", "--site"],
        plumbum.cli.Set(
            "A", "B", "D", "Z",
            case_sensitive=True),
        mandatory=True,
        help="The manufacturing site of the product")

    sub_assembly: ClassVar[plumbum.cli.SwitchAttr] = plumbum.cli.SwitchAttr(
        ["-s", "--sub-assembly"],
        plumbum.cli.Set(
            "A", "Z",
            case_sensitive=True),
        mandatory=True,
        help="The manufacturing site of the sub-assembly")

    def main(self, device_id: str) -> int:
        print(json.dumps(dataclasses.asdict(sdk.asyncio_run(generate_serial_number(sdk.SerialNumberRequestData(
                device_id=sdk.formalize_device_id(device_id),
                pcba=self.pcba,
                product=self.product,
                site=self.site,
                valve=self.sub_assembly),
            sdk.Tier[self.parent.tier.upper()], self.ignore_conflict, self.parent.proxy))),
            indent=2, sort_keys=True))
        return sdk.ExitStatus.EX_OK


async def get_serial_number_from_cloud(device_id: str, tier: sdk.Tier, proxy: Optional[str] = None) -> sdk.SerialNumber:
    session: aiohttp.ClientSession
    async with aiohttp.ClientSession() as session:
        flo: sdk.Flo = sdk.Flo(
            session,
            sdk.DevAPIClientConfig(proxy=proxy) if tier is sdk.Tier.DEV else sdk.ProdAPIClientConfig(proxy=proxy))
        await flo.oauth()
        return await flo.get_serial_number(device_id)


async def delete_serial_number_from_cloud(
        device_id: str, tier: sdk.Tier, proxy: Optional[str] = None) -> sdk.SerialNumber:
    session: aiohttp.ClientSession
    async with aiohttp.ClientSession() as session:
        flo: sdk.Flo = sdk.Flo(
            session,
            sdk.DevAPIClientConfig(proxy=proxy) if tier is sdk.Tier.DEV else sdk.ProdAPIClientConfig(proxy=proxy))
        await flo.oauth()
        return await flo.delete_serial_number(device_id)


class ReadCloudSerialNumberCommand(subcommand.ICDProvisionerSubApp):
    """Read serial number from the cloud"""

    COMMAND_NAME: str = "read-cloud"

    def main(self, device_id: str) -> int:
        print(json.dumps(dataclasses.asdict(sdk.asyncio_run(
            get_serial_number_from_cloud(
                sdk.formalize_device_id(device_id), sdk.Tier[self.parent.tier.upper()], proxy=self.parent.proxy))),
            indent=2, sort_keys=True))
        return sdk.ExitStatus.EX_OK


class DeleteCloudSerialNumberCommand(subcommand.ICDProvisionerSubApp):
    """Read serial number from the cloud"""

    COMMAND_NAME: str = "delete-cloud"

    def main(self, device_id: str) -> int:
        sdk.asyncio_run(delete_serial_number_from_cloud(
            sdk.formalize_device_id(device_id), sdk.Tier[self.parent.tier.upper()], proxy=self.parent.proxy))
        return sdk.ExitStatus.EX_OK


async def get_serial_number(
        device_id: str,
        tier: sdk.Tier,
        ip: Optional[str] = None,
        no_import_registry: bool = False,
        proxy: Optional[str] = None) -> str:
    device: sdk.DeviceClient = sdk.DeviceClient(device_id)
    if not no_import_registry:
        try:
            device.proxy = proxy
            await device.import_registry(tier)
        except Exception as e:
            logging.getLogger(__package__).debug(e)
    await device.replace_hostname_with_ip(ip)
    return await device.ssh.get_serial_number()


class ReadSerialNumberCommand(subcommand.ICDProvisionerSubApp):
    """Read serial number from the device"""

    COMMAND_NAME: str = "read"

    ip: ClassVar[plumbum.cli.SwitchAttr] = plumbum.cli.SwitchAttr(
        ["--ip"],
        help="Manually set the IP of the target device")

    no_import_registry: ClassVar[plumbum.cli.Flag] = plumbum.cli.Flag(
        ["--no-import-registry"],
        help="Do not import registry from the cloud")

    def main(self, device_id: str) -> int:
        res: str = sdk.asyncio_run(get_serial_number(
            sdk.formalize_device_id(device_id),
            sdk.Tier[self.parent.tier.upper()],
            self.ip,
            self.no_import_registry,
            self.parent.proxy)).strip()
        if res:
            print(res)
            return sdk.ExitStatus.EX_OK
        return sdk.ExitStatus.EX_NOTFOUND


async def set_serial_number(
        device_id: str,
        tier: sdk.Tier,
        serial_number: str,
        ip: Optional[str] = None,
        no_import_registry: bool = False,
        proxy: Optional[str] = None):
    device: sdk.DeviceClient = sdk.DeviceClient(device_id)
    if not no_import_registry:
        try:
            device.proxy = proxy
            await device.import_registry(tier)
        except Exception as e:
            logging.getLogger(__package__).debug(e)
    await device.replace_hostname_with_ip(ip)
    return await device.ssh.set_serial_number(serial_number)


class WriteSerialNumberCommand(subcommand.ICDProvisionerSubApp):
    """Write serial number to the device"""

    COMMAND_NAME: str = "write"

    ip: ClassVar[plumbum.cli.SwitchAttr] = plumbum.cli.SwitchAttr(
        ["--ip"],
        help="Manually set the IP of the target device")

    no_import_registry: ClassVar[plumbum.cli.Flag] = plumbum.cli.Flag(
        ["--no-import-registry"],
        help="Do not import registry from the cloud")

    def main(self, device_id: str, serial_number: str) -> int:
        sdk.asyncio_run(set_serial_number(
            sdk.formalize_device_id(device_id),
            sdk.Tier[self.parent.tier.upper()],
            serial_number,
            self.ip,
            self.no_import_registry,
            self.parent.proxy))
        return sdk.ExitStatus.EX_OK


sub_command_class: subcommand.ICDProvisionerSubApp
for sub_command_class in [
    DeleteCloudSerialNumberCommand,
    GenerateSerialNumberCommand,
    ReadCloudSerialNumberCommand,
    ReadSerialNumberCommand,
    WriteSerialNumberCommand,
]:
    SerialNumberCommand.subcommand(sub_command_class.COMMAND_NAME, sub_command_class)
