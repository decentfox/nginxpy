#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""Tests for `nginxpy` package."""

import re
import subprocess
import tempfile
import unittest
from os.path import exists, abspath

import nginx

CONF_OK = re.compile(r'configuration file ([^ ]+) test is successful')


class TestNginxpy(unittest.TestCase):
    def test_extension(self):
        self.assertTrue(hasattr(nginx, 'spec'))
        self.assertTrue(exists(nginx.spec.origin))

        with tempfile.NamedTemporaryFile('w') as f:
            f.write('error_log stderr;pid ')
            with tempfile.NamedTemporaryFile() as pid:
                f.write(abspath(pid.name))
            f.write(';load_module ')
            f.write(nginx.spec.origin)
            f.write(';events {}')
            f.flush()
            subprocess.check_call(['nginx', '-c', abspath(f.name), '-t'])
