import logging
import sys
from typing import ClassVar

import icd_provisioner_sdk as sdk
import plumbum.cli

from . import subcommand


class ICDProvisionerApp(plumbum.cli.Application):
    PROGNAME: str = "icd-provisioner"
    VERSION: str = sdk.version()

    debug: ClassVar[plumbum.cli.Flag] = plumbum.cli.Flag(
        ["d", "debug"], help="If given, I will be very talkative")

    verbose: ClassVar[plumbum.cli.Flag] = plumbum.cli.Flag(
        ["v", "verbose"], help="If given, I will be talkative")

    def main(self, *args) -> int:
        if args:
            print(f"Unknown command {args[0]!r}")
            return sdk.ExitStatus.EX_UNAVAILABLE
        if not self.nested_command:
            self.help()
            return sdk.ExitStatus.EX_OK

        if self.debug:
            logging.basicConfig(level=logging.DEBUG)
        elif self.verbose:
            logging.basicConfig(level=logging.INFO)
        else:
            logging.basicConfig(level=logging.WARNING)
        return sdk.ExitStatus.EX_OK


def main():
    sub_command_class: subcommand.ICDProvisionerSubApp
    for sub_command_class in [
        subcommand.CalibrateCommand,
        subcommand.CalibrationCommand,
        subcommand.ListenButtonCommand,
        subcommand.LockCommand,
        subcommand.LookUpCommand,
        subcommand.ModeCommand,
        subcommand.QRCodeCommand,
        subcommand.RegisterCommand,
        subcommand.RegistryCommand,
        subcommand.ScpCommand,
        subcommand.SerialCommand,
        subcommand.SerialNumberCommand,
        subcommand.SSHCommand,
        subcommand.UnlockCommand,
        subcommand.ValveCommand,
        subcommand.WiFiCommand,
    ]:
        ICDProvisionerApp.subcommand(sub_command_class.COMMAND_NAME, sub_command_class)

    sys.exit(ICDProvisionerApp.run())
