#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""Tests for `nginxpy` package."""


import os
import unittest

import nginx


class TestNginxpy(unittest.TestCase):
    def test_extension(self):
        self.assertTrue(hasattr(nginx, 'spec'))
        self.assertTrue(os.path.exists(nginx.spec.origin))
