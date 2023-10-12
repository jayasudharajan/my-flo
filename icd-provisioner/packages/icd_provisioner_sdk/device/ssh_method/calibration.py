import base64
import gzip

from ... import ssh


class GetCalibrationMethod(ssh.SSHClientMethod):
    METHOD_NAME = 'get_calibration'

    async def run(self) -> str:
        return gzip.decompress(base64.standard_b64decode(
            (await self.client.run('fw_printenv -n fr-cal')).stdout.strip().encode())).decode()


class SetCalibrationMethod(ssh.SSHClientMethod):
    METHOD_NAME = 'set_calibration'

    async def run(self, calibration: str) -> str:
        encoded_calibration: str = base64.standard_b64encode(gzip.compress(calibration.strip().encode())).decode()
        return (await self.client.run(f'fw_setenv fr-cal {encoded_calibration}', check=True)).stdout
