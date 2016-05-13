#!/usr/bin/env python

import subprocess
import os
import sys
import argparse
from subprocess import PIPE, STDOUT

null = open("/dev/null", "wb")

def wait(p):
    rc = p.wait()
    if rc != 0:
        p = play("sound/misc/compiler-failure.ogg")
        p.wait()
        assert p.returncode == 0
        sys.exit(rc)

def play(soundfile):
    p = subprocess.Popen(["play", soundfile], stdout=null, stderr=null)
    assert p.wait() == 0
    return p

def stage1():
    p = subprocess.Popen("(cd tgui; /bin/bash ./build.sh)", shell=True)
    wait(p)
    play("sound/misc/compiler-stage1.ogg")

def stage2():
    p = subprocess.Popen("DreamMaker tgstation.dme", shell=True)
    wait(p)

def stage3():
    play("sound/misc/compiler-stage2.ogg")
    logfile = open('server.log~','w')
    p = subprocess.Popen(
        "DreamDaemon tgstation.dmb 25001 -trace -trusted",
        shell=True, stdout=PIPE, stderr=STDOUT)
    while p.returncode is None:
        try:
            stdout = p.stdout.readline()
            t = "Initializations complete."
            if t in stdout:
                play("sound/misc/server-ready.ogg")
            sys.stdout.write(stdout)
            sys.stdout.flush()
        finally:
            logfile.flush()
            os.fsync(logfile.fileno())

if __name__=='__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('-s','---stage',default=1,type=int)
    args = parser.parse_args()
    stage = args.stage
    assert stage in (1,2,3)
    if stage == 1:
        stage1()
        stage = 2
    if stage == 2:
        stage2()
        stage = 3
    if stage == 3:
        stage3()
