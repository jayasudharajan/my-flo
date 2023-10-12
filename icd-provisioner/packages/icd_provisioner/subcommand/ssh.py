import asyncio
import logging
import sys
from typing import ClassVar, List, Optional

import asyncssh
import icd_provisioner_sdk as sdk
import plumbum.cli

from . import subcommand

POSIX_TTY_SUPPORTED: bool = False
try:
    import termios
    import tty
    POSIX_TTY_SUPPORTED = True
except ImportError:
    pass


async def run(
        device_id: str,
        tier: sdk.Tier,
        ip: Optional[str] = None,
        no_import_registry: bool = False,
        proxy: Optional[str] = None,
        command: Optional[str] = None):
    async def deal_with_stdin():
        await sdk.redirect_stream_to_async_streams(sys.stdin, [proc.stdin], stdin_stopper)

    async def deal_with_stdout():
        await sdk.redirect_async_stream_to_streams(proc.stdout, [sys.stdout])

    device: sdk.DeviceClient = sdk.DeviceClient(device_id)
    if not no_import_registry:
        try:
            device.proxy = proxy
            await device.import_registry(tier)
        except Exception as e:
            logging.getLogger(__package__).debug(e)
    await device.replace_hostname_with_ip(ip)
    conn: asyncssh.SSHClientConnection
    async with device.ssh.connect() as conn:
        proc: asyncssh.SSHClientProcess
        async with conn.create_process(command=command, term_type='xterm-color') as proc:
            if POSIX_TTY_SUPPORTED:
                fd: int = sys.stdin.fileno()
                tc_orig: List = termios.tcgetattr(fd)
                tty.setraw(fd)
            stdin_stopper = sdk.SingleReferenceValueWrapper(False)
            try:
                t: asyncio.Future = asyncio.ensure_future(asyncio.wait(
                    [deal_with_stdin(), deal_with_stdout()], return_when=asyncio.FIRST_EXCEPTION))
                await proc.wait_closed()
            finally:
                if not t.done():
                    stdin_stopper.value = True
                    t.cancel()
                if POSIX_TTY_SUPPORTED:
                    termios.tcsetattr(fd, termios.TCSADRAIN, tc_orig)
    return proc.exit_status


class SSHCommand(subcommand.ICDProvisionerSubApp):
    """SSH client that connects and logs into the specified device"""

    COMMAND_NAME: str = "ssh"

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

    def main(self, device_id: str, *cmds) -> int:
        cmd: Optional[str] = None
        if cmds:
            cmd = ' '.join(cmds)
        return sdk.asyncio_run(run(
            sdk.formalize_device_id(device_id),
            sdk.Tier[self.tier.upper()],
            ip=self.ip,
            no_import_registry=self.no_import_registry,
            proxy=self.proxy,
            command=cmd))
