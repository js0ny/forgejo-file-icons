{
  lib,
  stdenvNoCC,
  bash,
}:

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "forgejo-file-icons";
  version = "0-unstable-2026-03-05";

  src = lib.fileset.toSource {
    root = ./.;
    fileset = lib.fileset.unions [
      ./build.sh
      ./css
      ./icons
      ./LICENSE
      ./NOTICE
    ];
  };

  nativeBuildInputs = [ bash ];

  dontConfigure = true;

  buildPhase = ''
    runHook preBuild
    bash build.sh
    runHook postBuild
  '';

  # Layout mirrors Forgejo's custom dir so each path can be symlinked in place.
  # custom/public/assets/ is the webroot for /assets/.
  installPhase = ''
    runHook preInstall

    mkdir -p $out/public/assets/icons
    cp icons/*.svg $out/public/assets/icons/

    install -Dm644 templates/custom/header.tmpl $out/templates/custom/header.tmpl
    install -Dm644 LICENSE $out/share/doc/${finalAttrs.pname}/LICENSE
    install -Dm644 NOTICE $out/share/doc/${finalAttrs.pname}/NOTICE

    runHook postInstall
  '';

  meta = {
    description = "File-type icons for Forgejo's repository file browser";
    homepage = "https://git.cathedral.gg/Ben/forgejo-file-icons";
    # Build scripts and CSS are MIT; redistributed SVGs are MIT and Apache 2.0.
    license = with lib.licenses; [
      mit
      asl20
    ];
    platforms = lib.platforms.all;
  };
})
