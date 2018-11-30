=======
NGINXpy
=======


.. image:: https://img.shields.io/pypi/v/nginxpy.svg
        :target: https://pypi.python.org/pypi/nginxpy

.. image:: https://img.shields.io/travis/decentfox/nginxpy.svg
        :target: https://travis-ci.org/decentfox/nginxpy

.. image:: https://readthedocs.org/projects/nginxpy/badge/?version=latest
        :target: https://nginxpy.readthedocs.io/en/latest/?badge=latest
        :alt: Documentation Status


.. image:: https://pyup.io/repos/github/decentfox/nginxpy/shield.svg
     :target: https://pyup.io/repos/github/decentfox/nginxpy/
     :alt: Updates



Embed Python in NGINX.


* Free software: Apache Software License 2.0
* Documentation: https://nginxpy.readthedocs.io.


Features
--------

* Standard Python package with Cython extension
* Automatically build into NGINX dynamic module for current NGINX install
* Run embeded Python in NGINX worker processes
* Write NGINX modules in Python or Cython
* Python ``logging`` module redirected to NGINX ``error.log``
* (ongoing) NGINX event loop wrapped as Python ``asyncio`` interface
* (TBD) Python and Cython interface to most NGINX code
* (TBD) Adapt NGINX web server to WSGI, ASGI and aiohttp interfaces


Installation
------------

1. Install NGINX in whatever way, make sure ``nginx`` command is available.
2. ``pip install nginxpy``, or get the source and run ``pip install .``. You
   may want to add the ``-v`` option, because the process is a bit slow
   downloading Cython, NGINX source code and configuring it. The usual ``python
   setup.py install`` currently doesn't work separately - you should run
   ``python setup.py build`` first.
3. Run ``python -c 'import nginx'`` to get NGINX configuration hint.
4. Update NGINX configuration accordingly and reload NGINX.
5. See NGINX ``error.log`` for now.


Development
-----------

1. Install NGINX in whatever way, make sure ``nginx`` command is available.
2. Checkout source code.
3. Run ``python setup.py build`` and ``python setup.py develop``.
4. Run ``python -c 'import nginx'`` to get NGINX configuration hint.
5. Update NGINX configuration accordingly and reload NGINX.
6. See NGINX ``error.log`` for now.


Credits
-------

This package was created with Cookiecutter_ and the `audreyr/cookiecutter-pypackage`_ project template.

.. _Cookiecutter: https://github.com/audreyr/cookiecutter
.. _`audreyr/cookiecutter-pypackage`: https://github.com/audreyr/cookiecutter-pypackage
