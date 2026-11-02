# Everything every host gets: laptops, desktops and homelab servers.
{
  config,
  lib,
  pkgs,
  inputs,
  user,
  hostname,
  flakeDir,
  ...
}:
{
  networking.hostName = hostname;

  nix = {
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      trusted-users = [
        "root"
        "@wheel"
      ];
      # Emergency GC: if free space drops below 5 GiB during a build, Nix
      # collects garbage until 20 GiB are free (only unreferenced paths).
      min-free = 5 * 1024 * 1024 * 1024;
      max-free = 20 * 1024 * 1024 * 1024;
    };
    # Dedupe identical files weekly instead of on every build
    # (auto-optimise-store slows down each build).
    optimise = {
      automatic = true;
      dates = [ "weekly" ];
    };
    # Generations are pruned by `nh clean` below, not nix.gc.
    # `nix run nixpkgs#foo` and <nixpkgs> use the same nixpkgs as the system.
    registry.nixpkgs.flake = inputs.nixpkgs;
    nixPath = [ "nixpkgs=${inputs.nixpkgs}" ];
    channel.enable = false;
  };
  nixpkgs.config.allowUnfree = true;

  # nh: `nh os switch` / `nh os boot` / `nh os build` with a diff of what changes,
  # `nh search`, and periodic cleanup that always keeps recent generations.
  #
  # Weekly, for system + Home Manager + user profiles: keep the newest 5
  # generations and anything from the last 7 days, delete the rest, then GC.
  # --no-gcroots leaves `result` links and direnv/nix-direnv shells alone, so
  # project devShells don't get re-downloaded after every cleanup.
  programs.nh = {
    enable = true;
    flake = flakeDir;
    clean = {
      enable = true;
      dates = "weekly";
      extraArgs = "--keep 5 --keep-since 7d --no-gcroots";
    };
  };

  # Boot: systemd-boot on UEFI by default; hosts override when needed.
  # Boot menu shows the last 10 generations; this also caps kernels/initrds
  # on the 1 GiB ESP (older generations stay rollback-able via
  # `nixos-rebuild switch --rollback` until nh clean removes them).
  boot.loader.systemd-boot = {
    enable = lib.mkDefault true;
    configurationLimit = lib.mkDefault 10;
  };
  boot.loader.efi.canTouchEfiVariables = lib.mkDefault true;
  boot.tmp.cleanOnBoot = true;

  # Locale: English UI, Brazilian formats and keyboard. Hosts can override.
  time.timeZone = lib.mkDefault "America/Sao_Paulo";
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = lib.genAttrs [
    "LC_ADDRESS"
    "LC_IDENTIFICATION"
    "LC_MEASUREMENT"
    "LC_MONETARY"
    "LC_NAME"
    "LC_NUMERIC"
    "LC_PAPER"
    "LC_TELEPHONE"
    "LC_TIME"
  ] (_: "pt_BR.UTF-8");
  console.keyMap = lib.mkDefault "br-abnt2";
  services.xserver.xkb = {
    layout = lib.mkDefault "br";
    variant = lib.mkDefault "thinkpad";
  };

  networking.networkmanager.enable = lib.mkDefault true;
  networking.firewall.enable = true;

  # Key-only SSH with the keys in keys/osdva.pub (hosts can add more). The port
  # stays closed unless a role opens it (server.nix), so laptops on public
  # networks don't expose sshd.
  services.openssh = {
    enable = true;
    openFirewall = lib.mkDefault false;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
    };
  };

  services.fstrim.enable = true;
  services.fwupd.enable = true;
  hardware.enableRedistributableFirmware = true;

  security.sudo.wheelNeedsPassword = lib.mkDefault true;

  programs.fish.enable = true;
  # Users and groups are fully declarative; passwords live in hashedPasswordFile
  # or are set once with `passwd` (mutableUsers keeps that working).
  users.users.${user} = {
    isNormalUser = true;
    description = "Arthur Diniz";
    extraGroups = [
      "wheel"
      "networkmanager"
    ];
    shell = pkgs.fish;
    openssh.authorizedKeys.keyFiles = [ ../../../keys/osdva.pub ];
  };

  environment.systemPackages = with pkgs; [
    git
    curl
    wget
    vim
    usbutils
    pciutils
  ];

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "hm-backup";
    extraSpecialArgs = {
      inherit
        inputs
        user
        hostname
        flakeDir
        ;
    };
    users.${user} = {
      imports = [ ../../../home ];
      # Like system.stateVersion: the release this host was first installed with.
      home.stateVersion = lib.mkDefault config.system.stateVersion;
    };
  };
}
