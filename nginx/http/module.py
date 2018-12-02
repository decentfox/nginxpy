import asyncio

from . import log
from .._nginx import run_phases
from ..module import BaseModule, ReturnCode
from ..hooks import post_read_async


class HTTPModule(BaseModule):
    def __init__(self):
        self.loop = None

    def init_process(self):
        self.loop = asyncio.get_event_loop()

    def post_read(self, request):
        if request._started():
            log.debug('post_read end')
            return request._result()
        else:
            log.debug('post_read start')
            return request._start(self.loop.create_task(self._handle(request)))

    async def _handle(self, request):
        try:
            return await post_read_async(request)
        finally:
            self.loop.call_soon(run_phases, request)

    async def post_read_async(self, request):
        log.info('Delaying request for 1 second...')
        await asyncio.sleep(1)
        log.info('Now continue with the request')
        return ReturnCode.declined
