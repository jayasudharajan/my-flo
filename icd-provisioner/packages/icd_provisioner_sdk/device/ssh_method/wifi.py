import re

import asyncssh

from ... import ssh


class GetRssiMethod(ssh.SSHClientMethod):
    METHOD_NAME = 'get_rssi'

    async def run(self) -> int:
        ssh_res: asyncssh.SSHCompletedProcess = await self.client.run('iw wlan0 link', check=True)

        line: str
        for line in ssh_res.stdout.splitlines():
            if 'signal:' in line:
                return int(re.sub(' .*$', '', re.sub('^.*-', '-', line)))

        raise RuntimeError
