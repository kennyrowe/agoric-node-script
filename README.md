# agoric-node-script

Quickly spin up an agoric node with this shell script


1. `git clone https://github.com/GLIBX/agoric-node-script.git`
2. `cd agoric-node-script`
3. `chmod +x node_deploy.sh`
4. `bash node_deploy.sh`
5. "Enter the name of your moniker to initialize chain"
6. Once the script is completed, to check if your node is syncing use command  `ag-cosmos-helper status 2>&1 | jq .SyncInfo`
