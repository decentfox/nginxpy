import logging

from .module import load_modules, _modules

log = logging.Logger(__name__)


def init_process():
    log.debug('init_process')

    load_modules()

    for mod in _modules:
        log.debug('init_process: %r', mod)
        mod.init_process()


def exit_process():
    log.debug('exit_process')
    for mod in _modules[::-1]:
        log.debug('exit_process: %r', mod)
        mod.exit_process()
    _modules.clear()
