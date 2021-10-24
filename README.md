# Terraform Example
This Terraform program is connecting to Azure and creating the following:
* 3 Virtual Networks
* A subnet inside each virtual network
* Virtual network peering - vnet0<>vnet1; vnet0<>vnet2
* 3 VMs that will exist in each of the virtual networks' subnets

The base image of all VMs is Ubuntu 18.04 LTS

## Current issues/limitations
None of the VMs has a public IP