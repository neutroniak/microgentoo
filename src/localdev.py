import os
import sys

class Localdev:
    def __init__(self, cfg):
        self.cfg = cfg

    def valgrind(self):
        return "valgrind"

    def debug(self):
        return "debug"

