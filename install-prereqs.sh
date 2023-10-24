#!/bin/bash

# ACE images don't always have tar or which installed by default
if [ -f /usr/bin/microdnf ]
then
    echo Installing tar
    microdnf install tar
    echo Installing which
    microdnf install which
fi
