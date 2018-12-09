extern ngx_module_t ngx_python_module;

typedef struct {
    ngx_str_t  wsgi_pass;
} ngx_wsgi_pass_conf_t;
