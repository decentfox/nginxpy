import asyncio
import io
import sys
import functools

from . import log
from .._nginx import run_phases
from ..module import BaseModule, ReturnCode
from ..hooks import post_read_async


class HTTPModule(BaseModule):
    def __init__(self):
        self.loop = None

    def init_process(self):
        self.loop = asyncio.get_event_loop()

    def start_response(self, request, status, response_headers, exc_info=None):
        request.response_status = int(status.split(maxsplit=1)[0])
        for key, value in response_headers:
            request.add_response_header(key, value)

    def post_read(self, request):
        environ = {
            'REQUEST_METHOD': request.method_name,
            'SCRIPT_NAME': None,
            'PATH_INFO': request.uri,
            'QUERY_STRING': request.args,
            'CONTENT_TYPE': request.content_type,
            'CONTENT_LENGTH': request.content_length,
            'SERVER_NAME': 'localhost',
            'SERVER_PORT': '8080',
            'SERVER_PROTOCOL': request.http_protocol,
            'wsgi.input': io.BytesIO(),
            'wsgi.errors': sys.stderr,
            'wsgi.version': (1, 0),
            'wsgi.multithread': False,
            'wsgi.multiprocess': True,
            'wsgi.run_once': True,
        }
        if environ.get('HTTPS', 'off') in ('on', '1'):
            environ['wsgi.url_scheme'] = 'https'
        else:
            environ['wsgi.url_scheme'] = 'http'
        app_name = request.get_app_from_config()
        module_name, method_name = app_name.split(':')
        app = getattr(__import__(module_name), method_name)
        resp = app(environ, functools.partial(
            self.start_response, request))
        request.send_header()
        rv = 404
        for pos in resp:
            rv = request.send_response(pos)
        return rv
        # if request._started():
        #     log.debug('post_read end')
        #     return request._result()
        # else:
        #     log.debug('post_read request:\n%s', request)
        #     return request._start(self.loop.create_task(
        #         self._post_read_async(request)))

    async def _post_read_async(self, request):
        try:
            return await post_read_async(request)
        finally:
            self.loop.call_soon(run_phases, request)

    async def post_read_async(self, request):
        log.info('Delaying request for 1 second...')
        await asyncio.sleep(1)
        log.info('Now continue with the request')
        return ReturnCode.declined
