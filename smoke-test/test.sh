#!/bin/bash

# Copyright: (C) 2016 iCub Facility - Istituto Italiano di Tecnologia
# Authors: Ugo Pattacini <ugo.pattacini@iit.it>
# CopyPolicy: Released under the terms of the GNU GPL v3.0.

dir=$(pwd)
if [ $# -gt 1 ]; then   
    cd $1
fi

if [ -d build ]; then 
    rm build -rf
fi
mkdir build && cd build
cmake -DCMAKE_BUILD_TYPE=Release ../../
if [ $? -ne 0 ]; then
   exit 1
fi
make install
if [ $? -ne 0 ]; then
   exit 1
fi
cd $dir

if [ -d build-test ]; then 
    rm build-test -rf
fi
rm build-test -rf
mkdir build-test && cd build-test
cmake -DCMAKE_BUILD_TYPE=Release ../
make
if [ $? -ne 0 ]; then
   exit 2
fi
cd ../

# to let yarpmanager access the fixture
export YARP_DATA_DIRS=${YARP_DATA_DIRS}:$(pwd)

# to make the test library retrievable
export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:$(pwd)/build-test/plugins

yarp where > /dev/null 2>&1
if [ $? -eq 0 ]; then
   kill_yarp="no"
else
   kill_yarp="yes"
   yarpserver --write &
   sleep 1
fi

yarp exists /testnode
if [ $? -eq 0 ]; then
   kill_testnode="no"
else
   kill_testnode="yes"
   yarprun --server /testnode > /dev/null 2>&1 &
   sleep 1
fi

testrunner --verbose --suit test.xml > output.txt

if [ "$kill_yarp" == "yes" ]; then
   killall yarpserver
fi

if [ "$kill_testnode" == "yes" ]; then
   killall yarprun
fi

cd build
make uninstall && cd ../

cat output.txt

red='\033[1;31m'
green='\033[1;32m'
nc='\033[0m'

npassed=$(grep -i "Number of passed test cases" output.txt | sed 's/[^0-9]*//g')
if [ $npassed -eq 0 ]; then   
   echo -e "${red}xxxxx Test FAILED xxxxx${nc}\n"
   exit 3
else
   echo -e "${green}===== Test PASSED =====${nc}\n"
   exit 0
fi

