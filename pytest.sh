#!/bin/bash

#
# 16/10/2023.
#
# A generic script which create a clean virtual environment and run pytest.
#
# Intended to be used in a Jenkins GitHub project Pipeline as:
#
#    sh("${JENKINS_HOME}/scripts/pytest.sh ${WORKSPACE}")
#
# The repo is cloned automatically by Jenkins. This script does the followings:
#
#   1. If virtual directory ${WORKSPACE}/venv exists, remove all of it.
#
#   2. Create virtual environment ${WORKSPACE}/venv, then activate it.
#
#   3. Run editable install for the project.
#
#   4. Finally run pytest.
#

if [ -z $1 ]; then
    echo "Usage: ${0##*/} <dir>"
    exit 1
fi

if [ ! -d $1 ]; then
    echo "$1 does not exist."
    exit 1
fi

virtual_dir=$1/venv

echo "Virtual directory $virtual_dir."

if [ -d $virtual_dir ]; then
    rm -rf $virtual_dir
    echo "$virtual_dir removed."
fi

python3 -m venv venv

source venv/bin/activate
pip install -r requirements.txt
pytest
