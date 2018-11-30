from .nginx_config cimport ngx_int_t, ngx_uint_t

cdef extern from "ngx_core.h":
    const ngx_int_t NGX_OK
    const ngx_int_t NGX_ERROR

    const int NGX_LOG_EMERG
    const int NGX_LOG_ALERT
    const int NGX_LOG_CRIT
    const int NGX_LOG_ERR
    const int NGX_LOG_WARN
    const int NGX_LOG_NOTICE
    const int NGX_LOG_INFO
    const int NGX_LOG_DEBUG

    ctypedef int ngx_err_t
    ctypedef int ngx_msec_t

    ctypedef struct ngx_log_t:
        pass

    ctypedef struct ngx_cycle_t:
        ngx_log_t *log

    ctypedef struct ngx_queue_t:
        ngx_queue_t *prev
        ngx_queue_t *next

    void *ngx_calloc(size_t size, ngx_log_t *log)
    void ngx_free(void *p)
    void ngx_log_error(ngx_uint_t level,
                       ngx_log_t *log,
                       ngx_err_t err,
                       const char *fmt)
