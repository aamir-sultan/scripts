#!/bin/sh


# this script does absolutely ZERO error checking.   however, it worked
# for me on a RHEL 6.3 machine on 2012-08-08.  clearly, the version numbers
# and/or URLs should be made variables.  cheers,  zmil...@cs.wisc.edu


mkdir mosh
cd mosh

ROOT=`pwd`

echo "==================================="
echo "about to set up everything in $ROOT"
echo "==================================="

mkdir build
mkdir install

cd build
# wget https://github.com/protocolbuffers/protobuf/releases/download/v23.1/protobuf-23.1.tar.gz 
wget https://github.com/google/protobuf/releases/download/v2.6.1/protobuf-2.6.1.tar.gz
wget https://github.com/madler/zlib/releases/download/v1.2.13/zlib-1.2.13.tar.gz 
wget https://github.com/mobile-shell/mosh/releases/download/mosh-1.4.0/mosh-1.4.0.tar.gz 
tar zxvf protobuf-2.6.1.tar.gz
tar zxvf zlib-1.2.13.tar.gz 
tar zxvf mosh-1.4.0.tar.gz

echo "================="
echo "building protobuf"
echo "================="

cd $ROOT/build/protobuf-2.6.1
./configure --prefix=$HOME/.local --disable-shared
make install

echo "================="
echo "building zlib"
echo "================="

cd $ROOT/build/zlib-1.2.13
./configure --prefix=$HOME/.local
make
make install

echo "============="
echo "building mosh"
echo "============="

cd $ROOT/build/mosh-1.4.0
export PROTOC=$HOME/.local/bin/protoc
export protobuf_CFLAGS=-I$HOME/.local/include
export protobuf_LIBS=$HOME/.local/lib/libprotobuf.a

./configure --prefix=$HOME/.local
make
make install

echo "==="
echo "if all was successful, binaries are now in $ROOT/install/mosh/bin"
echo "==="
