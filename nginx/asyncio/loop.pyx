from cpython cimport Py_INCREF, Py_DECREF

from .nginx_core cimport ngx_cycle_t, ngx_calloc, ngx_free
from .nginx_event cimport ngx_event_t, ngx_post_event, ngx_add_timer
from .nginx_event cimport ngx_posted_events

import contextvars
import logging
import time
import traceback
from asyncio import Task, AbstractEventLoopPolicy, Future

log = logging.Logger(__name__)


cdef class Event:
    cdef:
        ngx_event_t *event
        object _callback
        object _args
        object _context

    def __cinit__(self, callback, args, context):
        self.event = <ngx_event_t *> ngx_calloc(sizeof(ngx_event_t),
                                                current_cycle.log.log)
        self.event.log = current_cycle.log.log
        self.event.data = <void *> self
        self.event.handler = self._run
        self._callback = callback
        self._args = args
        if context is None:
            context = contextvars.copy_context()
        self._context = context

    def __dealloc__(self):
        ngx_free(self.event)
        self.event = NULL

    @staticmethod
    cdef void _run(ngx_event_t *ev):
        cdef Event self = <Event> ev.data
        try:
            self._context.run(self._callback, *self._args)
        except Exception as exc:
            traceback.print_exc()
        finally:
            Py_DECREF(self)

    def cancel(self):
        # TODO: XXX
        pass

    cdef call_later(self, float delay):
        ngx_add_timer(self.event, int(delay * 1000))
        Py_INCREF(self)
        return self

    cdef post(self):
        ngx_post_event(self.event, &ngx_posted_events)
        Py_INCREF(self)
        return self


cdef class NginxEventLoop:
    def create_task(self, coro):
        return Task(coro, loop=self)

    def create_future(self):
        return Future(loop=self)

    def time(self):
        return time.monotonic()

    def call_later(self, delay, callback, *args, context=None):
        return Event(callback, args, context).call_later(delay)

    def call_at(self, when, callback, *args, context=None):
        return self.call_later(when - self.time(), callback, *args,
                               context=context)

    def call_soon(self, callback, *args, context=None):
        return Event(callback, args, context).post()

    def get_debug(self):
        return False


class NginxEventLoopPolicy(AbstractEventLoopPolicy):
    def __init__(self):
        self._loop = NginxEventLoop()

    def get_event_loop(self):
        return self._loop

    def set_event_loop(self, loop) -> None:
        pass

    def new_event_loop(self):
        return self._loop
