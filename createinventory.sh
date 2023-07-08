#!bin/bash

sed "s/{IP}/$1/" ./inventory.template > ./inventory
