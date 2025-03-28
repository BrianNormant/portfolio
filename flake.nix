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
				# Front-End
				devShells.website = pkgs.mkShell {
					packages = with pkgs; [ nodejs zsh ];
					shellHook = ''
						export SHELL=zsh
						cd ./web
						exec zsh
					'';
				};
				packages.portfolio-website = pkgs.buildNpmPackage rec {
					pname = "portfolio-${version}";
					version = "dev";
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
				packages.portfolio-api = pkgs.php84.buildComposerProject rec {
					pname = "portfolio-api";
					version = "0.0.1";

					src = ./api;
					composerLock = ./api/composer.lock;
					vendorHash = "sha256-L/dVhIO6qza4vzaC4pLAlwDsO2kXmYa4mQjxi15qHwU=";

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
					'';
				};
			};
		};
}
