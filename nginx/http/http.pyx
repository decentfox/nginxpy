from cpython cimport Py_INCREF, Py_DECREF
from .nginx_core cimport (
    ngx_log_error,
    NGX_LOG_CRIT,
    NGX_AGAIN,
    from_nginx_str,
    ngx_calloc,
    ngx_free,
    ngx_memcpy,
    ngx_module_t,
    ngx_str_t,
)
from .ngx_http cimport (
    ngx_http_request_t,
    ngx_http_core_run_phases,
    ngx_http_get_module_ctx,
    ngx_http_set_ctx,
    ngx_http_send_header,
    ngx_list_push,
    ngx_table_elt_t,
    ngx_str_set,
    ngx_http_output_filter,
    ngx_chain_t,
    ngx_buf_t,
    ngx_calloc_buf,
)

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
        public str content_type
        public str content_length
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

    def send_header(self):
        return ngx_http_send_header(self.request)

    def add_response_header(self, key, value):
        cdef:
            ngx_table_elt_t *h
            char *cstr
            char *csource
            bytes key_data, value_data
        h = ngx_list_push(&self.request.headers_out.headers)
        if h == NULL:
            raise MemoryError()
        h.hash = 1

        key_data = str(key).encode('iso8859-1')
        cstr = <char *>ngx_calloc(sizeof(char) * len(key_data), self.request.connection.log)
        h.key.len = len(key_data)
        csource = key_data
        ngx_memcpy(cstr, csource, len(key_data))
        h.key.data = cstr

        value_data = str(value).encode('iso8859-1')
        cstr = <char *>ngx_calloc(sizeof(char) * len(value_data), self.request.connection.log)
        h.value.len = len(value_data)
        csource = value_data
        ngx_memcpy(cstr, csource, len(value_data))
        h.value.data = cstr

    def send_response(self, pos):
        cdef:
            ngx_chain_t out
            ngx_buf_t *b
            bytes data = pos
            char* cstr = data
        b = ngx_calloc_buf(self.request.pool)
        if b == NULL:
            raise MemoryError
        b.last_buf = 1
        b.last_in_chain = 1
        b.memory = 1
        b.pos = cstr
        b.last = b.pos + len(data)

        out.buf = b
        out.next = NULL

        return ngx_http_output_filter(self.request, &out)

    def get_app_from_config(self):
        cdef ngx_wsgi_pass_conf_t *conf

        conf = <ngx_wsgi_pass_conf_t *>self.request.loc_conf[ngx_python_module.ctx_index]
        return from_nginx_str(conf.wsgi_pass)

    property response_status:
        def __get__(self):
            return self.request.headers_out.status

        def __set__(self, value):
            self.request.headers_out.status = value

    property response_content_length:
        def __get__(self):
            if self.request.headers_out.content_length:
                return self.request.headers_out.content_length.value

        def __set__(self, value):
            self.request.headers_out.content_length.value = value

    def __repr__(self):
        return f'Request({self.method_name} {self.uri})'

    def __str__(self):
        return f''' request_line: {self.request_line}
           uri: {self.uri}
          args: {self.args}
     extension: {self.extension}
  unparsed_uri: {self.unparsed_uri}
   method_name: {self.method_name}
  content_type: {self.content_type}
content_length: {self.content_length}
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
            if request.headers_in.content_type:
                new_req.content_type = from_nginx_str(
                    request.headers_in.content_type.value)
            if request.headers_in.content_length:
                new_req.content_length = from_nginx_str(
                    request.headers_in.content_length.value)

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
