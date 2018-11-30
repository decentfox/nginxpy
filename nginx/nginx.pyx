# cython: language_level=3

cdef extern from "ngx_config.h":
    ctypedef int ngx_int_t

cdef public ngx_int_t nginxpy_init_process():
    return 0

cdef public void nginxpy_exit_process():
    pass
