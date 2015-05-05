#!/bin/bash -e
set -euo pipefail
IFS=$'\n\t'

project=$(basename $PWD)

echo "Warning! This script will delete any existing databases configured for"
echo "$project development and test. If you need any data in those"
echo "databases, please exit this script now, and back it up before continuing."
echo ""
echo "Do you want to continue? [y/n]"

read option

version=2.1.5
if [ -f .ruby-version ]; then
  version=$(<.ruby-version)
fi

echo "Ruby version is $version"

if [[ $option == 'y' ]]; then
  echo "Setting up Project Neptune"
  echo "-----------------------------------------------------------------------"

  echo "Install required packages [y/n]?"

  read packages

  if [[ $packages == 'y' ]]; then
    if [[ "$OSTYPE" == "darwin"* ]]; then
      if [ -f requirements.txt ]; then
        packages=$(cat requirements.txt)
        echo "Installing $packages"
        if brew install $packages; then
          rbenv install -s $version
          rbenv local $version
          gem install bundler
      fi
      else
        echo "Failed to install required packages"
        exit $?
      fi
    fi
  fi

  echo "Checking for a .env file"
  if [[ ! -f .env ]]; then
    echo ".env file does not exist"
    echo "see env.sample for example file"
    exit
  fi

  echo "Running bundle install"
  bundle install

  echo "Deleting existing databases (if they exist)"
  bundle exec rake db:drop

  echo "Creating default tenant and system data"
  bundle exec rake db:setup

  echo "Prepating test database"
  bundle exec rake db:test:prepare

  echo "Installing Bower Components"
  bundle exec rake bower:install

  echo "==========================================="
  echo
  echo
  echo "Start your server (and sidekiq etc) with:"
  echo
  echo "    bundle exec foreman start"
  echo
  echo "Then you can visit your app at:"
  echo
  echo "    http://jobready.127.0.0.1.xip.io:3001"
  echo
  echo
  echo "==========================================="

else

  echo "Exiting the script"

fi

