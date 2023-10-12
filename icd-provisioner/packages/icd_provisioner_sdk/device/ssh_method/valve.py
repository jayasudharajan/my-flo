import enum
import json
from typing import ClassVar, Set

import asyncssh

from ... import ssh


class CloseValveMethod(ssh.SSHClientMethod):
    METHOD_NAME = 'close_valve'

    async def run(self) -> bool:
        ssh_res: asyncssh.SSHCompletedProcess = await self.client.run(
            'dbus-send --system --print-reply=literal --dest=com.flotechnologies.hal.valve '
            '/com/flotechnologies/hal/valve com.flotechnologies.hal.valve.SetStatus '
            '\'string:{"Status": "' + ValveState.CLOSED.value.lower() +
            '", "Reason": "command line tool"\'}', check=True)
        return 'OK' in ssh_res.stdout


class GetValveStateMethod(ssh.SSHClientMethod):
    METHOD_NAME = 'get_valve_state'

    async def run(self) -> 'ValveState':
        ssh_res: asyncssh.SSHCompletedProcess = await self.client.run(
            'dbus-send --system --print-reply=literal --dest=com.flotechnologies.hal.valve '
            '/com/flotechnologies/hal/valve com.flotechnologies.hal.valve.GetStatus', check=True)
        if 'OK' in ssh_res.stdout:
            return ValveState[json.loads(ssh_res.stdout)['Status'].upper()]
        raise RuntimeError


class OpenValveMethod(ssh.SSHClientMethod):
    METHOD_NAME = 'open_valve'

    async def run(self) -> bool:
        ssh_res: asyncssh.SSHCompletedProcess = await self.client.run(
            'dbus-send --system --print-reply=literal --dest=com.flotechnologies.hal.valve '
            '/com/flotechnologies/hal/valve com.flotechnologies.hal.valve.SetStatus '
            '\'string:{"Status": "' + ValveState.OPEN.value.lower() +
            '", "Reason": "command line tool"\'}', check=True)
        return 'OK' in ssh_res.stdout


class ValveState(enum.Enum):
    CLOSED: ClassVar[str] = 'CLOSED'
    CLOSING: ClassVar[str] = 'CLOSING'
    INVALID: ClassVar[str] = 'INVALID'
    OPEN: ClassVar[str] = 'OPEN'
    OPENING: ClassVar[str] = 'OPENING'
    TIMEOUT: ClassVar[str] = 'TIMEOUT'


SPECIFIABLE_VALVE_STATE: Set['ValveState'] = {
    ValveState.CLOSED,
    ValveState.OPEN,
}
