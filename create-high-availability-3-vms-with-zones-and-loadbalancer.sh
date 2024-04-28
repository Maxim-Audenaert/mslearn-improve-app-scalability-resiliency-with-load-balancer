#!/bin/bash

RgName=`az group list --query '[].name' --output tsv`
Location=`westeurope`

date
# Create a Virtual Network for the VMs
echo '------------------------------------------'
echo 'Creating a Virtual Network for the VMs'
az network vnet create \
    --resource-group $RgName \
    --location $Location \
    --name loadbalancerVnet \
    --subnet-name loadbalancerSubnet 

# Create a public IP for the load balancer
echo '------------------------------------------'
echo 'Creating a public IP for the load balancer'
az network public-ip create \
    --resource-group $RgName \
    --allocation-method Static \
    --name loadbalancerPublicIP 

# Create the load balancer
echo '------------------------------------------'
echo 'Creating the load balancer'
az network lb create \
    --resource-group $RgName \
    --name loadbalancer \
    --public-ip-address loadbalancerPublicIP \
    --frontend-ip-name loadbalancerFrontEndPool  \
    --backend-pool-name loadbalancerBackEndPool  

# Create a probe for the load balancer
echo '------------------------------------------'
echo 'Creating a probe for the load balancer'
az network lb probe create \
    --resource-group $RgName \
    --lb-name loadbalancer \
    --name loadbalancerProbe \
    --protocol tcp \
    --port 80

# Create a rule for the load balancer
echo '------------------------------------------'
echo 'Creating a rule for the load balancer'
az network lb rule create \
    --resource-group $RgName \
    --lb-name loadbalancer \
    --name loadbalancerHTTPRule \
    --protocol tcp \
    --frontend-port 80 \
    --backend-port 80 \
    --frontend-ip-name loadbalancerFrontEndPool \
    --backend-pool-name loadbalancerBackEndPool \
    --probe-name loadbalancerProbe 

# Create a Network Security Group
echo '------------------------------------------'
echo 'Creating a Network Security Group'
az network nsg create \
    --resource-group $RgName \
    --name loadbalancerNetworkSecurityGroup \

# Create a HTTP rule
echo '------------------------------------------'
echo 'Creating a HTTP rule'
az network nsg rule create \
    --resource-group $RgName \
    --nsg-name loadbalancerNetworkSecurityGroup \
    --name loadbalancerNetworkSecurityGroupRuleHTTP \
    --protocol tcp \
    --direction inbound \
    --source-address-prefixes '*' \
    --source-port-ranges '*' \
    --destination-address-prefixes '*' \
    --destination-port-ranges 80 \
    --access allow \
    --priority 200

# Create the NIC
for i in `seq 1 2 3`; do
  echo '------------------------------------------'
  echo 'Creating NIC'$i
  az network nic create \
    --resource-group $RgName \
    --name NIC$i \
    --vnet-name loadbalancerVnet \
    --subnet loadbalancerSubnet \
    --network-security-group loadbalancerNetworkSecurityGroup \
    --lb-name loadbalancer \
    --lb-address-pools loadbalancerBackEndPool 
done 

# Create 3 VM's
for i in `seq 1 2 3`; do
  echo '------------------------------------------'
  echo 'Creating VM'$i
  az vm create \
    --admin-username azureuser \
    --admin-password Pa55w.rd1234! \
    --authentication-type all \
    --resource-group $RgName \
    --name VM$i \
    --nics NIC$i \
    --image Ubuntu2204 \
    --zone $i \
    --generate-ssh-keys \
    --custom-data webpage.txt
done

# Done
echo '---------------------------------------------------'
echo '             Setup Script Completed'
echo '---------------------------------------------------'
strCommand="az network public-ip show -n loadbalancerPublicIP --query ipAddress -o tsv -g "$RgName
publicIP=`${strCommand}`
echo ' Visit the webpage at: http://'$publicIP
echo '---------------------------------------------------'
date
