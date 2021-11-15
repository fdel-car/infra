#!/bin/bash

# Install node using nvm
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
nvm install 16

# Install and configure global packages
npm install --global yarn pm2
pm2 list # Don't remove this line otherwise .pm2 folder will have permissions issues
sudo -E env "PATH=$PATH" pm2 startup
