import datetime
import shutil
import subprocess
import psutil
from pathlib import Path

def date(format="%Y%m%d"):
    return datetime.datetime.utcnow().strftime(format)

def kill_process(pid):
    try:
        proc = psutil.Process(pid)
        print("killing ", proc.name())
        proc.kill()
    except psutil.NoSuchProcess as ex:
        print("({pid}}) - no such process")

def make_dir(dirname) -> Path:
    today = date("%Y%m%d")
    odir = Path(".")/dirname
    odir.mkdir(exist_ok=True)
    return odir

def run_ls():
    subprocess.call(['/bin/ls', '-lSt'])
    subprocess.check_output(['echo', '$?'], shell=True)

def diff(f1, f2):
    pipe = subprocess.Popen(['diff', '-u', f1, f2], stdout=subprocess.PIPE)
    output = pipe.stdout

def dmesg():
    msg = subprocess.Popen(['dmesg'], stdout=PIPE)
    print(msg.communicate())

if __name__ == "__main__":
    dt = date()
    print(dt)
    make_dir("test")
    run_ls()
    diff('a','b')
