#!/bin/sh

# AIR certificate generator
# More information:
# http://livedocs.adobe.com/flex/3/html/help.html?content=CommandLineTools_5.html#1035959
# http://livedocs.adobe.com/flex/3/html/distributing_apps_4.html#1037515

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

# Certificate information
NAME="osmf-air"
PASSWORD=0123
CERTIFICATE="osmfair.pfx"

if ! adt -certificate -cn $NAME 1024-RSA $CERTIFICATE $PASSWORD; then
    failed
fi

echo Certificate created: $CERTIFICATE
echo With password: $PASSWORD
[[ $PASSWORD -eq "fd" ]] && echo "(WARNING: you did not change the default password)"

echo Hint: you may have to wait a few minutes before using this certificate to build your AIR application setup.

exit 0;