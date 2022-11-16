#!/bin/bash
#
echo 'You wish to have the power of a golden god?'
read answer

if [ "$answer" == 'Yes' ]; then
    echo 'THIS IS NOT A STARTER COMMAND THIS IS A FINISHER COMMAND YOU ARE NOW STUCK IN THIS CONTAINER FOREVER'
    sudo -u docker docker exec -it $(sudo -u docker docker run -d -v $1:/orange/MANUAL \
        iszatt/orange:0.0.1 sleep 1d) bash
fi

if [ "$answer" == 'no' ]; then
    echo 'Are you not aware of .... the implication?'
    exit 1
fi
U