#!/bin/bash -e
#title           :setup-mgmt.sh
#description     :This setups the management node to access Azure Cli and Kubernetes
#author		     :Alex Massey
#date            :19102018
#version         :0.1    
#usage		     :bash setup-mgmt.sh
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
  echo -e $mess >> /var/log/azure/custom-script/customscript.log

  echo "$(date) : $1"
}

function add_azure_apt_repo ()
{
    log "function: add_azure_apt_repo()"
    AZ_REPO=$(lsb_release -cs)
    until echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ $AZ_REPO main" | sudo tee /etc/apt/sources.list.d/azure-cli.list
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
    until sudo apt-get install apt-transport-https azure-cli
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

function install_kubernetes_tools ()
{
    log "function: install_kubernetes_tools()"
    until az aks install-cli
    do
        log "waiting for kubernetes tools to install..."
        sleep 2
    done
}

tenantID="${1}"
appId="${2}"
appKey="${3}"
resourceGroup="${4}"
clusterName="${5}"

# Main
add_azure_apt_repo
apt_update
apt_install_az-cli
install_kubernetes_tools
