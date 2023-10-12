import asyncio
import concurrent.futures
import queue
from typing import Generator

import ipcq


# FIXME: multiprocessing/resource_tracker.py:216: UserWarning: resource_tracker: There appear to be 3 leaked semaphore objects to clean up at shutdown
class SerialMacroRunner:
    def __init__(self, serial_port: str, macro_file: str):
        self.serial_port: str = serial_port
        self.macro_file: str = macro_file

    async def run(self) -> Generator[str, None, None]:
        manager: ipcq.QueueManagerServer
        with ipcq.QueueManagerServer(authkey=ipcq.AuthKey.DEFAULT) as manager:
            proc: asyncio.subprocess.Process = await asyncio.create_subprocess_exec(
                'macross-serial', 'run', self.serial_port, self.macro_file, manager.address)

            executor: concurrent.futures.ThreadPoolExecutor
            with concurrent.futures.ThreadPoolExecutor(max_workers=1) as executor:
                while proc.returncode is None:
                    try:
                        msg: str = await asyncio.get_running_loop().run_in_executor(
                            executor, manager.get_queue().get, True, 1)
                    except queue.Empty:
                        continue
                    except TypeError:
                        # FIXME: not sure why the flow goes here sometimes. Just ignore it for now.
                        continue
                    yield msg
