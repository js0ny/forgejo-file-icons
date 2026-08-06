{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.services.forgejo-file-icons;
  forgejo = config.services.forgejo;
  inherit (forgejo) customDir user group;
in
{
  options.services.forgejo-file-icons = {
    enable = lib.mkEnableOption "file-type icons for Forgejo's repository file browser";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.callPackage ./package.nix { };
      defaultText = lib.literalExpression "pkgs.callPackage ./package.nix { }";
      description = "Package providing the icon assets and the generated header.tmpl.";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = forgejo.enable;
        message = "services.forgejo-file-icons requires services.forgejo.enable = true.";
      }
    ];

    # The forgejo module already creates customDir itself; only the subdirs
    # holding our two symlinks need declaring. L+ replaces whatever is there,
    # so switching generations is idempotent.
    systemd.tmpfiles.rules = [
      "d '${customDir}/public' 0750 ${user} ${group} - -"
      "d '${customDir}/public/assets' 0750 ${user} ${group} - -"
      "L+ '${customDir}/public/assets/icons' - - - - ${cfg.package}/public/assets/icons"
      "d '${customDir}/templates' 0750 ${user} ${group} - -"
      "d '${customDir}/templates/custom' 0750 ${user} ${group} - -"
      "L+ '${customDir}/templates/custom/header.tmpl' - - - - ${cfg.package}/templates/custom/header.tmpl"
    ];

    # Forgejo parses templates once at startup outside dev mode.
    systemd.services.forgejo.restartTriggers = [ cfg.package ];
  };
}
