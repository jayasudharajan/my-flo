import os
from typing import List

import icd_provisioner_sdk as sdk

from . import subcommand


class LookUpCommand(subcommand.ICDProvisionerSubApp):
    """Get the IP addresses of a device with the corresponding device ID"""

    COMMAND_NAME: str = "look-up"

    def main(self, device_id: str) -> int:
        for _ in range(10):
            ips: List[str] = sdk.device_id_look_up(sdk.formalize_device_id(device_id))
            if ips:
                print(os.linesep.join(ips))
                return sdk.ExitStatus.EX_OK
        return sdk.ExitStatus.EX_UNAVAILABLE
