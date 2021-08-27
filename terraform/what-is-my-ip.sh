#!/bin/bash

public_ip=`curl -s ifconfig.me`
printf '{ "public_ip": "%s" }\n' $public_ip
