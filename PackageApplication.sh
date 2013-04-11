#!/bin/sh

# AIR application packaging
# More information:
# http://livedocs.adobe.com/flex/3/html/help.html?content=CommandLineTools_5.html#1035959

cert_not_found () {
    echo Certificate not found: $CERTIFICATE
    echo
    echo Troubleshotting:
    echo A certificate is required, generate one using 'CreateCertificate.sh'
    exit 1;
}

failed () {
    echo AIR setup creation FAILED.
    echo
    echo Troubleshotting:
    echo 'did you configure the AIR SDK path in AIRSDK_HOME environment variable and add $AIRSDK_NOME/bin to PATH ?'
    exit 1;
}

# ====

# Check AIR SDK configuration
if ! [[ -n $AIRSDK_HOME ]]; then
    failed
fi

# Signature (see 'CreateCertificate.sh')
CERTIFICATE="osmfair.pfx"
SIGNING_OPTIONS="-storetype pkcs12 -keystore $CERTIFICATE -tsa none"
if ! [[ -e $CERTIFICATE ]]; then
    cert_not_found
fi

# Output
if ! [[ -d "air" ]]; then
    mkdir air
fi
AIR_FILE=air/osmfair.air

# Input
APP_XML=application.xml
# В оригинале было
# set FILE_OR_DIR=-C bin .
FILE_OR_DIR="bin"

echo Signing AIR setup using certificate $CERTIFICATE.
if adt -package $SIGNING_OPTIONS $AIR_FILE $APP_XML $FILE_OR_DIR; then
    echo AIR setup created: $AIR_FILE
else
    failed
fi

exit 0;