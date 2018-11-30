from .nginx_core cimport ngx_cycle_t

cdef class Cycle:
    cdef:
        ngx_cycle_t *cycle
        public Log log

    def __init__(self, *args):
        raise NotImplementedError

    @staticmethod
    cdef Cycle from_ptr(ngx_cycle_t *cycle):
        cdef Cycle rv = Cycle.__new__(Cycle)
        rv.cycle = cycle
        rv.log = Log.from_ptr(cycle.log)
        return rv

cdef Cycle current_cycle = None

def get_current_cycle():
    return current_cycle
