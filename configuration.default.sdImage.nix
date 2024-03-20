{ config, pkgs, lib, ... }:

{
   # overlay = final: super: {
     makeModulesClosure = x:
     super.makeModulesClosure (x // { allowMissing = true; });
   };
  # nixosHardwareVersion = "7f1836531b126cfcf584e7d7d71bf8758bb58969";
  # imports = ["${fetchTarball "https://github.com/NixOS/nixos-hardware/archive/${nixosHardwareVersion}.tar.gz" }/raspberry-pi/4"];
  imports = [
    <nixpkgs/nixos/modules/installer/cd-dvd/sd-image-aarch64.nix>
    <nixpkgs/nixos/modules/installer/cd-dvd/channel.nix>
  ];
  sdImage.compressImage = true;

  fileSystems = {
    "/" = {
      device = "/dev/disk/by-label/NIXOS_SD";
      fsType = "ext4";
      options = [ "noatime" ];
    };
  };
  # nixpkgs.overlays = [ overlay ];
  config.system.build.sdImage.compressImage = false;
  
  networking.networkmanager.enable = true;
  services.openssh.enable = true;
  time.timeZone = "Europe/Istanbul";
  services.tailscale.enable = true;
  hardware.raspberry-pi."4".fkms-3d.enable = true;
  hardware.enableRedistributableFirmware = true;
  nixpkgs.config.allowUnfree = true;
  system.stateVersion = "23.11";
  swapDevices = [{ device = "/swapfile"; size = 2048; }]; 
  security.polkit.enable = true;

  networking.firewall = {
    enable = true;
    trustedInterfaces = [ "tailscale0" ];
    allowedUDPPorts = [ config.services.tailscale.port ];
    allowedTCPPorts = [ config.services.tailscale.port 5901 ];
  };

  environment.systemPackages = with pkgs; [
    libraspberrypi raspberrypi-eeprom
    curl
    nixos-generators
    xorg.xinit
    glxinfo
    vim
    git
    lshw
    socat
    chromium
    nix-index
    unzip zip 
    wget
    neatvnc turbovnc x11vnc 
    xz
    zlib
    tailscale
    geany
    yazi alacritty alacritty-theme gnome.gnome-font-viewer gnome.gnome-logs gnome.gnome-system-monitor gnome.nautilus gnome.gnome-terminal
    gnome.eog gnome.totem gnome-photos gnome.gnome-tweaks gnome.gnome-themes-extra gnome.gnome-system-monitor gnome.gnome-software gnome.gnome-shell-extensions
    gnome.gnome-remote-desktop nautilus-open-any-terminal    
  ];

  users = {
    mutableUsers = false;
    users."pi" = {
      isNormalUser = true;
      password = "admin";
      extraGroups = [ "wheel" ];
    };
  };

  security.sudo.extraRules = [
    {  users = [ "pi" ];
       commands = [
         { command = "ALL" ;
           options= [ "NOPASSWD" ];
        }
      ];
    }
  ];

  services.xserver = {
    videoDrivers = [ "modesetting" ];
    enable       = true;
    xkbVariant = "";
    layout = "en";
    enableCtrlAltBackspace = true;
    displayManager = {
      autoLogin.enable = true;
      autoLogin.user = "pi";
      gdm.enable = true;
    };
    desktopManager.gnome.enable = true;
  };

  services.gnome.core-utilities.enable = false;

  environment.shellAliases = {
    raspi-cpu = ''
      sudo vcgencmd get_throttled && sudo vcgencmd measure_temp
    '';
    raspi-firmware-update = ''
      sudo mkdir -p /mnt && \
      sudo mount /dev/disk/by-label/FIRMWARE /mnt && \
      BOOTFS=/mnt FIRMWARE_RELEASE_STATUS=stable sudo -E rpi-eeprom-update -d -a && \
      sudo umount /mnt
    '';
  };

  services.xserver.displayManager.sessionCommands = ''
     ${pkgs.x11vnc}/bin/x11vnc -rfbauth $HOME/.vnc/passwd -forever -shared -bg -display :0 &
     '';
}


  
