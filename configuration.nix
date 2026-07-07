# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

# NixOS-WSL specific options are documented on the NixOS-WSL repository:
# https://github.com/nix-community/NixOS-WSL

# access unstable packages via pkgs.pkgs-unstable
{ config, lib, pkgs, inputs, ... }:
{
  # This populates variables globally across all login accounts & system services
  environment.sessionVariables = {
    ANTHROPIC_AUTH_TOKEN = "ollama";
    ANTHROPIC_BASE_URL = "http://localhost:11434";
    EDITOR="nvim";
    GIT_ROOT = "/mnt/wsl/projects/git";
    # Inform your global login shells where to locate the user socket channel
    DBUS_SESSION_BUS_ADDRESS = "unix:path=/run/user/1000/bus";
  };

  imports = [
    # include NixOS-WSL modules
    # ./hardware-configuration.nix
    # <nixos-wsl/modules>
  ];

  # Core architecture switches mapping the guest VM parameters
  wsl.enable = true;
  wsl.defaultUser = "mwoodpatrick";

  # Essential build tools and utilities required by modern Neovim plugins
  # (e.g., Mason compilation, Treesitter parsers, and Telescope searching)
  environment.systemPackages = with pkgs; [
    fd
    gcc
    git
    gnumake
    lua-language-server
    lua5_1
    luarocks
    ripgrep
    tmux
    unzip
    wget
    pkgs-unstable.neovim
    pkgs-unstable.ollama
    inputs.claude-code-nix.packages.${pkgs.system}.default
  ];

  # Centralized tool management frameworks
  programs = {
    neovim = {
      enable = true;
      defaultEditor = true; # Automatically assigns $EDITOR and $VISUAL to nvim
      viAlias = true;       # Maps 'vi' command to nvim
      vimAlias = true;      # Maps 'vim' command to nvim
    };

    bash = {
      interactiveShellInit = ''
        if [ -f $GIT_ROOT/dotfiles/bash/init.bash ]; then
          source $GIT_ROOT/dotfiles/bash/init.bash
        fi
      '';
      
      shellAliases = {
        ll = "ls -l";
        la = "ls -la";
        g  = "git";
        v  = "nvim";
        ".." = "cd ..";
        "nb" = "sudo nixos-rebuild boot";
        "ne" = "sudo nixos-rebuild edit";
        "ns" = "sudo nixos-rebuild switch --flake .#nixos";
      };
    };
  };

  # Enable NIX-LD to allow unpatched dynamic binaries (like Mason LSPs)
  # to locate their runtime interpreters automatically within the Nix store
  programs.nix-ld.enable = true;

  # Enable the foundational D-Bus system services
  services.dbus.enable = true;

  # Force systemd to instantiate user-space session buses automatically
  systemd.user.extraConfig = ''
     DefaultEnvironment="DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus"
   '';

  # Workaround for NixOS 26.05 activation bug under headless WSL states
  # Bypasses the broken user-space systemd reload loop during nixos-rebuild switch
  system.activationScripts.userUnits = "";

  # Enable declarative Nix experimental features
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  users.users.mwoodpatrick = {
    isNormalUser = true;
    description = "mwoodpatrick";
    extraGroups = [ "networkmanager" "wheel" "docker" ];
  };

  #  Enable the Unfree licenses required for proprietary GPU acceleration hooks
  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
  "claude-code"
];

  # Enable the Ollama Service 
  # Enable the background daemon service
  services.ollama = {
    enable = true;

    # use the unstable service version
    package = pkgs.pkgs-unstable.ollama;
  
    # Pre-seed and pins models to download automatically in the background
    loadModels = [ 
      "gemma4:12b" 
      "deepseek-r1:14b" 
    ];

    # Expose the API surface cleanly across internal WSL networking layers if needed
    host = "0.0.0.0";
    port = 11434;
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "26.05"; # Did you read the comment?
}
