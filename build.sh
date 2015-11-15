#!/usr/bin/env bash

PKI_PATH="./pki"
ROOT_CA="$PKI_PATH/root"
INTERMEDIATE_CA="$PKI_PATH/intermediate"

if [[ -d "$PKI_PATH" ]]; then
  printf "[FATAL] Path \"$PKI_PATH\" already exists\n"
  exit 1
fi

printf "\n==> Setting things up:\n"
mkdir -p {$ROOT_CA,$INTERMEDIATE_CA}/{certs,crl,newcerts,private,csr}
chmod 700 {$ROOT_CA,$INTERMEDIATE_CA}/private
touch {$ROOT_CA,$INTERMEDIATE_CA}/database

for file in $ROOT_CA/serial $INTERMEDIATE_CA/serial $INTERMEDIATE_CA/crlnumber ; do
  printf 1000 > $file
done

cp root.cnf $ROOT_CA/openssl.cnf
cp intermediate.cnf $INTERMEDIATE_CA/openssl.cnf

printf "\n==> Generating Root CA key:\n"
openssl genrsa -aes256 -out $ROOT_CA/private/root.key 4096

printf "\n==> Generating Root CA certificate:\n"
openssl req -config $ROOT_CA/openssl.cnf -key $ROOT_CA/private/root.key \
  -new -x509 -days 3650 -sha256 -extensions v3_ca -out $ROOT_CA/certs/root.pem

printf "\n==> Generating Intermediate CA key:\n"
openssl genrsa -aes256 -out $INTERMEDIATE_CA/private/intermediate.key 4096

printf "\n==> Generating Intermediate CA certificate request:\n"
openssl req -config $INTERMEDIATE_CA/openssl.cnf -new -sha256 \
  -key $INTERMEDIATE_CA/private/intermediate.key \
  -out $INTERMEDIATE_CA/csr/intermediate.csr

printf "\n==> Requesting Intermediate CA certificate to the Root CA:\n"
openssl ca -config $ROOT_CA/openssl.cnf -extensions v3_intermediate_ca -days 1825 \
  -notext -md sha256 -in $INTERMEDIATE_CA/csr/intermediate.csr \
  -out $INTERMEDIATE_CA/certs/intermediate.pem

printf "\n==> Building certification chain:\n"
cat $INTERMEDIATE_CA/certs/intermediate.pem $ROOT_CA/certs/root.pem \
  > $INTERMEDIATE_CA/certs/chain.pem
printf "$INTERMEDIATE_CA/certs/chain.pem\n"

printf "\n==> All done!\n"
