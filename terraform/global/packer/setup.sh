#!/bin/bash

# Install node using nvm
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
nvm install 16

# Install and configure global packages
npm install --global yarn pm2
sudo -E env "PATH=$PATH" pm2 startup

# Fetch and serve application
npx create-react-app tracker
cd tracker
yarn build
pm2 serve build
pm2 save
