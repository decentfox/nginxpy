import asyncio
import logging

from .module import load_modules, _modules

log = logging.Logger(__name__)


def init_process():
    log.debug('init_process')

    load_modules()

    for mod in _modules:
        log.debug('init_process: %r', mod)
        mod.init_process()


async def after_init_process():
    log.debug('after_init_process')
    loop = asyncio.get_event_loop()
    tasks = []
    for mod in _modules:
        log.debug('after_init_process: %r', mod)
        tasks.append(loop.create_task(mod.after_init_process()))
    await asyncio.wait(tasks)


def exit_process():
    log.debug('exit_process')
    for mod in _modules[::-1]:
        log.debug('exit_process: %r', mod)
        mod.exit_process()
    _modules.clear()
