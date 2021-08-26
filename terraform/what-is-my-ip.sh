#!/bin/bash

public_ip=`dig @resolver4.opendns.com myip.opendns.com +short`
printf '{ "public_ip": "%s" }\n' $public_ip
