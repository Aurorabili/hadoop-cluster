#!/bin/bash

hdfs namenode & \
yarn resourcemanager & \
zkServer.sh start & \
hbase master start 
