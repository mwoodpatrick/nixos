{ config, pkgs, ... }:

{
  # 1. Core Home Manager State Setup
  # Replace with your actual user environment details
  home.username = "mwoodpatrick";
  home.homeDirectory = "/home/mwoodpatrick";

  # This value determines the Home Manager release that your configuration is
  # compatible with. Must map to your stable system state variant.
  # This value determines the Home Manager release that your configuration is
  # compatible with. This helps avoid breakage when a new Home Manager release
  # introduces backwards incompatible changes.
  #
  # You should not change this value, even if you update Home Manager. If you do
  # want to update the value, then make sure to first check the Home Manager
  # release notes.

  home.stateVersion = "26.05"; 

  # 2. User-specific CLI Toolsets
  # Installs tools directly inside the user's execution profile path
  home.packages = with pkgs; [
    git
    gh                  # GitHub official CLI engine
    ripgrep             # Optimal regex finder for tools like Telescope/Nvim
    fd                  # Fast user directory scanner dependency
    bubblewrap          # Sandboxing toolkit utility used for security boundaries
    slirp4netns         # User-space network engine for rootless sandboxes
    atool 
    httpie 
    htop
    fortune
    pyright
  ];

  # 3. Automated Git Architecture Configurations
  # Ties directly into your upstream tracking layout definitions
  programs.git = {
    enable = true;
    settings = {
      user = {
        name = "mwoodpatrick";
        email = "mwoodpatrick@gmail.com";
      };
      init = {
        defaultBranch = "main";
      };
      push = {
        autoSetupRemote = true;
      };
    };
  };

  programs.starship = {
    enable = false;
     enableBashIntegration = true; # Automatically hooks it into Bash initExtra [2]
  };

  # 4. Interactive Shell Integrations
  # Replaces legacy mutable config lookups with deterministic configurations
  programs.bash = {
    enable = true;
    enableCompletion = true;
    
    # Declarative aliases mapping clean operational steps
    shellAliases = {
      # Everyday administrative alias chains matching your layout requirements
      nix-switch = "sudo nixos-rebuild switch --flake /etc/nixos/#nixos";
      nix-add    = "sudo git add /etc/nixos/";
      nix-commit = "sudo git commit -m 'config: update flake definitions'";
      nix-push   = "sudo git push origin main";
      ll = "ls -l";
      la = "ls -la";
      g = "git";
      v = "nvim";
      ".." = "cd ..";
      "nb" = "sudo nixos-rebuild boot";
      "ne" = "sudo nixos-rebuild edit";
      "ns" = "sudo nixos-rebuild switch --flake /etc/nixos/#nixos";
    };

    # Extra lines to run during interactive shell sessions
    # This works perfectly here because it's wrapped safely inside user 'eve' [1.2.5]
    initExtra = ''
      # Dynamically search for the file path on your file system
      if [ -f "/mnt/wsl/projects/git/dotfiles/bash/init.bash" ]; then
        source "/mnt/wsl/projects/git/dotfiles/bash/init.bash"
      fi
    '';
  
    # Controls Bash history configuration
    # historySize = 10000;
    # historyFileSize = 50000;
    # historyControl = [ "ignoredups" "ignorespace" ]; # Don't record duplicate commands or commands starting with a space
    
    # Useful shell options to enable automatically
    shellOptions = [
      "autocd"   # Typing a directory name directly will cd into it
      "cdspell"  # Minor typos in directory names will be automatically corrected
      "cmdhist"  # Save multi-line commands as a single history entry
    ];
      
    # Extra lines to run for ALL login shells (both interactive and script sessions)
    profileExtra = ''
      # Environment variables or path scripts
      export PATH="$HOME/.local/bin:$PATH"
    '';
  };

  # 5. Declarative User Space Neovim Management
  # Configures binary routing matching how platforms look up packages safely

  programs.neovim = {
    enable = true;
    viAlias = true;
    vimAlias = true;
    vimdiffAlias = true;

    # 1. CRITICAL FLIP: Tell Home Manager not to create an init.lua file
    # This prevents Home Manager from creating symlinks over your files
    # Safe null configuration bypass option matching new option standards
    initLua = "";

    # Injects system requirements matching language runtime dependencies
    extraPackages = with pkgs; [
      gcc               # C Compiler needed to assemble nvim-treesitter modules
      gnumake           # Build automation engines
      nodejs_22         # JS backend processing dependency engine
    ];
  };

  # 6. Environmental Handshakes
  # Explicitly forces system applications to look up Nix store symlinks smoothly
  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
  };

  # Let Home Manager install and manage itself declaratively
  programs.home-manager.enable = true;
}
