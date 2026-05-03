{
  config,
  pkgs,
  lib,
  ...
}:
{
  options = {
    boot.initrd.supportedFilesystems.luks = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = ''
          Whether to enable LUKS encrypted device support in the initial ramdisk.

          This is set automatically when {option}`neededForBoot` is `true` on a
          LUKS fileSystem entry.

          To use LUKS, declare a {option}`fileSystems` entry with {option}`fsType`
          set to `"luks"`. The attribute name is used as the device mapper name,
          and {option}`device` should point to the LUKS partition. You must set
          {option}`neededForBoot` to `true` on this entry so that it is unlocked
          in the initial ramdisk.

          Options set in the {option}`options` attribute are passed as flags to
          {command}`cryptsetup open`.

          ::: {.example}
          ### Encrypted root partition with discards

          ```nix
          fileSystems."/dev/mapper/root" = {
            device = "/dev/sda2";
            fsType = "luks";
            neededForBoot = true;
            options = [ "--allow-discards" ];
          };

          fileSystems."/" = {
            device = "/dev/mapper/root";
            fsType = "ext4";
          };
          ```
          :::
        '';
      };

      packages = lib.mkOption {
        type = with lib.types; listOf package;
        default = [pkgs.cryptsetup];
        description = ''
          Packages providing LUKS utilities in the initial ramdisk.
        '';
      };
    };

    boot.supportedFilesystems.luks = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = ''
          Whether to enable LUKS encrypted device support.
        '';
      };

      packages = lib.mkOption {
        type = with lib.types; listOf package;
        default = [pkgs.cryptsetup];
        description = ''
          Packages providing LUKS utilities.
        '';
      };
    };
  };

  config = lib.mkMerge [
    (lib.mkIf config.boot.initrd.supportedFilesystems.luks.enable {
      boot.kernelModules = [ "dm_mod" "dm_crypt" ];

      boot.initrd.availableKernelModules = [
        "dm_mod"
        "dm_crypt"
        "aes"
        "blowfish"
        "twofish"
        "serpent"
        "cbc"
        "xts"
        "lrw"
        "ecb"
        "sha1"
        "sha256"
        "sha512"
        "af_alg"
        "algif_skcipher"
        "cryptd"
        "input_leds"
      ] ++ lib.optionals (lib.versionOlder config.boot.kernelPackages.kernel.version "7.0") [ "aes_generic" ];

      boot.initrd.fileSystemImportCommands = lib.mkOrder 500 (lib.concatStringsSep "\n" (
        lib.mapAttrsToList (
          name: dev:
          let
            fsOpts = lib.concatStringsSep " " (lib.filter (o: o != "defaults") dev.options);
          in
          "cryptsetup open ${fsOpts} ${dev.device} ${name}"
        ) (lib.filterAttrs (_: fs: fs.fsType == "luks") config.fileSystems)
      ));
    })
  ];
}
