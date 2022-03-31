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
fi