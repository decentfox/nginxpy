import asyncio
import logging

from .. import NginxEventLoopPolicy
from ..module import BaseModule

log = logging.Logger(__name__)


class AsyncioModule(BaseModule):
    def init_process(self):
        log.debug('init_process')
        asyncio.set_event_loop_policy(NginxEventLoopPolicy())
        loop = asyncio.get_event_loop()
        # noinspection PyProtectedMember
        asyncio.events._set_running_loop(loop)
        log.debug('created event loop: %r', loop)
        loop.call_later(0, loop.create_task, main())

    def exit_process(self):
        log.debug('exit_process')
        # noinspection PyProtectedMember
        asyncio.events._set_running_loop(None)
        asyncio.set_event_loop_policy(None)


async def main():
    log.info('Hello, asyncio!')
    await asyncio.sleep(1)
    log.info('Hello, timer!')
