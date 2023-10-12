import asyncio
import itertools
import logging
import os
from typing import ClassVar, List, Optional, Tuple, Union

import icd_provisioner_sdk as sdk
import plumbum.cli

from . import subcommand
from .. import icd_provisioner


def parse_paths(input_paths) -> Tuple[str, List[Union[sdk.SSHRemotePath, str]], Union[sdk.SSHRemotePath, str]]:
    device_id: str = ''
    srcs: List[Union[sdk.SSHRemotePath, str]] = list()
    dest: Union[sdk.SSHRemotePath, str] = ''

    input_path: str
    for input_path in input_paths:
        if len(input_path) > 12 and input_path[12] == ':':
            device_id = sdk.formalize_device_id(input_path[:12])
            break

    i: int
    for i, input_path in enumerate(input_paths):
        path: Union[sdk.SSHRemotePath, str] = input_path
        if len(input_path) > 12 and input_path[12] == ':':
            path = sdk.SSHRemotePath(input_path[13:])
        if i < len(input_paths) - 1:
            srcs.append(path)
        else:
            dest = path

    return device_id, srcs, dest


async def scp(
        device_id: str,
        tier: sdk.Tier,
        srcs: List[Union[sdk.SSHRemotePath, str]],
        dest: Union[sdk.SSHRemotePath, str],
        recursive: bool = False,
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
    src: Union[sdk.SSHRemotePath, str]
    for src in srcs:
        t: asyncio.Task = asyncio.create_task(show_progress(device_id, src, dest))
        await device.ssh.scp(src, dest, recursive=recursive)
        t.cancel()
        print("\r -")


async def show_progress(device_id: str, src: Union[sdk.SSHRemotePath, str], dest: Union[sdk.SSHRemotePath, str]):
    # The progress bar library is kinda overkill: https://github.com/rsalmei/alive-progress
    # So just do it by ourselves.
    bar: str
    for bar in itertools.cycle("⣾⣷⣯⣟⡿⢿⣻⣽"):
        print(f"\r {bar} {src if isinstance(src, str) else device_id + ':' + src.path} -> "
              f"{dest if isinstance(dest, str) else device_id + ':' + dest.path}", end='')
        await asyncio.sleep(0.1)


class ScpCommand(subcommand.ICDProvisionerSubApp):
    """SSH client that connects and logs into the specified device"""

    COMMAND_NAME: str = "scp"
    USAGE: str = \
        f"    {icd_provisioner.__package__.replace('_', '-')} {COMMAND_NAME} [META-SWITCH]" \
        f"{os.linesep}" \
        f"    {icd_provisioner.__package__.replace('_', '-')} {COMMAND_NAME}" \
        f" [SWITCHES] [<device-id>:]file1 ... [<device-id>:]fileN"

    ip: ClassVar[plumbum.cli.SwitchAttr] = plumbum.cli.SwitchAttr(
        ["--ip"],
        help="Manually set the IP of the target device")

    no_import_registry: ClassVar[plumbum.cli.Flag] = plumbum.cli.Flag(
        ["--no-import-registry"],
        help="Do not import registry from the cloud")

    proxy: ClassVar[plumbum.cli.SwitchAttr] = plumbum.cli.SwitchAttr(
        ["--proxy"],
        help="Specify the proxy for the HTTP protocol")

    recursive: ClassVar[plumbum.cli.Flag] = plumbum.cli.Flag(
        ["-r", "--recursive"],
        help="Copy file(s) recursively")

    tier: ClassVar[plumbum.cli.SwitchAttr] = plumbum.cli.SwitchAttr(
        ["-t", "--tier"],
        plumbum.cli.Set(sdk.Tier.DEV.value, sdk.Tier.PROD.value),
        default=sdk.Tier.DEV.value,
        help="The target tier")

    def main(self, *args) -> int:
        if len(args) < 2:
            e: RuntimeError = RuntimeError("too few arguments provided")
            sdk.print_error(e)
            self.help()
            return sdk.ExitStatus.EX_USAGE

        srcs: List[Union[sdk.SSHRemotePath, str]]
        dest: Union[sdk.SSHRemotePath, str]
        device_id, srcs, dest = parse_paths(args)

        sdk.asyncio_run(scp(
            device_id,
            sdk.Tier[self.tier.upper()],
            srcs,
            dest,
            self.recursive,
            ip=self.ip,
            no_import_registry=self.no_import_registry,
            proxy=self.proxy))
        return sdk.ExitStatus.EX_OK
