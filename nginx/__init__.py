# -*- coding: utf-8 -*-

"""Top-level package for NGINXpy."""

__author__ = """DecentFoX Studio"""
__email__ = 'foss@decentfox.com'
__version__ = '0.1.0'

try:
    from ._nginx import (
        Cycle, Log, get_current_cycle,
        NginxEventLoop, NginxEventLoopPolicy, Event,
    )
except ImportError:
    import sys
    from os.path import abspath, dirname
    from importlib.util import find_spec
    spec = find_spec('nginx._nginx')

    if spec and ('' not in sys.path or
                 abspath(dirname(spec.origin)) != abspath(dirname(__file__))):
        print('Cannot import nginx, should load in nginx.conf first:')
        print()
        print(f'    load_module {spec.origin};')
        print(f'    python_enabled on;')
        print()
    elif '' in sys.path:
        sys.modules.pop('nginx')
        sys.path.remove('')
        __import__('nginx')
    else:
        print('Cannot import nginx, please check installation.')
