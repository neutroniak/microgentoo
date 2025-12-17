import sys
import yaml
from src.atom import Atom
from src.buildah import Buildah
from src.localdev import Localdev

if __name__ == '__main__':

    action = ""

    try:
        action = sys.argv[1]
    except:
        print("usage ./cottage <action>")

    if(action == "containers"):
        with open("config.yaml") as stream:
            try:
                cfg = yaml.safe_load(stream)
            except yaml.YAMLError as yerr:
                print(yerr)

        for c in cfg:
            print(f"building containers from {c}")
            for cc in cfg[c]["containers"]:
               
                print("{} ({}): with packages {}".format(cc, cfg[c]["containers"][cc]["name"], cfg[c]["containers"][cc]["packages"] ))
              
                atoms = []
                for p in cfg[c]["containers"][cc]["packages"]:
                    atom = Atom( p, cfg[c]["containers"][cc], cfg[c] )
                    atom.get_contents()
                    #atom.list_files()
                    atom.end()
                    atoms.append(atom)
                buildah = Buildah()
                buildah.create(atoms, cfg[c]["containers"][cc])

    elif(action == "clean"):
        buildah = Buildah()
        buildah.clean();

    elif(action == "purge"):
        buildah = Buildah()
        buildah.purge()

    elif(action == "localdev"):
       print(action)

