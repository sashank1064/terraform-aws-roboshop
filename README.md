# terraform-aws-roboshop

Component-level AWS infrastructure for a single RoboShop service. Given a component name, it provisions the EC2 instance, the ALB target group, the listener rule, and the Route 53 record, then hands bootstrap off to `ansible-pull`.

![Terraform](https://img.shields.io/badge/Terraform-7B42BC?logo=terraform&logoColor=white)
![AWS](https://img.shields.io/badge/AWS-232F3E?logo=amazonaws&logoColor=white)
![Ansible](https://img.shields.io/badge/Ansible-EE0000?logo=ansible&logoColor=white)

## Overview

This repo is the "one component, one instance, one target-group entry" factory. The parent deployment in [`roboshop-infra-dev`](https://github.com/sashank1064/roboshop-infra-dev) instantiates it once per service (`catalogue`, `user`, `cart`, `shipping`, `payment`, `dispatch`) through a `for_each` loop.

## What it creates, per component

| Resource | Purpose |
|---|---|
| `aws_lb_target_group` | Named `${project}-${environment}-${component}`, with a real health check (path, port, 200-299 matcher, 15s interval) |
| `aws_instance` | Uses data sources to pick the right AMI and component SG; tagged with `Component` and `Environment` so inventory can find it |
| `aws_lb_target_group_attachment` | Registers the new instance with the target group |
| `aws_lb_listener_rule` | Routes hostname-based traffic on the backend ALB to this target group, at a consumer-supplied `rule_priority` |
| `aws_route53_record` | Private zone A record `${component}-${environment}.internal` pointing at the instance private IP |
| `user_data` bootstrap | Installs Ansible and runs `ansible-pull` against `ansible-roboshop-roles-tf`, passing `component` and `env` as extra vars |

## The ansible-pull bridge

This is the piece that ties the two layers together. The instance's `user_data` is just:

```bash
#!/bin/bash
dnf install ansible -y
ansible-pull -U https://github.com/sashank1064/ansible-roboshop-roles-tf.git \
  -e component=$1 -e env=$2 main.yaml
```

Terraform provisions the host and tags it. Ansible (running from inside the host on first boot) configures the service. No external configuration server. No master to run from. The code that configures `catalogue` lives in one place and ships with the instance.

## Inputs

| Name | Type | Notes |
|---|---|---|
| `project` | `string` | Used in names and tags |
| `environment` | `string` | `dev`, `stage`, `prod` |
| `component` | `string` | `catalogue`, `user`, `cart`, etc. |
| `rule_priority` | `number` | ALB listener rule priority, set by the parent |
| Other locals | various | Looked up from tagged VPC, SG, ALB, and zone data sources |

## Design notes

- **One component, one module call.** No monolith. Adding a service is a new `for_each` entry in the parent, not a schema change.
- **Data sources over variables.** The VPC id, SG ids, ALB listener ARN, and private zone id are all looked up by tag, so the module doesn't need to know anything about the parent stack's internals.
- **Health checks are not optional.** Each target group has a path, port, matcher, and interval configured. No surprise green-but-broken services.
- **Bootstrap by pull, not push.** `ansible-pull` on boot means the node is self-healing on recreate.

## Used by

- [`roboshop-infra-dev`](https://github.com/sashank1064/roboshop-infra-dev) phase `90-components` loops over component definitions and calls this module once per entry

## Related repos

1. [`terraform-aws-vpc`](https://github.com/sashank1064/terraform-aws-vpc), [`terraform-aws-securitygroup`](https://github.com/sashank1064/terraform-aws-securitygroup), [`terraform-aws-instance`](https://github.com/sashank1064/terraform-aws-instance): foundational modules
2. `terraform-aws-roboshop` (this repo): per-component composition
3. [`roboshop-infra-dev`](https://github.com/sashank1064/roboshop-infra-dev): phased full-platform deployment
4. [`ansible-roboshop-roles-tf`](https://github.com/sashank1064/ansible-roboshop-roles-tf): the `ansible-pull` payload
