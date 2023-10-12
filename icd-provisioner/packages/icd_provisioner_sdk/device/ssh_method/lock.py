import asyncio
import base64
import gzip
import importlib.resources
import io
import os
import tempfile
from typing import BinaryIO, Coroutine, IO, List, Optional, TextIO, Union

import asyncssh
import jinja2

from .. import device
from .. import remote_script
from ... import cli, ssh, util


async def make_remote_lock_script(attribute: 'device.DeviceAttributes') -> str:
    template: jinja2.Template = jinja2.Template(
        importlib.resources.read_text(remote_script.__package__, 'lock.sh'), enable_async=True)
    ssh_auth_keys_gzip_base64: str = base64.standard_b64encode(gzip.compress(
        f'{attribute.ssh_authorized_keys.rstrip()}\n'.encode())).decode()
    ws_server_cert_gzip_base64: str = base64.standard_b64encode(gzip.compress(
        f'{attribute.ws_server_key.rstrip()}\n{attribute.ws_server_cert.rstrip()}\n'.encode())).decode()
    ws_server_token_gzip_base64: str = base64.standard_b64encode(gzip.compress(
        f'{attribute.ws_server_token.rstrip()}\n'.encode())).decode()
    return await template.render_async(
        mqtt_host=attribute.mqtt_host,
        mqtt_port=attribute.mqtt_port,
        ssh_auth_keys_gzip_base64=ssh_auth_keys_gzip_base64,
        ws_server_cert_gzip_base64=ws_server_cert_gzip_base64,
        ws_server_token_gzip_base64=ws_server_token_gzip_base64)


async def make_remote_unlock_script(attribute: 'device.DeviceAttributes') -> str:
    attribute: device.DeviceAttributes = device.DeviceClient(attribute.device_id).attribute
    template: jinja2.Template = jinja2.Template(
        importlib.resources.read_text(remote_script.__package__, 'unlock.sh'), enable_async=True)
    ssh_auth_keys_gzip_base64: str = base64.standard_b64encode(gzip.compress(
        f'{attribute.ssh_authorized_keys.rstrip()}\n'.encode())).decode()
    ws_server_token_gzip_base64: str = base64.standard_b64encode(gzip.compress(
        f'{attribute.ws_server_token.rstrip()}\n'.encode())).decode()
    return await template.render_async(
        ssh_auth_keys_gzip_base64=ssh_auth_keys_gzip_base64,
        ws_server_token_gzip_base64=ws_server_token_gzip_base64)


class LockMethod(ssh.SSHClientMethod):
    METHOD_NAME = 'lock'

    async def run(
            self,
            stdout_stream: Optional[Union[BinaryIO, TextIO]],
            stderr_stream: Optional[Union[BinaryIO, TextIO]]) -> str:
        script_f: IO = tempfile.NamedTemporaryFile(mode='w+b', delete=False)
        script_f.write((await make_remote_lock_script(self.client.device.attribute)).encode())
        script_f.flush()
        await self.client.scp(script_f.name, ssh.SSHRemotePath('/run/lock.sh'))
        script_f.close()
        os.remove(script_f.name)

        result: TextIO = io.StringIO()

        conn: asyncssh.SSHClientConnection
        async with self.client.connect() as conn:
            proc: asyncssh.SSHClientProcess
            async with conn.create_process('ash /run/lock.sh') as proc:
                stdout_streams: List[Union[BinaryIO, TextIO]] = [result]
                if stdout_stream:
                    stdout_streams.append(stdout_stream)

                coros: List[Coroutine] = [util.redirect_async_stream_to_streams(proc.stdout, stdout_streams)]
                if stderr_stream:
                    coros.append(util.redirect_async_stream_to_streams(proc.stderr, [stderr_stream]))

                await asyncio.wait(coros)

            if proc.exit_status != cli.ExitStatus.EX_OK:
                raise RuntimeError
            return result.read()


class UnlockMethod(ssh.SSHClientMethod):
    METHOD_NAME = 'unlock'

    async def run(
            self,
            stdout_stream: Optional[Union[BinaryIO, TextIO]],
            stderr_stream: Optional[Union[BinaryIO, TextIO]]) -> str:
        script_f: IO = tempfile.NamedTemporaryFile(mode='w+b', delete=False)
        script_f.write((await make_remote_unlock_script(self.client.device.attribute)).encode())
        script_f.flush()
        await self.client.scp(script_f.name, ssh.SSHRemotePath('/run/unlock.sh'))
        script_f.close()
        os.remove(script_f.name)

        result: TextIO = io.StringIO()

        conn: asyncssh.SSHClientConnection
        async with self.client.connect() as conn:
            proc: asyncssh.SSHClientProcess
            async with conn.create_process('ash /run/unlock.sh') as proc:
                stdout_streams: List[Union[BinaryIO, TextIO]] = [result]
                if stdout_stream:
                    stdout_streams.append(stdout_stream)

                coros: List[Coroutine] = [util.redirect_async_stream_to_streams(proc.stdout, stdout_streams)]
                if stderr_stream:
                    coros.append(util.redirect_async_stream_to_streams(proc.stderr, [stderr_stream]))

                await asyncio.wait(coros)

            if proc.exit_status != cli.ExitStatus.EX_OK:
                raise RuntimeError
            return result.read()
