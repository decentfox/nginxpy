import logging
import pkg_resources

log = logging.Logger(__name__)
_modules = []


class BaseModule:
    def init_process(self):
        pass

    async def after_init_process(self):
        pass

    def exit_process(self):
        pass


def load_modules():
    log.debug('loading modules')
    for ep in pkg_resources.iter_entry_points('nginx', 'module'):
        log.debug('loading %s', ep.module_name)
        mod = ep.load()
        log.debug('installing %s', mod)
        _modules.append(mod())
