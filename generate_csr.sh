#!/bin/bash

#                                         __                        
#       ____ ____  ____  ___  _________ _/ /____     _______________
#      / __ `/ _ \/ __ \/ _ \/ ___/ __ `/ __/ _ \   / ___/ ___/ ___/
#     / /_/ /  __/ / / /  __/ /  / /_/ / /_/  __/  / /__(__  ) /    
#     \__, /\___/_/ /_/\___/_/   \__,_/\__/\___/   \___/____/_/     
#    /____/                                                         
#
#    Author: Pierpaolo Pupilli
#
#    This is Free Software licensed under the GNU GPL
#

function usage {
  echo usage: $0 CN passphrase [SAN1,...SANn] 
  echo
  exit
}

if [ "$1" == "-h" ] || [ "$1" == "--help" ]; then
  usage
  exit 0
fi

if [ "$1" == "" ]; then
  echo "Empty common name"
  usage
  exit 1
fi

if [ "$2" == "" ]; then
  echo "Empty passphrase"
  usage
  exit 1
fi

CN=$1
PASSPHRASE=$2
if [ "$3" != "" ]; then
  SAN=,DNS:`echo $3 | sed -e 's/,/,DNS:/g'`
fi

countryName="IT"
stateOrProvinceName="Italy"
localityName="Ancona"
organizationName="Acme spa"
organizationalUnitName="-"
emailAddress="foo@bar.com"

WORKDIR=/etc/ssl/my_certs

if [[ "$CN" == "*"* ]]; then
  DIRNAME=WILDCARD.`echo $CN | sed 's/\*\.\(.*\)/\1/'`
else
	DIRNAME=$CN
fi

mkdir $WORKDIR/$DIRNAME
[ $? -eq 0 ] || exit 1

cd $WORKDIR/$DIRNAME

echo "Writing passphrase..."
echo $PASSPHRASE > passphrase

echo "Generating key request for $CN"

#Generate a key
#openssl genrsa -des3 -passout pass:$password -out $CN.key 2048 -noout
openssl genrsa -des3 \
	       -passout pass:$PASSPHRASE \
	       -out $DIRNAME.key 2048 > /dev/null 2>&1


#Create the request
echo "Creating CSR"
openssl req -new \
            -key $DIRNAME.key \
	    			-out $DIRNAME.csr \
	    			-passin pass:$PASSPHRASE \
            -subj "/C=$countryName/ST=$stateOrProvinceName/L=$localityName/O=$organizationName/OU=$organizationalUnitName/CN=$CN/emailAddress=$emailAddress" \
	    			-addext "subjectAltName = DNS:$CN$SAN"

echo "Data dir: $WORKDIR/$DIRNAME"
echo "Key: $DIRNAME.key"
echo "Csr: $DIRNAME.csr"
echo
echo "csr content:"
openssl req -noout -text -in $WORKDIR/$DIRNAME/$DIRNAME.csr
cd -

exit 0
