# AWS Security Groups Module
A Terraform/OpenTofu module for creating a pre-defined set of security groups to secure traffic between the Web Servers, Workers, Load Balancers, Databases, Redis Instances, and Elasticsearch Instances of an application.

NOTE: This module is optimized for use with the [AWS Server Stack](https://github.com/strouptl/terraform-aws-server-stack) module.

## Example
Insert the following into your main.tf file:

    terraform {
      required_providers {
        aws = { 
          source  = "hashicorp/aws"
          version = "~> 5.17"
        }   
      }
      required_version = ">= 1.2.0"
    }
    
    provider "aws" {
      region  = "us-east-1"
    }
    
    module "example_security_groups" {
      source = "git@github.com:strouptl/terraform-aws-security-groups.git?ref=0.1.0"
      name = "example"
    }

## Usage
Once you have defined your security groups as above, you can then reference the ID's for those security group by name elsewhere in your main.tf file. For example, the Database Security Group's id would be:

    module.example_security_groups.database_instances.id 

See the list below for other "outputs" that you can reference in your main.tf file from this module.

## Outputs
1. web_servers
2. workers
3. load_balancers
4. database_instances
5. redis_instances
6. elasticsearch_instances
