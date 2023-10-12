import enum
import json
from typing import ClassVar

import asyncssh

from ... import ssh


class GetModeMethod(ssh.SSHClientMethod):
    METHOD_NAME = 'get_mode'

    async def run(self) -> 'Mode':
        try:
            ssh_res: asyncssh.SSHCompletedProcess = await self.client.run(
                'sqlite3 /data/flod/flod.db "SELECT mode FROM \'system-settings\' LIMIT 1;"', check=True)
            if ssh_res.returncode or not ssh_res.stdout.strip():
                raise RuntimeError
        except Exception:
            ssh_res = await self.client.run(
                'sqlite3 /data/ultima/ultima-server.db "SELECT value FROM setting WHERE key = \'system_mode\' LIMIT 1;"',
                check=True)
            if ssh_res.returncode or not ssh_res.stdout.strip():
                raise RuntimeError
        return Mode(int(ssh_res.stdout.strip()))


class SetModeMethod(ssh.SSHClientMethod):
    METHOD_NAME = 'set_mode'

    async def run(self, mode: 'Mode') -> bool:
        ssh_res: asyncssh.SSHCompletedProcess = await self.client.run(
            'dbus-send --system --print-reply=literal --dest=com.flotechnologies.ultima '
            '/com/flotechnologies/ultima com.flotechnologies.ultima.set_system_mode string:\'{"mode": '
            + str(mode.value) + '}\'', check=True)
        return 'OK' in ssh_res.stdout


class Mode(enum.IntEnum):
    AUTORUN: ClassVar[int] = 1
    HOME: ClassVar[int] = 2
    AWAY: ClassVar[int] = 3
    VACATION: ClassVar[int] = 4
    LEARNING: ClassVar[int] = 5
    MAINTENANCE: ClassVar[int] = 6
    BUILDER: ClassVar[int] = 7
