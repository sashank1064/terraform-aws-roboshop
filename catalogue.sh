#!/bin/bash

dnf install ansible -y
ansible-pull -U https://github.com/sashank1064/ansible-roboshop-roles-tf.git -e component=$1 -e env=$2 main.yaml