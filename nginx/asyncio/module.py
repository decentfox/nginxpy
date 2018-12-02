import asyncio

from . import log
from .. import NginxEventLoopPolicy
from ..module import BaseModule
from ..hooks import after_init_process


class AsyncioModule(BaseModule):
    def init_process(self):
        log.debug('init_process')
        asyncio.set_event_loop_policy(NginxEventLoopPolicy())
        loop = asyncio.get_event_loop()
        # noinspection PyProtectedMember
        asyncio.events._set_running_loop(loop)
        log.debug('created event loop: %r', loop)
        loop.call_later(0, loop.create_task, after_init_process())

    async def after_init_process(self):
        log.info('Hello, asyncio!')
        await asyncio.sleep(1)
        log.info('Hello, timer!')

    def exit_process(self):
        log.debug('exit_process')
        # noinspection PyProtectedMember
        asyncio.events._set_running_loop(None)
        asyncio.set_event_loop_policy(None)
