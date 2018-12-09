from .nginx_core cimport ngx_str_t, ngx_module_t, ngx_log_t, ngx_uint_t, ngx_int_t


cdef extern from "ngx_http.h":

    ctypedef struct ngx_table_elt_t:
        ngx_uint_t hash
        ngx_str_t key
        ngx_str_t value

    ctypedef struct ngx_list_t:
        pass

    ctypedef struct ngx_http_headers_in_t:
        ngx_table_elt_t *content_type
        ngx_table_elt_t *content_length

    ctypedef struct ngx_http_headers_out_t:
        ngx_uint_t status
        ngx_table_elt_t *content_length
        ngx_list_t headers

    ctypedef struct ngx_chain_t:
        ngx_buf_t *buf
        ngx_chain_t *next

    ctypedef struct ngx_buf_t:
        unsigned last_buf
        unsigned last_in_chain
        unsigned memory
        char *pos
        char *last

    ctypedef struct ngx_pool_t:
        pass

    ctypedef struct ngx_connection_t:
        ngx_log_t *log

    ctypedef struct ngx_http_request_t:
        ngx_connection_t *connection
        ngx_str_t request_line
        ngx_str_t uri
        ngx_str_t args
        ngx_str_t exten
        ngx_str_t unparsed_uri
        ngx_str_t method_name
        ngx_str_t http_protocol
        ngx_pool_t *pool
        ngx_http_headers_in_t headers_in
        ngx_http_headers_out_t headers_out
        void **loc_conf

    void ngx_http_core_run_phases(ngx_http_request_t *request)
    void *ngx_http_get_module_ctx(ngx_http_request_t *request,
                                  ngx_module_t module)
    void ngx_http_set_ctx(ngx_http_request_t *request, void *ctx,
                          ngx_module_t module)

    void ngx_http_send_header(ngx_http_request_t *r)

    ngx_table_elt_t *ngx_list_push(ngx_list_t *list)

    void ngx_str_set(ngx_str_t *str, char *text)

    ngx_int_t ngx_http_output_filter(ngx_http_request_t *r, ngx_chain_t *input)

    ngx_buf_t *ngx_calloc_buf(ngx_pool_t *pool)


