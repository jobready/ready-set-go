#!/bin/bash
set -eo pipefail
IFS=$'\n\t'
project=$(basename $PWD)

function can_execute () {
  hash "$1" 2>/dev/null
}

if ! [[ -f Gemfile ]]; then
  "Need to be in project root directory"
  exit
fi

echo "Warning! This script will delete any existing databases configured for"
echo "$project development and test. If you need any data in those"
echo "databases, please exit this script now, and back it up before continuing."
echo ""

read -p "Do you want to continue? [y/n]" option

version=2.1.5
if [ -f .ruby-version ]; then
  version=$(<.ruby-version)
fi

if [[ $option == 'y' ]]; then
  echo "Ruby version is $version"
  echo "Setting up $project"
  echo "RAILS_ENV = $RAILS_ENV"
  echo "-----------------------------------------------------------------------"

  if ! can_execute java; then
    echo "You will need to install Java before we start"
    exit
  fi

  read -p "Install required packages [y/n]?" packages

  if [[ $packages == 'y' ]]; then
    if [[ "$OSTYPE" == "darwin"* ]]; then

      if ! can_execute brew; then
        echo "homebrew not found"
        exit
      fi

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

  if [[ -f Bowerfile ]]; then
    if ! can_execute bower; then
      echo "You will need to install bower before we start: npm install bower -g"
      exit
    fi
  fi

  echo "Running bundle install"
  bundle install

  echo "Deleting existing databases (if they exist)"
  bundle exec rake db:drop

  echo "Creating default tenant and system data"
  bundle exec rake db:setup

  echo "Preparing test database"
  bundle exec rake db:test:prepare

  if [[ -f Bowerfile ]]; then
    echo "Installing Bower Components..."
    bundle exec rake bower:install
  fi

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

