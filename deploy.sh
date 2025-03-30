#!env zsh

SERVER_CONFIG_DIR=~/nixos-config
SERVER_SSH=RootNixServer
SERVER_FLAKE="--flake .#BrianNixServer"
SERVER_ACTION=switch
APP_FLAKE=portfolio


OLD_PWD=$PWD
cd $SERVER_CONFIG_DIR
nix flake update $APP_FLAKE
nixos-rebuild $SERVER_ACTION $SERVER_FLAKE --target-host $SERVER_SSH
cd $OLD_PWD
