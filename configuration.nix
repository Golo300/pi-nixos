{ pkgs, lib, ... }:
let
  ssh-key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOb9qR65i6UTSF92nnOYZZ3zxRyIxv9ApS702G01mabG Tim.lanzinger@gmx.de";
in
{
  # NixOS wants to enable GRUB by default
  boot.loader.grub.enable = false;
  # Enables the generation of /boot/extlinux/extlinux.conf
  boot.loader.generic-extlinux-compatible.enable = true;

  # !!! Set to specific linux kernel version
  boot.kernelPackages = pkgs.linuxPackages;

  # Disable ZFS on kernel 6
  boot.supportedFilesystems = lib.mkForce [
    "vfat"
    "xfs"
    "cifs"
    "ntfs"
  ];

  # !!! Needed for the virtual console to work on the RPi 3, as the default of 16M doesn't seem to be enough.
  # If X.org behaves weirdly (I only saw the cursor) then try increasing this to 256M.
  # On a Raspberry Pi 4 with 4 GB, you should either disable this parameter or increase to at least 64M if you want the USB ports to work.
  #boot.kernelParams = [ "cma=256M" ];

  # File systems configuration for using the installer's partition layout
  fileSystems = {
    "/" = {
      device = "/dev/disk/by-label/NIXOS_SD";
      fsType = "ext4";
    };
  };

  swapDevices = [{ device = "/swapfile"; size = 2048; }];

  environment.systemPackages = with pkgs; [
    vim
    curl
    wget
    git
    htop
  ];

  services.openssh = {
    enable = true;
    ports = [ 22 ];
    openFirewall = true;

    /* allow root login for remote deploy aka. rebuild-switch  */
    settings.AllowUsers = [ "timl" "root" ];
    settings.PermitRootLogin = "yes";

    /* require public key authentication for better security */
    settings.PasswordAuthentication = false;
    settings.KbdInteractiveAuthentication = false;
  };


  # WiFi
  hardware = {
    enableRedistributableFirmware = true;
    firmware = [ pkgs.wireless-regdb ];
  };

  networking = {
    firewall.enable = false;

    # useDHCP = true;
    interfaces.eth0 = {
      # I used DHCP because sometimes I disconnect the LAN cable
      #ipv4.addresses = [{
      #  address = "192.168.100.3";
      #  prefixLength = 24;
      #}];
    };

    # Enabling WIFI
    wireless.enable = true;
    wireless.interfaces = [ "wlan0" ];
    # If you want to connect also via WIFI to your router
    # wireless.networks."SATRIA".psk = "wifipassword";
    # You can set default nameservers
    # nameservers = [ "192.168.100.3" "192.168.100.4" "192.168.100.1" ];
    # You can set default gateway
    # defaultGateway = {
    #  address = "192.168.1.1";
    #  interface = "eth0";
    # };
  };

  # forwarding
  boot.kernel.sysctl = {
    "net.ipv4.conf.all.forwarding" = true;
    "net.ipv6.conf.all.forwarding" = true;
    "net.ipv4.tcp_ecn" = true;
  };

  users.mutableUsers = true;
  users.groups = {
    timl = {
      gid = 1000;
      name = "timl";
    };
  };
  users.users = {
    timl = {
      uid = 1000;
      home = "/home/timl";
      isNormalUser = true;
      name = "timl";
      group = "timl";
      extraGroups = [ "wheel" ];
    };
  };
  users.users.root.openssh.authorizedKeys.keys = [ ssh-key ];
  users.users.timl.openssh.authorizedKeys.keys = [ ssh-key ];

  system.stateVersion = "23.05";
}
