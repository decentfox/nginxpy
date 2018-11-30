#include <ngx_config.h>
#include <ngx_core.h>
#include <Python.h>
#include "nginx.h"


typedef struct {
    ngx_flag_t  enable;
} ngx_python_conf_t;


static void *ngx_python_create_conf(ngx_cycle_t *cycle);
static char *ngx_python_init_conf(ngx_cycle_t *cycle, void *conf);
static ngx_int_t ngx_python_init_process(ngx_cycle_t *cycle);
static void ngx_python_exit_process(ngx_cycle_t *cycle);

static char *ngx_python_enable(ngx_conf_t *cf, void *post, void *data);
static ngx_conf_post_t  ngx_python_enable_post = { ngx_python_enable };
static wchar_t *python_exec = NULL;

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
        ngx_python_init_process,               /* init process */
        NULL,                                  /* init thread */
        NULL,                                  /* exit thread */
        ngx_python_exit_process,               /* exit process */
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

static ngx_int_t
ngx_python_init_process(ngx_cycle_t *cycle) {
    if (python_exec == NULL) {
        python_exec = Py_DecodeLocale(PYTHON_EXEC, NULL);
        if (python_exec == NULL) {
            ngx_log_error(NGX_LOG_CRIT, cycle->log, 0,
                          "Could not decode Python executable path.");
            return NGX_ERROR;
        }
    }
    Py_SetProgramName(python_exec);
    if (PyImport_AppendInittab("nginx._nginx", PyInit__nginx) == -1) {
        ngx_log_error(NGX_LOG_CRIT, cycle->log, 0,
                      "Could not initialize nginxpy extension.");
        return NGX_ERROR;
    }
    ngx_log_error(NGX_LOG_NOTICE, cycle->log, 0,
                  "Initializing Python...");
    Py_Initialize();
    if (PyImport_ImportModule("nginx._nginx") == NULL) {
        ngx_log_error(NGX_LOG_CRIT, cycle->log, 0,
                      "Could not import nginxpy extension.");
        return NGX_ERROR;
    }
    return nginxpy_init_process(cycle);
}

static void
ngx_python_exit_process(ngx_cycle_t *cycle) {
    nginxpy_exit_process(cycle);
    ngx_log_error(NGX_LOG_NOTICE, cycle->log, 0,
                  "Finalizing Python...");
    if (Py_FinalizeEx() < 0) {
        ngx_log_error(NGX_LOG_CRIT, cycle->log, 0,
                      "Failed to finalize Python!");
    }
}
