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

				devShells.default = pkgs.mkShell {
					packages = with pkgs; [ nodejs zsh ];
					shellHook = ''
						export SHELL=zsh
						exec zsh
					'';
				};

				# Website and build
				packages = rec {
					website = pkgs.buildNpmPackage rec {
						pname = "portfolio-${version}";
						version = "dev";
						src = ./.;
						npmDepsHash = "sha256-QlTJvdiyS29sWAzJVzVJTHnmS4Y2ZRmVwCJiipyxhQM=";
						installPhase = ''
							mkdir -p $out
							cp -r dist/* $out
							'';
					};
					default = website;
				};
			};
		};
}
