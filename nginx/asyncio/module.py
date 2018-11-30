import logging

from ..module import BaseModule

log = logging.Logger(__name__)


class AsyncioModule(BaseModule):
    def init_process(self):
        log.debug('init_process')

    def exit_process(self):
        log.debug('exit_process')
