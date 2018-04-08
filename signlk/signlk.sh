#!/bin/sh
################################################################################
# Copyright (c) 2016, The Linux Foundation. All rights reserved.               #
#                                                                              #
# Redistribution and use in source and binary forms, with or without           #
# modification, are permitted provided that the following conditions are       #
# met:                                                                         #
#     * Redistributions of source code must retain the above copyright         #
#       notice, this list of conditions and the following disclaimer.          #
#     * Redistributions in binary form must reproduce the above                #
#       copyright notice, this list of conditions and the following            #
#       disclaimer in the documentation and/or other materials provided        #
#       with the distribution.                                                 #
#     * Neither the name of The Linux Foundation nor the names of its          #
#       contributors may be used to endorse or promote products derived        #
#       from this software without specific prior written permission.          #
#                                                                              #
# THIS SOFTWARE IS PROVIDED "AS IS" AND ANY EXPRESS OR IMPLIED                 #
# WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF         #
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NON-INFRINGEMENT       #
# ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS       #
# BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR       #
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF         #
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR              #
# BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,        #
# WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE         #
# OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN       #
# IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.                                #
#                                                                              #
# THIS IS A WORKAROUND TO GET LK INTO THE PROPER FORMAT,                       #
# NO SECURITY IS BEING PROVIDED BY THE OPENSSL CALLS                           #
################################################################################
INFILE=""
OUTFILE=""
DIR=$(dirname $0)
EXECUTABLE="$DIR/signer/signlk"
CN=""
OU=""

set -e

for i in "$@"
do
case $i in
    -i=*|--in=*)
    INFILE="${i#*=}"

    ;;
    -o=*|--out=*)
    OUTFILE="${i#*=}"
    ;;
    -OU=*|-ou=*)
    OU="${i#*=}"

    ;;
    -CN=*|-cn=*)
    CN="${i#*=}"

    ;;
    -d|--debug)
        #set -x
    ;;
    -h*|--help*)
    echo "signlk -i=input_file_name [-o=output_file_name]"
    echo "-i                    input ELF/MBN file name" 
    echo "-o                    output file name, input_file_name with suffix of 'signed' as default "
    echo "-cn                   common name "
    echo "-ou                   organization unit "
    exit 0
    ;;
    *)
    echo "unsupported option"       # unknown option
    echo "type signlk --help for help" 
    exit 1
    ;;
esac
done

if [ "$INFILE" = "" ]; then
   echo "ERROR: Must specify input file:"
   echo "signlk -i=input_file_name [-o=output_file_name]"
	exit 2
fi

INFILE_filename=$(echo $INFILE | rev | cut -f 2- -d '.' | rev)
INFILE_extension=$(echo $INFILE | rev | cut -f 1 -d '.' | rev)

if [ "$OUTFILE" = "" ]; then
        OUTFILE=$INFILE_filename"_signed.mbn"
        
fi
echo "generating output file $OUTFILE"

tmpdir=$(mktemp -d)
TMPOUTFILE=$tmpdir/"tmp.elf"
if [ ! "$(openssl version)" ]; then
   echo "please install openssl"
   exit 6
fi
if [ ! "$(make -v)" ]; then
   echo "please install gcc"
   exit 7
fi
if [ ! "$(g++ --version)" ]; then
   echo "please install g++"
   exit 8
fi

echo "Building executable..."
export mfile_path=$DIR/signer
make -f $mfile_path/Makefile

if [ "$?" != 0 ]; then
    echo " failed to build executable"
    exit 5
fi

echo "Running executable..."
$EXECUTABLE $INFILE $TMPOUTFILE $tmpdir

echo "Generating SHA256 digest..."
openssl sha256 -binary $tmpdir/header > $tmpdir/data
cat $tmpdir/hash>> $tmpdir/data
openssl sha256 -binary $tmpdir/2 >> $tmpdir/data
openssl sha256 -binary $tmpdir/3 >> $tmpdir/data

openssl sha256 -binary $tmpdir/data > $tmpdir/stp0
cat $tmpdir/Si > $tmpdir/tmpDigest0
cat $tmpdir/stp0 >> $tmpdir/tmpDigest0 
openssl sha256 -binary $tmpdir/tmpDigest0 > $tmpdir/stp1
cat $tmpdir/So > $tmpdir/tmpDigest1
cat $tmpdir/stp1 >> $tmpdir/tmpDigest1 
openssl sha256 -binary $tmpdir/tmpDigest1 > $tmpdir/dataToSign.bin

