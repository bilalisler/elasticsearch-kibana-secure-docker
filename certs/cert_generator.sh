#!/bin/bash

# Generate Root Key rootCA.key with 2048
openssl genrsa -passout pass:"$1" -des3 -out rootCA.key 2048

# Generate Root PEM (rootCA.pem) with 1024 days validity.
openssl req -passin pass:"$1" -subj "/C=US/ST=Random/L=Random/O=Global Security/OU=IT Department/CN=Local Certificate"  -x509 -new -nodes -key rootCA.key -sha256 -days 1024 -out rootCA.pem

# Add root cert as trusted cert
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # Linux
        yum -y install ca-certificates
        update-ca-trust force-enable
        cp rootCA.pem /etc/pki/ca-trust/source/anchors/
        update-ca-trust
        #meeting ES requirement
        sysctl -w vm.max_map_count=262144
elif [[ "$OSTYPE" == "darwin"* ]]; then
        # Mac OSX
        security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain rootCA.pem
else
        # Unknown.
        echo "Couldn't find desired Operating System. Exiting Now ......"
        exit 1
fi


# Generate elasticsearch node 1 Cert
openssl req -subj "/C=US/ST=Random/L=Random/O=Global Security/OU=IT Department/CN=localhost"  -new -sha256 -nodes -out elasticsearch_docker1.csr -newkey rsa:2048 -keyout elasticsearch_docker1.key
openssl x509 -req -passin pass:"$1" -in elasticsearch_docker1.csr -CA rootCA.pem -CAkey rootCA.key -CAcreateserial -out elasticsearch_docker1.crt -days 500 -sha256 -extfile  <(printf "subjectAltName=DNS:localhost,DNS:elasticsearch_docker1")

# Generate elasticsearch node 2 Cert
openssl req -subj "/C=US/ST=Random/L=Random/O=Global Security/OU=IT Department/CN=localhost"  -new -sha256 -nodes -out elasticsearch_docker2.csr -newkey rsa:2048 -keyout elasticsearch_docker2.key
openssl x509 -req -passin pass:"$1" -in elasticsearch_docker2.csr -CA rootCA.pem -CAkey rootCA.key -CAcreateserial -out elasticsearch_docker2.crt -days 500 -sha256 -extfile  <(printf "subjectAltName=DNS:localhost,DNS:elasticsearch_docker2")

# Generate kibana Cert
openssl req -subj "/C=US/ST=Random/L=Random/O=Global Security/OU=IT Department/CN=localhost"  -new -sha256 -nodes -out kibana_docker.csr -newkey rsa:2048 -keyout kibana_docker.key
openssl x509 -req -passin pass:"$1" -in kibana_docker.csr -CA rootCA.pem -CAkey rootCA.key -CAcreateserial -out kibana_docker.crt -days 500 -sha256 -extfile  <(printf "subjectAltName=DNS:localhost,DNS:kibana_docker")
