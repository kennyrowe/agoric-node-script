#!/usr/bin/sh
set -o errexit

#THIS BASH SCRIPT AUTOMATES THE NODE AND VALIDATOR DEPLOYMENT PROCESS

# Request the user's moniker
echo "Enter the public name of your node (your moniker) ?"
read moniker

# Installation of Node, Go & Agoric SDK
curl https://deb.nodesource.com/setup_12.x | sudo bash

# Download the Yarn repository configuration
# See instructions on https://legacy.yarnpkg.com/en/docs/install/
curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list

#Update machine
sudo apt update
sudo apt upgrade -y

# Install Node.js, Yarn, and build tools
# Install jq for formatting of JSON data
sudo apt install nodejs=12.* yarn build-essential jq -y

# Removing any existing old Go installation before installing
sudo rm -rf /usr/local/go

curl https://dl.google.com/go/go1.15.7.linux-amd64.tar.gz | sudo tar -C/usr/local -zxvf -

# Update environment variables to include go
cat <<'EOF' >>$HOME/.profile
export GOROOT=/usr/local/go
export GOPATH=$HOME/go
export GO111MODULE=on
export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin
EOF
source $HOME/.profile

#Agoric installation
git clone https://github.com/Agoric/agoric-sdk -b master
cd agoric-sdk

# Install and build Agoric Javascript packages
yarn install
yarn build

# Install and build Agoric Cosmos SDK support
(cd packages/cosmic-swingset && make)


# Display the version of Agoric SDK installed
ag-chain-cosmos version --long

#Exiting agoric directory
cd ../../../


# Checking Network Parameters

# First, get the network config for the current network.
curl https://testnet.agoric.net/network-config > chain.json

# Set chain name to the correct value
chainName=`jq -r .chainName < chain.json`

# Confirming value: should be something like agorictest-N.
echo $chainName


# First time initialization of validator
ag-chain-cosmos init --chain-d $chainName $moniker

# Download the genesis file
curl https://testnet.agoric.net/genesis.json > $HOME/.ag-chain-cosmos/config/genesis.json 
# Reset the state of your validator.
ag-chain-cosmos unsafe-reset-all

# Setting up validator cofig

#  Set peers variable to the correct value
peers=$(jq '.peers | join(",")' < chain.json)
# Set seeds variable to the correct value.
seeds=$(jq '.seeds | join(",")' < chain.json)
# Confirm values, each should be something like "077c58e4b207d02bbbb1b68d6e7e1df08ce18a8a@178.62.245.23:26656,..."
echo $peers
echo $seeds
# Fix `Error: failed to parse log level`
sed -i.bak 's/^log_level/# log_level/' $HOME/.ag-chain-cosmos/config/config.toml
# Replace the seeds and persistent_peers values
sed -i.bak -e "s/^seeds *=.*/seeds = $seeds/; s/^persistent_peers *=.*/persistent_peers = $peers/" $HOME/.ag-chain-cosmos/config/config.toml


# Syncing The Node

# Creating systemd service file to manage Agoric Cosmos Deamon
sudo tee <<EOF >/dev/null /etc/systemd/system/ag-chain-cosmos.service
[Unit]
Description=Agoric Cosmos daemon
After=network-online.target

[Service]
User=$USER
ExecStart=$HOME/go/bin/ag-chain-cosmos start --log_level=warn
Restart=on-failure
RestartSec=3
LimitNOFILE=4096

[Install]
WantedBy=multi-user.target
EOF



