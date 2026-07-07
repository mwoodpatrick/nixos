{
  description = "NixOS WSL-2 System Configuration Flake";

  inputs = {
    # Pinned stable package stream for NixOS 26.05
    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";

    # Fast-moving unstable stream utilized to selectively override target mismatched services
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    # Community launcher tools integration framework for native WSL capabilities
    nixos-wsl.url = "github:nix-community/NixOS-WSL/main";
    nixos-wsl.inputs.nixpkgs.follows = "nixpkgs";

    # Declarative user-space dotfile profile management (Optional)
    home-manager.url = "github:nix-community/home-manager/release-26.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    # Claude code
    claude-code-nix.url = "github:sadjow/claude-code-nix";
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, nixos-wsl, home-manager, ... }@inputs:
    let
      system = "x86_64-linux";
    in {
      nixosConfigurations = {
        # This string must match your target system identifier attribute node
        nixos = nixpkgs.lib.nixosSystem {
          inherit system;

          # Makes external input channels cleanly available down within evaluation modules
          specialArgs = { inherit inputs; };

          modules = [
            # Pulls in necessary architecture optimizations for running under Windows Hyper-V
            nixos-wsl.nixosModules.default

            # Links your core layout options file directly into the graph
            ./configuration.nix
            
            # Machine-specific storage block mounts mapping file
            # ./hardware-configuration.nix

            # Embedded overlay setup block to declare and expose 'pkgs-unstable'
            ({ config, pkgs, ... }: {
              nixpkgs.overlays = [
                (final: prev: {
                  pkgs-unstable = import nixpkgs-unstable {
                    inherit system;
                    config.allowUnfree = true;
                  };
                })
              ];
            })

            # Home Manager inline integration mapping (omit if using standalone runner)
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              # Replace with your local system user name string
              home-manager.users.mwoodpatrick = import ./home.nix; 
            }
          ];
        };
      };
    };
}
