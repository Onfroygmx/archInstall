#!/bin/bash
#
# Author : Onf
# Version: 0.1
#
if [[ -n $SSH_CONNECTION ]] ; then
    echo "I'm logged in remotely"

#Color variables
#W="\033[00;37m"
W="\033[0m"
B="\033[01;36m"
R="\033[01;31m"
G="\033[01;32m"
N="\033[0m"

USERNAME=`whoami`
USERGROUP=`id -Gn`

echo -e "$B       USER $G:$W $USERNAME"
echo -e "$B     GROUPS $G:$W $USERGROUP"

fi
