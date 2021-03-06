import importlib
import itertools
import os
import platform
import subprocess

from IPython.core.magic import Magics, cell_magic, line_magic, magics_class
from IPython.core.magic_arguments import (argument, magic_arguments,
                                          parse_argstring)
from pip._internal.utils.misc import get_installed_distributions

try:
    from isort import SortImports
    isort = True
except:  # noqa: E722
    isort = False


@magics_class
class CustomMagics(Magics):

    @magic_arguments()
    @argument('-v', '--verbose', action='store_true',
              help='perform verbose installation')
    @argument('pkg', type=str, help='Package to install')
    @line_magic
    def install(self, line):
        """Install a package locally."""
        args = parse_argstring(self.install, line)
        opts = os.getenv("EXTRA_PIP_OPTS", "")
        cmd = "pip install -U --user {} {}".format(args.pkg, opts)
        a = subprocess.run(cmd,
                           shell=True, stdout=subprocess.PIPE,
                           stderr=subprocess.PIPE)
        if a.returncode == 0:
            if args.verbose:
                print(a.stdout.decode())
        else:
            print(a.stderr.decode())

    @magic_arguments()
    @argument('-p', '--packages', nargs='+', type=str,
              help='List of packages')
    @line_magic
    def info_versions(self, line):
        def _pprint(key, val):
            print("{:30s}: {}".format(key, val))

        _pprint("Python", "{} {} {}".format(platform.python_version(),
                                            platform.architecture()[0],
                                            platform.python_compiler()))
        _pprint("OS", platform.platform().replace('-', ' '))
        print()
        args = parse_argstring(self.info_versions, line)
        packages = args.packages
        if not packages:
            packages = ['numpy', 'scipy', 'matplotlib', 'sklearn',
                        'pandas', 'astropy', 'tensorflow']
        res = {}
        for pkg in sorted(packages):
            try:
                version = importlib.__import__(pkg)
            except:
                res[pkg] = 'Package not found'
            else:
                try:
                    res[pkg] = version.__version__
                except:
                    res[pkg] = None

        for k in res:
            _pprint(k, res[k])

    @line_magic
    def list_packages(self, line):
        installed_packages = get_installed_distributions()
        installed_packages_list = sorted(["\033[95m%s\033[0m==%s" % (i.key, i.version)
                                          for i in installed_packages if len(i.key) < 20])
        res = [installed_packages_list[3 * i:3 * (i + 1)]
               for i in range(len(installed_packages_list) // 3 + 1)]
        for r in res:
            print(''.join([*map(lambda x: f'{x:40s}', r)]))


if __name__ == '__main__':
    from IPython import get_ipython
    get_ipython().register_magics(CustomMagics)
