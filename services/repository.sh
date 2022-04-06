#!/bin/bash
#
#   Abhandlung von Repositories - clone und run scripts/install.sh

cd $HOME
git clone $1

repo=$(basename $1)

if  [ -d ${repo} ]
then

    cd ${repo}
    bash -x scripts/install.sh
    
    # Dateien fuer Willkommenseite aufbereiten
    [ -f README.md ] && [ cp README.md /home/ubuntu/; ]
    [ -f ACCESSING.md ] && [ cp ACCESSING.md /home/ubuntu/; ]
    [ -f SERVICES.md ] && [ cp SERVICES.md /home/ubuntu/; ]
fi