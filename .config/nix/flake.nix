{
  description = "Example nix-darwin system flake";

  nixConfig = {
    substituters = [
      # Query the mirror of USTC first, and then the official cache.
      "https://mirrors.ustc.edu.cn/nix-channels/store"
      "https://cache.nixos.org"
    ];
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-homebrew.url = "github:zhaofengli-wip/nix-homebrew";
    # Optional: Declarative tap management
    homebrew-core = {
      url = "github:homebrew/homebrew-core";
      flake = false;
    };
    homebrew-cask = {
      url = "github:homebrew/homebrew-cask";
      flake = false;
    };
    homebrew-bundle = {
      url = "github:homebrew/homebrew-bundle";
      flake = false;
    };
  };

  outputs =
    inputs@{
      self,
      nix-darwin,
      nixpkgs,
      home-manager,
      nix-homebrew,
      homebrew-core,
      homebrew-cask,
      homebrew-bundle,
    }:
    let
      configuration =
        { pkgs, ... }:
        {
          # List packages installed in system profile. To search by name, run:
          # $ nix-env -qaP | grep wget
          environment.systemPackages = with pkgs; [ git ];
          environment.variables = {
            EDITOR = "vim";
          };

          # Necessary for using flakes on this system.
          nix.settings = {
            # enable flakes globally
            experimental-features = [
              "nix-command"
              "flakes"
            ];
            # substituers that will be considered before the official ones(https://cache.nixos.org)
            substituters = [
              "https://mirror.sjtu.edu.cn/nix-channels/store"
              "https://nix-community.cachix.org"
            ];
            trusted-public-keys = [
              "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
            ];

            trusted-users = [
              "root"
              "fwc"
            ];
            trusted-substituters = [
              "https://mirror.sjtu.edu.cn/nix-channels/store"
              "https://nix-community.cachix.org"
            ];
            builders-use-substitutes = true;
          };

          homebrew = {
            enable = true;

            onActivation = {
              autoUpdate = true;
              upgrade = false;
              # 'zap': uninstalls all formulae(and related files) not listed here.
              # cleanup = "zap";
            };

            taps = [ ];

            # brew install
            brews = [ ];
            # brew install --cask
            # these need to be updated manually
            casks = [
              "raycast"
              "warp"
            ];

            # mac app store
            # click
            masApps = { };
          };

          services.nix-daemon.enable = true;
          nix.package = pkgs.nix;
          nixpkgs.config.allowUnfree = true;

          users.users.fwc = {
            name = "fwc";
            home = "/Users/fwc";
          };

          # Enable alternative shell support in nix-darwin.
          # programs.fish.enable = true;
          # programs.zsh.enable = true;

          fonts.packages = with pkgs; [
            nerd-fonts.fira-code
            nerd-fonts.jetbrains-mono
          ];

          security.pam.enableSudoTouchIdAuth = true;

          # Set Git commit hash for darwin-version.
          system.configurationRevision = self.rev or self.dirtyRev or null;

          # Used for backwards compatibility, please read the changelog before changing.
          # $ darwin-rebuild changelog
          system = {
            stateVersion = 5;
            activationScripts.postUserActivation.text = ''
              # activateSettings -u will reload the settings from the database and apply them to the current session,
              # so we do not need to logout and login again to make the changes take effect.
              /System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u
            '';
            defaults = {
              trackpad.Clicking = true;
              trackpad.TrackpadRightClick = true;
              trackpad.Dragging = true;
              trackpad.TrackpadThreeFingerDrag = true;

              NSGlobalDomain.AppleShowAllFiles = true;
              NSGlobalDomain.AppleShowAllExtensions = true;
              NSGlobalDomain.AppleInterfaceStyleSwitchesAutomatically = true;
              NSGlobalDomain.NSAutomaticCapitalizationEnabled = false;
              NSGlobalDomain.NSDocumentSaveNewDocumentsToCloud = false;
              NSGlobalDomain.InitialKeyRepeat = 15;
              NSGlobalDomain.KeyRepeat = 3;
              NSGlobalDomain.NSAutomaticDashSubstitutionEnabled = false; # disable auto dash substitution(智能破折号替换)
              NSGlobalDomain.NSAutomaticPeriodSubstitutionEnabled = false; # disable auto period substitution(智能句号替换)
              NSGlobalDomain.NSAutomaticQuoteSubstitutionEnabled = false; # disable auto quote substitution(智能引号替换)
              NSGlobalDomain.NSAutomaticSpellingCorrectionEnabled = false; # disable auto spelling correction(自动拼写检查)
              NSGlobalDomain.NSNavPanelExpandedStateForSaveMode = true; # expand save panel by default(保存文件时的路径选择/文件名输入页)
              NSGlobalDomain.NSNavPanelExpandedStateForSaveMode2 = true;

              dock.minimize-to-application = true;
              dock.autohide = true;

              screencapture.location = "~/Pictures/Screenshots";

              finder._FXShowPosixPathInTitle = true;
              finder.AppleShowAllExtensions = true;
              finder.FXEnableExtensionChangeWarning = false;
              finder.AppleShowAllFiles = true;
              finder.ShowStatusBar = true;
              finder.ShowPathbar = true;
              finder.FXDefaultSearchScope = "SCcf";
              finder.FXPreferredViewStyle = "Nlsv";
              finder.QuitMenuItem = true;
            };

            keyboard.enableKeyMapping = true;
            # keyboard.remapCapsLockToControl = true;
          };

          # The platform the configuration will be used on.
          nixpkgs.hostPlatform = "aarch64-darwin";
        };

      homeconfig =
        { pkgs, ... }:
        {
          # this is internal compatibility configuration for home-manager,
          # don't change this!
          home.stateVersion = "24.11";
          # Let home-manager install and manage itself.
          programs.home-manager.enable = true;

          home.packages = with pkgs; [
            go
            rustup
            aria2
          ];
          programs.zsh = {
            enable = true;
            enableCompletion = true;
            autosuggestion.enable = true;
            syntaxHighlighting.enable = true;
            historySubstringSearch.enable = true;
            oh-my-zsh = {
              enable = true;
              theme = "rkj-repos"; # xiong-chiamiov
            };
            shellAliases = {
              grep = "grep --binary-files=without-match";
              ll = "ls -al";
              switch = "darwin-rebuild switch --flake ~/.config/nix";
            };
            sessionVariables = {
              RUSTUP_DIST_SERVER = "https://rsproxy.cn";
              RUSTUP_UPDATE_ROOT = "https://rsproxy.cn/rustup";
              HOMEBREW_API_DOMAIN = "https://mirrors.tuna.tsinghua.edu.cn/homebrew-bottles/api";
              HOMEBREW_BOTTLE_DOMAIN = "https://mirrors.tuna.tsinghua.edu.cn/homebrew-bottles";
              HOMEBREW_BREW_GIT_REMOTE = "https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/brew.git";
              HOMEBREW_CORE_GIT_REMOTE = "https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/homebrew-core.git";
              HOMEBREW_PIP_INDEX_URL = "https://pypi.tuna.tsinghua.edu.cn/simple";
              ANDROID_HOME = "/Users/fwc/Library/Android/sdk";
              PATH = "$ANDROID_HOME/tools:$ANDROID_HOME/tools/bin:$ANDROID_HOME/platform-tools:$PATH";
            };
          };

          programs.git = {
            enable = true;
            userName = "fwc";
            userEmail = "1643806656@qq.com";
            ignores = [ ".DS_Store" ];
            extraConfig = {
              init.defaultBranch = "master";
              push.autoSetupRemote = true;
            };
          };

        };
    in
    {
      # Build darwin flake using:
      # $ darwin-rebuild build --flake .#FeiWenChunDeMacBook-Pro
      darwinConfigurations."MacBook-Pro" = nix-darwin.lib.darwinSystem {
        modules = [
          configuration
          home-manager.darwinModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.verbose = true;
            home-manager.users.fwc = homeconfig;
          }
          nix-homebrew.darwinModules.nix-homebrew
          {
            nix-homebrew = {
              # Install Homebrew under the default prefix
              enable = true;

              # Apple Silicon Only: Also install Homebrew under the default Intel prefix for Rosetta 2
              enableRosetta = false;

              # User owning the Homebrew prefix
              user = "fwc";

              # Optional: Declarative tap management
              taps = {
                "homebrew/homebrew-core" = homebrew-core;
                "homebrew/homebrew-cask" = homebrew-cask;
                "homebrew/homebrew-bundle" = homebrew-bundle;
              };

              # Optional: Enable fully-declarative tap management
              #
              # With mutableTaps disabled, taps can no longer be added imperatively with `brew tap`.
              mutableTaps = false;
            };
          }
        ];
      };
    };
}
