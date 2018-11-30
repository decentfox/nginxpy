#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""The setup script."""

import os
import re
import subprocess
import sys
import sysconfig
from distutils.command.build import build
from urllib.request import urlretrieve
from setuptools import setup, find_packages, Extension

with open('README.rst') as readme_file:
    readme = readme_file.read()

with open('HISTORY.rst') as history_file:
    history = history_file.read()

requirements = []

test_requirements = []


class nginxpy_build(build):
    def run(self):
        print('checking current NGINX install')
        nginx_bin = subprocess.getoutput('which nginx')
        nginx_ver = subprocess.getoutput(nginx_bin + ' -v')
        nginx_ver = re.findall(r'nginx/([\d\.]+)', nginx_ver)[0]
        print(nginx_ver, '@', nginx_bin)

        print('checking NGINX configure parameters')
        nginx_params = subprocess.getoutput(nginx_bin + ' -V')
        nginx_params = re.findall(r'configure arguments: (.*)',
                                  nginx_params)[0]

        def filter_params(params):
            params = iter(params)
            try:
                while True:
                    val = next(params)
                    if val.startswith('--add-dynamic-module'):
                        if val == '--add-dynamic-module':
                            next(params)
                    else:
                        yield val
            except StopIteration:
                pass

        nginx_params = list(filter_params(nginx_params.split()))
        print(' '.join(nginx_params))

        print('updating NGINX source')
        build_base = os.path.abspath(self.build_base)
        if not os.path.exists(build_base):
            os.mkdir(build_base)
        nginx_src = os.path.join(build_base, 'nginx-' + nginx_ver)
        nginx_tarball = os.path.join(build_base,
                                     'nginx-' + nginx_ver + '.tar.gz')
        nginx_url = 'https://nginx.org/download/nginx-{}.tar.gz'.format(
            nginx_ver)
        if os.path.exists(nginx_src):
            print('reusing', nginx_src)
        else:
            if os.path.exists(nginx_tarball):
                print('reusing', nginx_tarball)
            else:
                print('downloading', nginx_url)
                urlretrieve(nginx_url, nginx_tarball)
            print('extracting tarball')
            subprocess.check_call(['tar', 'xvf', nginx_tarball,
                                   '-C', build_base])

        print('retrieving NGINX build options')
        nginx_configure = os.path.join(nginx_src, 'configure')
        nginx_make = os.path.join(nginx_src, 'objs', 'Makefile')
        if os.path.exists(nginx_make):
            print('reusing', nginx_make)
        else:
            print('configuring NGINX')
            src_dir = os.path.join(os.path.abspath(os.path.dirname(__file__)), 'nginx')
            cmd = (' '.join([nginx_configure] + nginx_params +
                                  ['--add-dynamic-module=' + src_dir]))
            subprocess.check_call([cmd],
                                  cwd=nginx_src, shell=True)
            with open(nginx_make, 'a') as f:
                f.write('\n')
                f.write('print-%  : ; @echo $* = $($*)')
                f.write('\n')
        nginx_cflags = subprocess.getoutput(
            'make -f ' + nginx_make + ' print-CFLAGS')
        nginx_cflags = re.findall(r'CFLAGS = (.*)', nginx_cflags)[0].split()
        nginx_cflags = list(filter(lambda x: x != '-Werror', nginx_cflags))
        nginx_all_incs = subprocess.getoutput(
            'make -f ' + nginx_make + ' print-ALL_INCS')
        nginx_all_incs = re.findall(r'ALL_INCS = (.*)', nginx_all_incs)[0]
        nginx_all_incs = list(map(lambda x: os.path.join(nginx_src, x),
                                  filter(lambda x: x != '-I',
                                         nginx_all_incs.split())))
        if subprocess.getoutput('grep fPIC ' + nginx_make):
            nginx_cflags.append('-fPIC')
        print('NGINX CFLAGS:', ' '.join(nginx_cflags))
        print('NGINX ALL_INCS:', ' '.join(nginx_all_incs))

        nginxpy.include_dirs.extend(nginx_all_incs)
        nginxpy.extra_compile_args.extend(nginx_cflags)

        print('retrieving Python link options')
        pyver = sysconfig.get_config_var('VERSION')
        getvar = sysconfig.get_config_var
        libs = ['-lpython' + pyver + sys.abiflags]
        libs += getvar('LIBS').split()
        libs += getvar('SYSLIBS').split()
        # add the prefix/lib/pythonX.Y/config dir, but only if there is no
        # shared library in prefix/lib/.
        if not getvar('Py_ENABLE_SHARED'):
            libs.insert(0, '-L' + getvar('LIBPL'))
        if not getvar('PYTHONFRAMEWORK'):
            libs.extend(getvar('LINKFORSHARED').split())
        libs = list(filter(lambda x: 'stack_size' not in x, libs))

        print('link options:', ' '.join(libs))
        nginxpy.extra_link_args.extend(libs)

        super().run()


nginxpy = Extension(
    'nginx._nginx',
    sources=[
        'nginx/ngx_python_module.c',
        'nginx/ngx_python_module_modules.c',
        'nginx/nginx.pyx',
    ], define_macros=[
        ('PYTHON_EXEC', '"{}"'.format(os.path.abspath(sys.executable))),
    ], depends=[
        'nginx/cycle.pyx',
        'nginx/log.pyx',
        'nginx/asyncio/loop.pyx',
    ])

setup(
    author="DecentFoX Studio",
    author_email='foss@decentfox.com',
    classifiers=[
        'Development Status :: 2 - Pre-Alpha',
        'Intended Audience :: Developers',
        'License :: OSI Approved :: Apache Software License',
        'Natural Language :: English',
        'Programming Language :: Python :: 3',
        'Programming Language :: Python :: 3.7',
    ],
    description="Embed Python in NGINX.",
    install_requires=requirements,
    license="Apache Software License 2.0",
    long_description=readme + '\n\n' + history,
    include_package_data=True,
    keywords='nginxpy',
    name='nginxpy',
    packages=find_packages(include=['nginx', 'nginx.asyncio']),
    ext_modules=[nginxpy],
    cmdclass=dict(build=nginxpy_build),
    entry_points='''\
    [nginx]
    module = nginx.asyncio:AsyncioModule
    ''',
    test_suite='tests',
    tests_require=test_requirements,
    url='https://github.com/decentfox/nginxpy',
    version='0.1.0',
    zip_safe=False,
)
