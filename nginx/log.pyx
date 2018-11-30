import logging

from .nginx_core cimport ngx_log_error
from .nginx_core cimport (
    NGX_LOG_ALERT,
    NGX_LOG_CRIT,
    NGX_LOG_ERR,
    NGX_LOG_WARN,
    NGX_LOG_INFO,
    NGX_LOG_DEBUG,
)
from .nginx_core cimport ngx_log_t, ngx_uint_t

cdef class Log:
    cdef ngx_log_t *log

    def __init__(self, *args):
        raise NotImplementedError

    @staticmethod
    cdef Log from_ptr(ngx_log_t *log):
        cdef Log rv = Log.__new__(Log)
        rv.log = log
        return rv


class NginxLogHandler(logging.Handler):
    def __init__(self, log):
        super().__init__()
        self._log = log
        self.lock = None

    def emit(self, record):
        cdef ngx_uint_t level = NGX_LOG_ALERT
        if record.levelno == logging.DEBUG:
            level = NGX_LOG_DEBUG
        elif record.levelno == logging.INFO:
            level = NGX_LOG_INFO
        elif record.levelno == logging.WARN:
            level = NGX_LOG_WARN
        elif record.levelno == logging.ERROR:
            level = NGX_LOG_ERR
        elif record.levelno == logging.CRITICAL:
            level = NGX_LOG_CRIT
        ngx_log_error(level, (<Log> self._log).log, 0,
                      '[{}] {}'.format(
                          record.name,
                          record.getMessage()).encode())

    def createLock(self):
        pass


cdef set_last_resort(Log log):
    logging.lastResort = NginxLogHandler(log)
    logging.basicConfig(level=logging.NOTSET,
                        handlers=[logging.lastResort])

cdef unset_last_resort():
    logging.lastResort = logging._defaultLastResort
    logging.root.handlers.clear()
