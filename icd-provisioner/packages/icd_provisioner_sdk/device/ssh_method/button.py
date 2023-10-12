import importlib.resources
import pathlib

import asyncssh
import icd_provisioner_sdk as sdk

from .. import remote_script
from ... import ssh


class ListenButtonClickMethod(ssh.SSHClientMethod):
    METHOD_NAME = 'listen_button_click'

    async def run(
            self,
            no_copy_script: bool = False,
            only_copy_script: bool = False,
            bin_command: bool = False,
            timeout: int = 30) -> int:
        button_listener_program_name: str = 'button-listener'

        if bin_command:
            cp: asyncssh.SSHCompletedProcess = await self.client.run(
                'uni-button-listener', timeout=timeout)
            print(cp.stdout.strip())
            return cp.returncode
        else:
            if not no_copy_script:
                path: pathlib.Path
                with importlib.resources.path(remote_script.__package__, button_listener_program_name) as path:
                    await self.client.scp(str(path), sdk.ssh.SSHRemotePath(f'/run/{button_listener_program_name}'))

            if not only_copy_script:
                await self.client.run(f'chmod +x /run/{button_listener_program_name}')
                cp: asyncssh.SSHCompletedProcess = await self.client.run(
                    f'/run/{button_listener_program_name}', timeout=timeout)
                print(cp.stdout.strip())
                return cp.returncode

        return sdk.ExitStatus.EX_OK
