#!/bin/bash -e
#title           :setup-mgmt.sh
#description     :This setups the management node to access Azure Cli and Kubernetes
#author		     :Alex Massey
#date            :19102018
#version         :0.1    
#usage		     :bash setup-mgmt.sh $tenantId $appId $appKey $resourceGroup $clusterName
#notes           :
#==============================================================================


function log() {

  x=":ok:"
  if [ "$2" = "x" ]; then
    x=":question:"
  fi
  if [ "$2" != "0" ]; then
    if [ "$2" = "N" ]; then
       x=""
    else
       x=":japanese_goblin:"
    fi
  fi
  mess="$(date) - $(hostname): $1 $x"
  echo -e $mess >> /tmp/setup.log

  echo "$(date) : $1"
}

function add_azure_apt_repo ()
{
    log "function: add_azure_apt_repo()"
    AZ_REPO=$(lsb_release -cs)
    until echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ $AZ_REPO main" | tee /etc/apt/sources.list.d/azure-cli.list
    do
        log "Waiting to update apt repo list..."
        sleep 2
    done

    until curl -L https://packages.microsoft.com/keys/microsoft.asc | sudo apt-key add -
    do
        log "waiting for the apt key to be installed..."
        sleep 2
    done

}

function apt_update ()
{
    log "function: apt_update()"
    until apt-get update
    do
        log "Lock detected on apt update Try again..."
        sleep 2
    done

}

function apt_install_az-cli () 
{
    log "function: apt_install_az-cli()"
    until apt-get install apt-transport-https azure-cli jq -y
    do
        log "waiting for apt-get install apt-transport-https azure-cli..."
        sleep 2
    done
}

function az_login ()
{
    log "function: az_login()"
    until az login --service-principal -u "$appId" -p "$appKey" --tenant "$tenantID"
    do
        log "waiting for az login to complete..."
        sleep 2
    done
}

function create_aks_cluster ()
{
    log "function: create_aks_cluster..."
    az aks create \
        --resource-group "$resourceGroup" \
        --name "$clusterName" \
        --node-count "$nodeCount" \
        --service-principal "$appId" \
        --client-secret "$appKey" \
        --generate-ssh-keys
    
}

function install_kubernetes_tools ()
{
    log "function: install_kubernetes_tools()"
    until az aks install-cli
    do
        log "waiting for kubernetes tools to install..."
        sleep 2
    done
}

function setup_kubectl ()
{
    log "function: setup_kubectl()"
    until az aks get-credentials --resource-group "$resourceGroup" --name "$clusterName"
    do
        log "waiting to configure kubectl credentials..."
        sleep 2
    done
}

function deploy_mgmt_node () 
{
    log "function: deploy_mgmt_node()"
    until kubectl create -f deployMgmt.yml
    do
        log "waiting for mgmt node to create..."
        sleep 2
    done
   
    check_loadbalancer_ip
}

function check_loadbalancer_ip ()
{
    result=$(kubectl get svc mgmt-svc -o json)
    result=$(echo $result | jq -r '.status.loadBalancer | select (.ingress != null) | .ingress[].ip')
    if [ -z "$result" ]
    then
        sleep 5
        log "waiting for the public IP to be provisioned..."
        check_loadbalancer_ip
    else 
        check_loadbalancer_ip_result=$result
        return 0
    fi
}

# Variables

tenantID="${1}"
appId="${2}"
appKey="${3}"
resourceGroup="${4}"
clusterName="${5}"
nodeCount="${6}"

log "*BEGIN* Configuration of the Pl^g AKS management node" "N"
log " Parameters : " "N"
log " - Azure Tenant ID $tenantID" "N"
log " - Azure App Id $appId" "N"
log " - Azure App Key $appKey" "N"
log " - Azure Kubernetes Resource Group $resourceGroup" "N"
log " - Azure Kubernetes Cluster Name $clusterName" "N"
log " - Azure Kubernetes Number of Nodes $nodeCount" "N"


# Main
add_azure_apt_repo
apt_update
apt_install_az-cli
az_login
create_aks_cluster
install_kubernetes_tools
setup_kubectl
deploy_mgmt_node

# Required Output for Azure ARM templates 
# write an array delimiter before and after the data we want
echo '#DATA#'
echo "$check_loadbalancer_ip_result"
echo '#DATA#'
