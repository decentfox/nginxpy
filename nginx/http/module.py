import asyncio
import logging

from .._nginx import run_phases
from ..module import BaseModule, ReturnCode

log = logging.getLogger(__name__)


class HTTPModule(BaseModule):
    def __init__(self):
        self.loop = None

    def init_process(self):
        self.loop = asyncio.get_event_loop()

    def post_read(self, request):
        if request._started():
            return request._result()
        else:
            return request._start(self.loop.create_task(self._handle(request)))

    async def _handle(self, request):
        try:
            log.info('Handling request...')
            await asyncio.sleep(1)
            log.info('Done')
            return ReturnCode.declined
        finally:
            self.loop.call_soon(run_phases, request)