echo "Generating signing certificate..."
DATA=$tmpdir/data
CODE=$tmpdir/dataToSign.bin
SIG=$tmpdir/sig
ATT=$tmpdir/atte.DER
ROOT=$tmpdir/root.DER

tmp_att_file=$tmpdir/e.ext

echo "authorityKeyIdentifier=keyid,issuer" >> $tmp_att_file
echo "basicConstraints=CA:FALSE,pathlen:0" >> $tmp_att_file
echo "keyUsage=digitalSignature" >> $tmp_att_file

openssl version > $tmpdir/days
openssl req -new -x509\
	-keyout $tmpdir/root_key.PEM -nodes\
	-newkey rsa:2048 -days 7300 -set_serial 1 -sha256\
	-subj "/CN=DRAGONBOARD TEST PKI – NOT SECURE/O=S/OU=01 0000000000000009 SW_ID/OU=02 0000000000000000 HW_ID"\
	-out $tmpdir/root_certificate.PEM
	
openssl x509 -in $tmpdir/root_certificate.PEM -inform PEM -outform DER -out $ROOT
openssl genpkey -algorithm RSA -outform PEM -pkeyopt rsa_keygen_bits:2048 -pkeyopt rsa_keygen_pubexp:3 -out $tmpdir/atte_key.PEM

openssl req -new\
	-key $tmpdir/atte_key.PEM\
	-subj "/CN=DRAGONBOARD TEST PKI – NOT SECURE/OU=01 0000000000000009 SW_ID/OU=02 0000000000000000 HW_ID"\
	-days 7300\
	-out $tmpdir/atte_csr.PEM
	
openssl x509 -req -in $tmpdir/atte_csr.PEM -CAkey $tmpdir/root_key.PEM -CA $tmpdir/root_certificate.PEM -days 7300 -set_serial 1 -extfile $tmp_att_file -sha256 -out $tmpdir/atte_cert.PEM 2>/dev/null
openssl x509 -in $tmpdir/atte_cert.PEM -inform PEM -outform DER -out $ATT 2>/dev/null
openssl pkeyutl -sign -inkey $tmpdir/atte_key.PEM -in $CODE -out $SIG 2>/dev/null

get_size () {
	echo $(du -b $1 | tr '[:blank:]' ' ' | cut -d ' ' -f 1)
}

data_siz=$(get_size $DATA)
code_siz=$(get_size $CODE)
sig_siz=$(get_size $SIG)
atte_siz=$(get_size $ATT)
root_siz=$(get_size $ROOT)
hseg_siz=$(get_size $tmpdir/hashSeg)

hseg_offset=4096
mi_hdr_size=40

DATA_OFF=$(($hseg_offset+$mi_hdr_size))
SIG_OFF=$(($hseg_offset+$mi_hdr_size+$data_siz))
ATT_OFF=$(($hseg_offset+$mi_hdr_size+$data_siz+$sig_siz))
ROOT_OFF=$(($hseg_offset+$mi_hdr_size+$data_siz+$sig_siz+$atte_siz))
HSEG_OFF=$(($hseg_offset+$mi_hdr_size+$data_siz+$sig_siz+$atte_siz+$root_siz))

echo "Appending certificate data to ELF..."
dd if=$TMPOUTFILE of=$OUTFILE  2>/dev/null
dd if=$DATA of=$OUTFILE bs=1 count=$data_siz  seek=$DATA_OFF 2>/dev/null
dd if=$SIG  of=$OUTFILE bs=1 count=$sig_siz   seek=$SIG_OFF 2>/dev/null
dd if=$ATT  of=$OUTFILE bs=1 count=$atte_siz  seek=$ATT_OFF 2>/dev/null
dd if=$ROOT of=$OUTFILE bs=1 count=$root_siz  seek=$ROOT_OFF 2>/dev/null
dd if=$tmpdir/hashSeg of=$OUTFILE bs=1 \
	skip=$(($mi_hdr_size+$data_siz+$sig_siz+$atte_siz+$root_siz)) \
	seek=$HSEG_OFF 2>/dev/null
	
dd if=$TMPOUTFILE of=$OUTFILE bs=1 skip=$(($hseg_offset+$hseg_siz)) seek=$(($hseg_offset+$hseg_siz)) 2>/dev/null

# no cleanup in debug mode
if ! echo "$-" | grep -q 'x'; then
   rm -rf $tmpdir
fi

echo done
