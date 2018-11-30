from .nginx_config cimport ngx_int_t

cdef extern from "ngx_core.h":
    const ngx_int_t NGX_OK, NGX_ERROR

    ctypedef struct ngx_cycle_t:
        pass
