#!/bin/bash

if [ $1 -eq 0 ] 
then
    echo "Enter number of samples"
else
    head -c $(($1*4)) test/usrp.dat > sim/din.dat
    head -c $(($1/8*4)) test/usrp.out > sim/cmp.dat
fi
