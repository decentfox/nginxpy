# cython: language_level=3

from .nginx_config cimport ngx_int_t
from .nginx_core cimport ngx_cycle_t, NGX_OK

cdef public ngx_int_t nginxpy_init_process(ngx_cycle_t *cycle):
    return NGX_OK

cdef public void nginxpy_exit_process(ngx_cycle_t *cycle):
    pass
