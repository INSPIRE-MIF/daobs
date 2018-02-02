#!/bin/bash

sed "s#SECRET#$SECRET#g" -i /opt/cerebro/conf/application.conf

./bin/cerebro
