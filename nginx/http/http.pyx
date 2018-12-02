from cpython cimport Py_INCREF, Py_DECREF
from .nginx_core cimport ngx_log_error, NGX_LOG_CRIT, NGX_AGAIN
from .ngx_http cimport ngx_http_request_t, ngx_http_core_run_phases
from .ngx_http cimport ngx_http_get_module_ctx, ngx_http_set_ctx

import traceback


cdef class Request:
    cdef:
        ngx_http_request_t *request
        public Log log
        object future

    def __init__(self, *args):
        raise NotImplementedError

    def _started(self):
        return self.future is not None

    def _start(self, fut):
        self.future = fut
        Py_INCREF(self)
        return NGX_AGAIN

    def _result(self):
        if self.future.done():
            Py_DECREF(self)
            ngx_http_set_ctx(self.request, NULL, ngx_python_module)
            return self.future.result()
        return NGX_AGAIN

    @staticmethod
    cdef Request from_ptr(ngx_http_request_t *request):
        cdef:
            void *rv
            Request new_req
        rv = ngx_http_get_module_ctx(request, ngx_python_module)
        if rv == NULL:
            new_req = Request.__new__(Request)
            new_req.request = request
            new_req.log = Log.from_ptr(request.connection.log)
            ngx_http_set_ctx(request, <void *>new_req, ngx_python_module)
            return new_req
        else:
            return <object>rv


cdef public ngx_int_t nginxpy_post_read(ngx_http_request_t *request):
    try:
        from . import hooks
        return hooks.post_read(Request.from_ptr(request))
    except:
        ngx_log_error(NGX_LOG_CRIT, request.connection.log, 0,
                      b'Error occured in post_read:\n' +
                      traceback.format_exc().encode())
        return 500


def run_phases(Request request):
    ngx_http_core_run_phases(request.request)
