import logging
import pkg_resources

from . import ReturnCode

log = logging.Logger(__name__)
_modules = []


class BaseModule:
    def init_process(self):
        pass

    async def after_init_process(self):
        pass

    def exit_process(self):
        pass

    def post_read(self, request):
        return ReturnCode.declined


def load_modules():
    log.debug('loading modules')
    endpoints = [ep for d in pkg_resources.working_set for ep in
                 d.get_entry_map('nginx.modules').values()]
    endpoints.sort(key=lambda ep: ep.name)
    for ep in endpoints:
        log.info('loading %s', ep.module_name)
        mod = ep.load()
        log.info('installing %s', mod)
        _modules.append(mod())
