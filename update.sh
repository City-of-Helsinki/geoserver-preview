#!/bin/bash
echo "Pulling latest stuff from git."
git pull
echo "npm install to check for new dependencies."
npm install
echo "bower install to check for new frontend dependencies."
bower install
echo "gulp to build the assets to serve."
gulp
echo "All done! Remember to run pm2 restart!"
