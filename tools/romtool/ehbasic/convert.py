#!/usr/bin/python

import sys, getopt
import os

def Quartus(filename):
    f = open(filename+".bin", 'rb')
    out = open(filename+".hex", 'w')

    d = f.read()
    for i in d:
        out.write('{0:02X}\n'.format(ord(i)))
    out.close()
    f.close()

def main(argv):
    if len(argv) == 0:
        return

    Quartus(argv[0])

if __name__ == "__main__":
   main(sys.argv[1:])
