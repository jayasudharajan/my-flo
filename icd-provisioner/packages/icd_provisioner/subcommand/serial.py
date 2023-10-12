import asyncio
import enum
import os

import icd_provisioner_sdk as sdk
import ipcq
import plumbum.cli

from . import subcommand


class SerialCommand(subcommand.ICDProvisionerSubApp):
    """Handles device serial"""

    COMMAND_NAME: str = "serial"

    def main(self, *args, **kwargs) -> int:
        if args:
            print(f"Unknown command {args[0]!r}")
            return sdk.ExitStatus.EX_UNAVAILABLE
        if not self.nested_command:
            self.help()
            return sdk.ExitStatus.EX_OK


class ConsoleCommand(subcommand.ICDProvisionerSubApp):
    """Interactive serial console"""

    COMMAND_NAME: str = "console"

    # TODO: Implementation


class ListCommand(subcommand.ICDProvisionerSubApp):
    """List serial ports"""

    COMMAND_NAME: str = "list"

    def main(self) -> int:
        return sdk.subprocess_run_hidden(['macross-serial', 'list-port'], text=True).returncode


# Reference for the progress_tunnel:
#   https://gist.github.com/changyuheng/89062d639e40110c61c2f88018a8b0e5
async def run(port: str, macro_enum: enum.Enum, progress_tunnel: str):
    runner: sdk.DeviceSerialMacroRunner = sdk.DeviceSerialMacroRunner(port)
    message: str
    async for message in runner.run(macro_enum):
        if progress_tunnel:
            qmc: ipcq.QueueManagerClient = ipcq.QueueManagerClient(
                progress_tunnel, authkey=ipcq.AuthKey.DEFAULT)
            qmc.get_queue().put(message)
            continue
        print(message)
    if 'ERROR' in message:
        raise RuntimeError(message)


class RunCommand(subcommand.ICDProvisionerSubApp):
    """Run the macro on the serial console"""

    COMMAND_NAME: str = "run"

    def main(
            self,
            port: str,
            macro_enum: plumbum.cli.Set(sdk.DeviceSerialMacro.FACTORY_PCBA_5_2_11.name, sdk.DeviceSerialMacro.FACTORY_PCBA_5_2_12.name),
            progress_tunnel: str = '') -> int:

        if os.name == 'nt':
            sdk.asyncio_run(run(port, sdk.DeviceSerialMacro[macro_enum.upper()], progress_tunnel),
                            asyncio.WindowsProactorEventLoopPolicy())
        else:
            sdk.asyncio_run(run(port, sdk.DeviceSerialMacro[macro_enum.upper()], progress_tunnel))
        return sdk.ExitStatus.EX_OK


SerialCommand.subcommand(ConsoleCommand.COMMAND_NAME, ConsoleCommand)
SerialCommand.subcommand(ListCommand.COMMAND_NAME, ListCommand)
SerialCommand.subcommand(RunCommand.COMMAND_NAME, RunCommand)
