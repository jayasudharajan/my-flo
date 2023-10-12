from ... import ssh


class GetSerialMethod(ssh.SSHClientMethod):
    METHOD_NAME = 'get_serial_number'

    async def run(self) -> str:
        return (await self.client.run('fw_printenv -n sn')).stdout


class SetSerialMethod(ssh.SSHClientMethod):
    METHOD_NAME = 'set_serial_number'

    async def run(self, serial_number: str) -> str:
        return (await self.client.run(f'fw_setenv sn {serial_number}', check=True)).stdout
