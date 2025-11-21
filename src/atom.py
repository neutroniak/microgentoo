import re
import sys
import os
import portage
import shutil
import mimetypes
import subprocess
import pprint
import tarfile
from pathlib import Path

class Atom:

    def __init__(self, name, cfg, cfgup):
        self.chroot = cfgup["chroot"]
        self.prefix = cfgup["prefix"]
        self.package = cfg["name"];
        self.name = name

        self.prev = os.open("/", os.O_RDONLY)
        os.chroot(self.chroot)

        self.slots = []

    def get_contents(self):

        os.chdir("/")

        p = portage.db[portage.root]["vartree"].dbapi

        hasslot = self.name.split(":")

        sloted = None

        if(len(hasslot)>1):
            sloted = hasslot[1]
            plist = p.cp_list(hasslot[0])
        else:
            plist = p.cp_list(self.name)

        for pl in plist:

            px = p.aux_get(pl, ["CONTENTS"])[0]
            pa = px.split("\n")
            slot = p.aux_get(pl, ["SLOT"])[0]
            version = p.aux_get(pl, ["PV"])[0]
            chost = p.aux_get(pl, ["CHOST"])[0]

            if(sloted != None and slot != sloted):
                continue;

            tmpslot = {"slot":slot, "version":version, "chost":chost, "files":{}}
            for i in pa:
                if re.match("^dir", i) or i == "":
                    continue;

                if re.search(r"usr.share.*.man|usr.share.man|var.run|var.lock|proc|usr.share.info|usr.share.doc|usr.include|.\.h|python.*.test", i) == None:
                    try:
                        cfile = i.split(" ")
                        file = cfile[1]
                        ftype = cfile[0]
                        execx = os.access(file, os.X_OK)
                        mtype = mimetypes.guess_type(file)
                        tmpslot["files"][file] = file;
                        if (mtype[0] == "application/octet-stream" or mtype[0]==None) and execx == True:
                            self.get_ldd(tmpslot, file)
                    except Exception as ex:
                        print(ex)
                        print("err: {}".format(i))

            self.create_tarfile(tmpslot)
            self.slots.append(tmpslot)
        return ""

    def get_ldd(self, slot, pfile):
        popen = subprocess.Popen(["/usr/bin/ldd", pfile], stdout=subprocess.PIPE, stderr=subprocess.PIPE, universal_newlines=True)

        for stdout_line in iter(popen.stdout.readline, ""):
            line = stdout_line.strip()
            soline = stdout_line.strip()

            if soline.find("=>") > -1:
                pos = 1
            else:
                pos = 0
            aso = soline.split("=>")
            soitem = re.sub(r" .*.$","", aso[pos].strip())

            if soitem.find("/") == 0:
                slot["files"][soitem]=soitem

        popen.stdout.close()
        popen.stderr.close()

        return_code = popen.wait()

        return ""

    def list_files(self):

        pp = pprint.PrettyPrinter(indent=1,width=3)

        #pp.pprint(self.files)
        for ff in self.slots:
            pp.pprint(ff)
        return ""

    def create_tarfile(self, slot):
        spl = self.name.split("/")
        fname = "{}_{}_{}.tar".format(spl[1],self.package, slot["version"])
        tar = tarfile.open(fname, "w");
        for s in slot["files"]:
            tar.add(s)
            sym = Path(s)
            if(sym.is_symlink()):
                realfile = sym.resolve()
                tar.add(realfile)
        slot["tarfile"] = fname
        tar.close()
        return ""

    def end(self):
        os.fchdir(self.prev)
        os.chroot(".")
        os.close(self.prev)

