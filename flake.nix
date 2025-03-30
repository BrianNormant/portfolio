{
	description = "My portfolio";

	inputs = {
		flake-parts.url = "github:hercules-ci/flake-parts";
		nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
	};

	outputs = inputs@{ flake-parts, ... }:
		flake-parts.lib.mkFlake { inherit inputs; } {
			systems = [ "x86_64-linux" ];
			perSystem = { pkgs, inputs, ... }: {
				# Tmux dev shell
				devShells.default = pkgs.mkShell {
					packages = with pkgs; [];
					shellHook = ''
						export SHELL=zsh
						SESSION_NAME=Portfolio
						DEV_DIR=$(pwd)

						# Check if session exists
						if tmux has-session -t "$SESSION_NAME" > /dev/null 2>&1; then
							echo "Tmux $SESSION_NAME session already running."
							tmux switch-client -t "$SESSION_NAME":1
							exit 0
						fi

						# Check if session exists but is detached
						if tmux list-sessions | grep -q "$SESSION_NAME"; then
							echo "Tmux $SESSION_NAME session exists, attaching..."
							tmux attach-session -t "$SESSION_NAME":1
							exit 0
						fi

						tmux new-session -d -c "~" -s $SESSION_NAME

						tmux respawn-window -k -t $SESSION_NAME:1 -c $DEV_DIR "nix develop .#web"
						tmux rename-window -t $SESSION_NAME:1 "Web"


						tmux new-window -t $SESSION_NAME:2 -n "Api" -c $DEV_DIR "nix develop .#api"

						tmux new-window -t $SESSION_NAME:3 -n "Server" -c "~/nixos-config"
						tmux split-window -t $SESSION_NAME:3 "ssh BrianNixServer"

						tmux new-window -t $SESSION_NAME:4 -n "flake" -c $DEV_DIR "lazygit"

						tmux switch -t $SESSION_NAME:1

						exit 0;
					'';
				};

				# Front-End
				devShells.web= pkgs.mkShell {
					packages = with pkgs; [ nodejs zsh ];
					shellHook = ''
						export SHELL=zsh
						cd ./web
						exec zsh
					'';
				};
				packages.portfolio-website = pkgs.buildNpmPackage rec {
					pname = "portfolio-${version}";
					version = "0.0.1";
					src = ./web;
					npmDepsHash = "sha256-QlTJvdiyS29sWAzJVzVJTHnmS4Y2ZRmVwCJiipyxhQM=";
					installPhase = ''
						mkdir -p $out
						cp -r dist/* $out
					'';
				};
				
				# Rest-API
				# Inspiration from
				# https://github.com/MatejaMaric/yota-laravel/blob/0ee30435fe94918836360022ddb3e24cfeed384a/derivation.nix
				devShells.api = pkgs.mkShell {
					packages = with pkgs; [ php84Packages.composer php84 zsh nodejs ];
					shellHook = ''
						export SHELL=zsh
						cd ./api
						exec zsh
					'';

				};

				packages.portfolio-api = let
					# Those folder need to be setup by the module
					dataDir = "/var/lib/portfolio-api";
					runtimeDir = "/run/portfolio-api";
				in pkgs.php84.buildComposerProject rec {
					pname = "portfolio-api";
					version = "0.0.1";

					src = ./api;
					composerLock = ./api/composer.lock;
					vendorHash = "sha256-sDmWBR6hHlzmBNQj3dmGCt9v7StydiI46O695dzm4IE=";

					nativeBuildInputs = with pkgs; [
						nodejs
						npmHooks.npmConfigHook
						npmHooks.npmInstallHook
					];

					npmDeps = pkgs.fetchNpmDeps {
						inherit src;
						hash = "sha256-NJkyTpQTg2NVckHkbeb2X/7vyJSRuJRC0FaJIMVtDaI=";
					};

					postInstall = ''
						mv $out/share/php/portfolio-api/* $out
						rm -rf $out/share

						rm -R $out/bootstrap/cache

						mv $out/bootstrap $out/bootstrap-static
						mv $out/storage $out/storage-static

						ln -s ${dataDir}/storage $out/storage
						ln -s ${dataDir}/storage/app/public $out/public/storage
						ln -s ${runtimeDir} $out/bootstrap
						ln -s ${dataDir}/.env $out/.env

						chmod +x $out/artisan
					'';
				};
			};
			flake = {
				nixosModules.portfolio-api = {lib, pkgs, config, ...}:
				let
					cfg = config.services.portfolio-api;
					user = "portfolio";
					group = "portfolio";
					dataDir = "/var/lib/portfolio-api";
					runtimeDir = "/run/portfolio-api";
					phpPackage = pkgs.php.withExtensions ({enabled, all}: enabled);
					configFile = pkgs.writeText "portfolio-api-env" (lib.generators.toKeyValue { } {
						APP_KEY = "";
						APP_ENV = if cfg.debug then "local" else "production";
						APP_DEBUG = cfg.debug;
						APP_URL = "https://${cfg.domain}";
						APP_DOMAIN = cfg.domain;
						LOG_CHANNEL = "stderr";
						DB_CONNECTION = "pgsql";
						DB_DATABASE = user;
						DB_USERNAME = user;
						DB_PASSWORD = "1234";
					});
				in {
					
					options.services.portfolio-api= {
						enable = lib.mkEnableOption "Enable portfolio-api";
						portfolio-pkgs = lib.mkOption {
							type = lib.types.package;
							description = "the api package to use";
						};
						debug = lib.mkOption {
							type = lib.types.bool;
							default = false;
						};
						domain = lib.mkOption {
							type = lib.types.str;
						};
					};
					config = lib.mkIf cfg.enable {
						users.users = {
							${user} = {
								isSystemUser = true;
								inherit group;
							};
							# Needed for Nginx to access phpfpm socket
							${config.services.nginx.user} = {
								extraGroups = [ group ];
							};
						};
						users.groups.${group} = {};

						environment.systemPackages = [
							# Shell to manage the api
							# This is for to run migrations, inspect the database status, ect
							(pkgs.writeShellApplication {
							name = "portfolio-management-shell";
							runtimeInputs = with pkgs; [ phpPackage zsh ];
							text = ''
								cd ${cfg.portfolio-pkgs}
								zsh
							'';
							})
						];

						
						# Cache
						systemd.tmpfiles.rules = [
							"d ${runtimeDir}/        0775 ${user} ${group} - -"
							"d ${runtimeDir}/cache   0775 ${user} ${group} - -"
							"d ${dataDir}/           0775 ${user} ${group} - -"
						];

						# Service
						systemd.services = {
							portfolio-data-setup = {
								description = "Setup portfolio data";
								wantedBy = [ "multi-user.target" ];
								after = [ "postgresql.service" ];
								requires = [ "postgresql.service" ];
								path = [ phpPackage pkgs.rsync ];

								serviceConfig = {
									Type = "oneshot";
									User = user;
									Group = group;
									StateDirectory = "portfolio-api";
									Umask = "077";
								};

								script = ''
									# Before running any PHP program, cleanup the code cache.
									# It's necessary if you upgrade the application otherwise you might try to import non-existent modules.
									rm -f ${runtimeDir}/app.php
									rm -rf ${runtimeDir}/cache/*

									rm -f ${dataDir}/.env
									cp --no-preserve=all ${configFile} ${dataDir}/.env

									# Copy the static storage (package provided) to the runtime storage
									mkdir -p ${dataDir}/storage
									rsync -av --no-perms ${cfg.portfolio-pkgs}/storage-static/ ${dataDir}/storage
									chmod -R +w ${dataDir}/storage

									chmod g+x ${dataDir}/storage ${dataDir}/storage/app
									chmod -R g+rX ${dataDir}/storage/app/public

									# Link the app.php in the runtime folder.
									# We cannot link the cache folder only because bootstrap folder needs to be writeable.
									ln -sf ${cfg.portfolio-pkgs}/bootstrap-static/app.php ${runtimeDir}/app.php

									cd ${cfg.portfolio-pkgs}
									php artisan key:generate
									php artisan config:cache
									php artisan route:cache
									php artisan view:cache
									'';
							};
							portfolio-migrade-db = {
								path = [ phpPackage ];
								script = "php artisan migrate";
								serviceConfig = {
									Type = "oneshot";
									User = user;
									Group = group;
									WorkingDirectory = cfg.portfolio-pkgs;
									Umask = "077";
								};
							};
							portfolio-migrade-db-FORCE = {
								path = [ phpPackage ];
								script = "php artisan migrate --force";
								serviceConfig = {
									Type = "oneshot";
									User = user;
									Group = group;
									WorkingDirectory = cfg.portfolio-pkgs;
									Umask = "077";
								};
							};
							portfolio-rollback-db = {
								path = [ phpPackage ];
								script = "php artisan migrate:rollback";
								serviceConfig = {
									Type = "oneshot";
									User = user;
									Group = group;
									WorkingDirectory = cfg.portfolio-pkgs;
									Umask = "077";
								};
							};
						};
					};
				};
			};
		};
}
