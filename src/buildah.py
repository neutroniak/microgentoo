import subprocess
import os
import tarfile
import mimetypes
import tarfile
import sys
import stat
from pathlib import Path
import shutil

class Buildah:

    def __init__(self):
        self.container = "x"

    def create(self, atoms, cfg):
        sub = subprocess.run(["buildah", "from", "scratch"], capture_output=True, text=True)
        basect = "{}".format(sub.stdout.strip())
        m = self.mount(basect)

        for atom in atoms:
            envdir = atom.chroot
            prefix = atom.prefix
            os.chdir(envdir)
            for f in atom.slots:
                tfile = tarfile.open("{}/{}".format(atom.chroot, f["tarfile"]));
                tfile.extractall(m)
                version = f["version"]
        try:
            os.mkdir("{}/tmp".format(m))
            os.mkdir("{}/var".format(m))
            os.mkdir("{}/run".format(m))
            os.mkdir("{}/root".format(m))
            os.mkdir("{}/dev".format(m))
            os.mkdir("{}/run/lock".format(m))
            os.symlink("../run", "{}/var/run".format(m) )
            os.symlink("../run/lock", "{}/var/lock".format(m) )
            os.chmod("{}/tmp".format(m), 0o777)
            shutil.copy("{}/etc/ld.so.conf".format(atom.chroot), "{}/etc/".format(m))
            shutil.copy("{}/etc/ld.so.cache".format(atom.chroot), "{}/etc/".format(m))
            shutil.copy("{}/etc/profile.env".format(atom.chroot), "{}/etc/".format(m))
            shutil.copytree("{}/etc/ld.so.conf.d".format(atom.chroot), "{}/etc/ld.so.conf.d/".format(m), dirs_exist_ok=True)
            shutil.copytree("{}/etc/profile.d".format(atom.chroot), "{}/etc/profile.d".format(m), dirs_exist_ok=True)
            shutil.copytree("{}/etc/env.d".format(atom.chroot), "{}/etc/env.d".format(m), dirs_exist_ok=True)
        except Exception as ex:
            print(ex)
        self.umount(basect)
        name = "{}/{}:{}".format(prefix, cfg["name"], version)
        self.commit(basect, name)
        self.rm(basect)
        return 1 

    def copy(self, container, src, dest):
        sub = subprocess.run(["buildah", "copy", container, src, dest], capture_output=True, text=True)
        print(sub.stdout.strip())
        return 1

    def commit(self, container, name):
        sub = subprocess.run(["buildah", "commit", container, name], capture_output=True, text=True)
        print(sub.stdout.strip())
        return 1

    def rm(self, container):
        sub = subprocess.run(["buildah", "rm", container], capture_output=True, text=True)
        print(sub.stdout.strip())
        sub = subprocess.run(["buildah", "rmi", "--prune"], capture_output=True, text=True) 
        return 1

    def run(self, container, cmd):
        c = ["buildah", "run", "-t", container, "--"]
        c = c+cmd
        sub = subprocess.run(c, capture_output=True, text=True)
        print(sub.stdout.strip())
        return 1

    def mount(self, container):
        sub = subprocess.run(["buildah", "mount", container], capture_output=True, text=True)
        return sub.stdout.strip()

    def umount(self, container):
        sub = subprocess.run(["buildah", "umount", container], capture_output=True, text=True)

    def clean(self):
        sub = subprocess.run(["buildah", "rmi", "--prune"])

    def purge(self):
        sub = subprocess.run(["buildah", "rmi", "-a"])

