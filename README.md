# Lesson Ansible – Terraform Environment

This is **not a full-scale project**, but a small Terraform setup I use for practicing Ansible.

## Purpose

The configuration creates:
- A VPC with public subnets
- Internet Gateway and route table
- A Security Group with SSH access
- Two EC2 instances (Ubuntu and CentOS Stream 9)

This environment is used as a **working lab** for Ansible lessons — to test playbooks and manage remote nodes.