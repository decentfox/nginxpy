from cpython cimport Py_INCREF, Py_DECREF
from .nginx_core cimport ngx_log_error, NGX_LOG_CRIT, NGX_AGAIN, from_nginx_str
from .ngx_http cimport ngx_http_request_t, ngx_http_core_run_phases
from .ngx_http cimport ngx_http_get_module_ctx, ngx_http_set_ctx

import traceback


cdef class Request:
    cdef:
        ngx_http_request_t *request
        public Log log
        object future
        public str request_line
        public str uri
        public str args
        public str extension
        public str unparsed_uri
        public str method_name
        public str http_protocol

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

    def __repr__(self):
        return f'Request({self.method_name} {self.uri})'

    def __str__(self):
        return f''' request_line: {self.request_line}
          uri: {self.uri}
         args: {self.args}
    extension: {self.extension}
 unparsed_uri: {self.unparsed_uri}
  method_name: {self.method_name}
http_protocol: {self.http_protocol}'''

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

            new_req.request_line = from_nginx_str(request.request_line)
            new_req.uri = from_nginx_str(request.uri)
            new_req.args = from_nginx_str(request.args)
            new_req.extension = from_nginx_str(request.exten)
            new_req.unparsed_uri = from_nginx_str(request.unparsed_uri)
            new_req.method_name = from_nginx_str(request.method_name)
            new_req.http_protocol = from_nginx_str(request.http_protocol)

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
