# cython: language_level=3

import traceback

from .nginx_config cimport ngx_int_t
from .nginx_core cimport ngx_cycle_t
from .nginx_core cimport NGX_OK, NGX_ERROR
from .nginx_core cimport NGX_LOG_DEBUG, NGX_LOG_CRIT
from .nginx_core cimport ngx_log_error

from . import hooks

cdef public ngx_int_t nginxpy_init_process(ngx_cycle_t *cycle):
    ngx_log_error(NGX_LOG_DEBUG, cycle.log, 0,
                  b'Starting init_process.')
    # noinspection PyBroadException
    try:
        global current_cycle
        current_cycle = Cycle.from_ptr(cycle)
        set_last_resort(current_cycle.log)
        hooks.init_process()
    except:
        ngx_log_error(NGX_LOG_CRIT, cycle.log, 0,
                      b'Error occured in init_process:\n' +
                      traceback.format_exc().encode())
        return NGX_ERROR
    else:
        ngx_log_error(NGX_LOG_DEBUG, cycle.log, 0,
                      b'Finished init_process.')
        return NGX_OK

cdef public void nginxpy_exit_process(ngx_cycle_t *cycle):
    ngx_log_error(NGX_LOG_DEBUG, cycle.log, 0,
                  b'Starting exit_process.')
    # noinspection PyBroadException
    try:
        global current_cycle
        hooks.exit_process()
        unset_last_resort()
        current_cycle = None
    except:
        ngx_log_error(NGX_LOG_CRIT, cycle.log, 0,
                      b'Error occured in exit_process:\n' +
                      traceback.format_exc().encode())
    else:
        ngx_log_error(NGX_LOG_DEBUG, cycle.log, 0,
                      b'Finished exit_process.')

include "log.pyx"
include "cycle.pyx"
include "asyncio/loop.pyx"
