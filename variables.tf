variable "project" {
  description = "Project name"
  type        = string
  default = "roboshop"
  
}

variable "environment" {
  description = "Environment name"
  type        = string
  default = "dev"
  
}

variable "zone_id" {
  description = "Route53 zone ID"
  type        = string
  default = "Z05717891IWFXUBM74UFS"
}

variable "zone_name" {
  description = "Route53 zone name"
  type        = string
  default = "daws84s.pro"
  
}

variable "component" {
  description = "Component name"
  type        = string
  
  
}

variable "rule_priority" {
  description = "Rule priority for ALB listener"
  type        = number
}