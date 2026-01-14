{
  description = "Bram Dell nix-darwin system flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:nix-darwin/nix-darwin/master";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    nix-homebrew.url = "github:zhaofengli/nix-homebrew";
    homebrew-core = {
      url = "github:homebrew/homebrew-core/master";
      flake = false;
    };
    homebrew-cask = {
      url = "github:homebrew/homebrew-cask/master";
      flake = false;
    };
  };

  outputs = inputs@{ self, nix-darwin, nixpkgs, nix-homebrew, homebrew-core, homebrew-cask }:
  let
    configuration = { pkgs, config, ... }: {

      nixpkgs.config.allowUnfree = true;

      # Set primary user for system-wide options like homebrew
      system.primaryUser = "brambeirens";

      # List packages installed in system profile. To search by name, run:
      # $ nix-env -qaP | grep wget
      environment.systemPackages =
        [
          pkgs.vim
          pkgs.warp-terminal
          pkgs.mkalias
          pkgs.obsidian
          pkgs.sherlock
          pkgs.firefox
          pkgs.vscode
          pkgs.the-unarchiver
          pkgs.mas
          pkgs.shottr
          pkgs.orbstack
        ];

      homebrew = {
        enable = true;
        brews = [
        ];
        casks = [
          "1password"
          "raindropio"
          "autodesk-fusion"
          "orcaslicer"
          # "lm-studio" # Requires Apple Silicon
          "tower"
          "remote-desktop-manager"
          "omnigraffle"
          "sublime-text" # pkgs.sublimetext4 doesn't exist in the nixpkgs-unstable channel
        ];
        masApps = {
          "Trello" = 1278508951;
          "HEIC Converter" = 1294126402;
          "Structured" = 1499198946;
        };
        onActivation.cleanup = "zap";
        onActivation.autoUpdate = true;
        onActivation.upgrade = true;
      };

      fonts.packages = [
        pkgs.jetbrains-mono
      ];

      system.defaults = {
        dock.orientation = "left";
        dock.persistent-apps = [
          "/System/Applications/Launchpad.app"
          "/Applications/Safari.app"
          "/System/Applications/Messages.app"
          "/System/Applications/Maps.app"
          "/System/Applications/Photos.app"
          "/System/Applications/FaceTime.app"
          "/System/Applications/Calendar.app"
          "/System/Applications/Contacts.app"
          "/System/Applications/Reminders.app"
          "/System/Applications/Notes.app"
          "/System/Applications/Freeform.app"
          "/System/Applications/TV.app"
          "/System/Applications/Music.app"
          "/System/Applications/App Store.app"
          "/System/Applications/System Settings.app"
        ];
        loginwindow.GuestEnabled = false;
      };

      # Necessary for using flakes on this system.
      nix.settings.experimental-features = "nix-command flakes";

      # Enable alternative shell support in nix-darwin.
      programs.fish.enable = true;

      # Install Xcode Command Line Tools if not present.
      system.activationScripts.xcode.text = ''
        # Install Xcode Command Line Tools if not present
        if ! /usr/bin/xcode-select -p &> /dev/null; then
          echo "Installing Xcode Command Line Tools..."
          /usr/bin/xcode-select --install
        fi
      '';

      # Set Git commit hash for darwin-version.
      system.configurationRevision = self.rev or self.dirtyRev or null;

      # Used for backwards compatibility, please read the changelog before changing.
      # $ darwin-rebuild changelog
      system.stateVersion = 6;

      # The platform the configuration will be used on.
      nixpkgs.hostPlatform = "x86_64-darwin";
    };
  in
  {
    # Build darwin flake using:
    # $ darwin-rebuild build --flake .#HackBook-Pro-van-Bram
    darwinConfigurations."HackBook-Pro-van-Bram" = nix-darwin.lib.darwinSystem {
      modules = [
        configuration
        nix-homebrew.darwinModules.nix-homebrew
        {
          nix-homebrew = {
            enable = true;
            user = "brambeirens";
            taps = {
              "homebrew/homebrew-core" = homebrew-core;
              "homebrew/homebrew-cask" = homebrew-cask;
            };
            mutableTaps = false;
          };
        }
        ({config, ...}: {
          homebrew.taps = builtins.attrNames config.nix-homebrew.taps;
        })
      ];
    };
  };
}
