import argparse
import os
import platform
import re
import shutil
import subprocess
import sys
from typing import IO, List


def get_requirements() -> List[str]:
    res: List[str] = [f'icd_provisioner=={get_version()}']

    line: str
    for line in subprocess.run(
            ['poetry', 'export'],
            stdout=subprocess.PIPE, text=True).stdout.splitlines():
        if line.startswith(' ') or line.startswith('\t'):
            continue
        res.append(line[:line.find(';')])

    return res


def workaround_wheel_name_for_pynsist():
    fname: str
    for fname in os.listdir(os.path.join('build', 'wheels')):
        if 'none' not in fname:
            src: str = f'{os.path.join("build", "wheels", fname)}'
            dst: str = f'{os.path.join("build", "wheels", re.sub(r"-cp[^-]+-win", "-none-win", fname))}'
            os.rename(src, dst)
            fname = os.path.basename(dst)
        if '-abi3-' in fname:
            src = f'{os.path.join("build", "wheels", fname)}'
            dst: str = f'{os.path.join("build", "wheels", fname.replace("-abi3-", "-none-"))}'
            os.rename(src, dst)
            fname = os.path.basename(dst)
        if '-cp36-' in fname:
            src = f'{os.path.join("build", "wheels", fname)}'
            dst: str = f'{os.path.join("build", "wheels", fname.replace("-cp36-", "-cp39-"))}'
            os.rename(src, dst)


def get_version() -> str:
    f: IO[str]
    with open('pyproject.toml', encoding='utf-8') as f:
        line: str
        for line in f.readlines():
            if not line.startswith('version '):
                continue
            m: re.Match = re.search('"(.*)"', line)
            if not m:
                raise RuntimeError('unable to get the version number')
            return m.group(1).strip()


def pack_for_windows(args: argparse.Namespace):
    os.system('poetry run pip install --upgrade wheel')
    os.system(f'poetry run pip wheel . --no-deps --wheel-dir {os.path.join("build", "wheels")}')
    package: str
    for package in get_requirements():
        print(f'{package=}')
        if package.startswith('icd_provisioner=='):
            continue
        os.system(f'poetry run pip wheel {package} --wheel-dir {os.path.join("build", "wheels")}')

    f: IO[str]
    with open(os.path.join('data', 'pynsist_cfg_template.txt'), encoding='utf-8') as f:
        pynsist_cfg: str = f.read()
    with open('pynsist.cfg', 'w', encoding='utf-8') as f:
        f.write(pynsist_cfg.format(
            version=get_version(),
            pypi_wheels=f'\n    '.join(get_requirements()),
            python_version=platform.python_version(),
            variant=f'-{os.path.splitext(os.path.basename(args.config))[0]}' if args.config else ''))

    workaround_wheel_name_for_pynsist()
    shutil.copy2(os.path.join('data', 'icon.ico'), 'build')
    os.system('poetry run pip install --upgrade pynsist')

    os.system('poetry run pynsist pynsist.cfg')


def parse_args() -> argparse.Namespace:
    parser: argparse.ArgumentParser = argparse.ArgumentParser()

    parser.add_argument('--config')

    return parser.parse_args()


def main() -> int:
    if not shutil.which('poetry'):
        raise RuntimeError('command "poetry" is missing')

    args: argparse.Namespace = parse_args()
    if args.config:
        if not os.path.isfile(args.config):
            raise FileNotFoundError(f'{args.config} does not exist')
        shutil.copy2(args.config, os.path.join('packages', 'icd_provisioner_desktop', 'config', 'built-in.toml'))

    shutil.rmtree('build', ignore_errors=True)
    os.system('poetry install --no-dev')
    os.system('poetry build')

    if os.name == 'nt':
        pack_for_windows(args)

    return 0


if __name__ == '__main__':
    os.chdir(os.path.dirname(os.path.dirname(os.path.realpath(__file__))))
    sys.exit(main())
