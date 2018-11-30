#include <ngx_config.h>
#include <ngx_core.h>


typedef struct {
    ngx_flag_t  enable;
} ngx_python_conf_t;


static void *ngx_python_create_conf(ngx_cycle_t *cycle);
static char *ngx_python_init_conf(ngx_cycle_t *cycle, void *conf);

static char *ngx_python_enable(ngx_conf_t *cf, void *post, void *data);
static ngx_conf_post_t  ngx_python_enable_post = { ngx_python_enable };


static ngx_command_t  ngx_python_commands[] = {

        { ngx_string("python_enabled"),
          NGX_MAIN_CONF|NGX_DIRECT_CONF|NGX_CONF_FLAG,
          ngx_conf_set_flag_slot,
          0,
          offsetof(ngx_python_conf_t, enable),
          &ngx_python_enable_post },

        ngx_null_command
};


static ngx_core_module_t  ngx_python_module_ctx = {
        ngx_string("python"),
        ngx_python_create_conf,
        ngx_python_init_conf
};


ngx_module_t  ngx_python_module = {
        NGX_MODULE_V1,
        &ngx_python_module_ctx,                   /* module context */
        ngx_python_commands,                      /* module directives */
        NGX_CORE_MODULE,                       /* module type */
        NULL,                                  /* init master */
        NULL,                                  /* init module */
        NULL,                                  /* init process */
        NULL,                                  /* init thread */
        NULL,                                  /* exit thread */
        NULL,                                  /* exit process */
        NULL,                                  /* exit master */
        NGX_MODULE_V1_PADDING
};


static void *
ngx_python_create_conf(ngx_cycle_t *cycle)
{
    ngx_python_conf_t  *fcf;

    fcf = ngx_pcalloc(cycle->pool, sizeof(ngx_python_conf_t));
    if (fcf == NULL) {
        return NULL;
    }

    fcf->enable = NGX_CONF_UNSET;

    return fcf;
}


static char *
ngx_python_init_conf(ngx_cycle_t *cycle, void *conf)
{
    ngx_python_conf_t *fcf = conf;

    ngx_conf_init_value(fcf->enable, 0);

    return NGX_CONF_OK;
}


static char *
ngx_python_enable(ngx_conf_t *cf, void *post, void *data)
{
    ngx_flag_t  *fp = data;

    if (*fp == 0) {
        return NGX_CONF_OK;
    }

    ngx_log_error(NGX_LOG_NOTICE, cf->log, 0, "Python Module is enabled");

    return NGX_CONF_OK;
}
