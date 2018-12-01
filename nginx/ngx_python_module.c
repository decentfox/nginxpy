#include <ngx_config.h>
#include <ngx_core.h>
#include <Python.h>
#include "nginx.h"


static ngx_int_t ngx_python_init_process(ngx_cycle_t *cycle);
static void ngx_python_exit_process(ngx_cycle_t *cycle);

static wchar_t *python_exec = NULL;


static ngx_core_module_t  ngx_python_module_ctx = {
        ngx_string("python"),
        NULL,
        NULL
};


ngx_module_t  ngx_python_module = {
        NGX_MODULE_V1,
        &ngx_python_module_ctx,                /* module context */
        NULL,                                  /* module directives */
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
