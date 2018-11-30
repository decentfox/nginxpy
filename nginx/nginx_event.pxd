from .nginx_core cimport ngx_queue_t, ngx_msec_t, ngx_log_t

cdef extern from "ngx_event.h":
    ctypedef void (*ngx_event_handler_pt)(ngx_event_t *ev)

    ctypedef struct ngx_event_t:
        void *data
        ngx_event_handler_pt handler
        ngx_queue_t queue
        ngx_log_t *log
    ngx_queue_t ngx_posted_events

    void ngx_post_event(ngx_event_t *ev, ngx_queue_t *q)
    void ngx_add_timer(ngx_event_t *ev, ngx_msec_t timer)

