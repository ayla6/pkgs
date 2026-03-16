{
  buildGoModule,
  buildPackages,
  fetchFromGitHub,
  fetchNpmDeps,
  lib,
  nodejs_24,
  npmHooks,
  pkg-config,
  stdenv,
  ffmpeg-headless,
  libavif,
  libjxl,
  libwebp,
  taglib,
  zlib,
  nixosTests,
  nix-update-script,
  ffmpegSupport ? true,
  versionCheckHook,
}:
buildGoModule (finalAttrs: {
  pname = "navidrome-ayla";
  version = "0.0.6-unstable-2026-03-16";

  src = fetchFromGitHub {
    owner = "ayla6";
    repo = "navidrome";
    rev = "43158151d57c6deb91f51493bce5a2847175bbed";
    hash = "sha256-0rXSBsfPxeGsJGTjM0MSU2mKxNK0mWeGLb8m4p/sQCk=";
  };

  vendorHash = "sha256-cfyQnpHyM8FoRUQVPEezfPn7srY6Gr1kbK9RGJtqRTM=";

  npmRoot = "ui";

  npmDeps = fetchNpmDeps {
    inherit (finalAttrs) src;
    sourceRoot = "${finalAttrs.src.name}/ui";
    hash = "sha256-BOOslyb4OuDaw0OVc2xi1hsOp6LZgicaZr9EMs2iLF4=";
  };

  nativeBuildInputs = [
    buildPackages.makeWrapper
    nodejs_24
    npmHooks.npmConfigHook
    pkg-config
  ];

  overrideModAttrs = oldAttrs: {
    nativeBuildInputs = lib.filter (drv: drv != npmHooks.npmConfigHook) oldAttrs.nativeBuildInputs;
    preBuild = null;
  };

  buildInputs = [
    taglib
    zlib
  ];

  excludedPackages = [
    "plugins"
  ];

  ldflags = [
    "-X github.com/navidrome/navidrome/consts.gitSha=${finalAttrs.src.rev}"
    "-X github.com/navidrome/navidrome/consts.gitTag=${finalAttrs.src.rev}"
  ];

  env = lib.optionalAttrs stdenv.cc.isGNU {
    CGO_CFLAGS = toString ["-Wno-return-local-addr"];
  };

  postPatch = ''
    patchShebangs ui/bin/update-workbox.sh
  '';

  preBuild = ''
    make buildjs
  '';

  tags = [
    "netgo"
    "sqlite_fts5"
  ];

  nativeInstallCheckInputs = [versionCheckHook];
  doInstallCheck = true;

  postFixup = lib.optionalString ffmpegSupport ''
    wrapProgram $out/bin/navidrome \
      --prefix PATH : ${lib.makeBinPath [
      ffmpeg-headless
      libavif
      libjxl
      libwebp
    ]}
  '';

  passthru = {
    tests.navidrome = nixosTests.navidrome;
    updateScript = nix-update-script {};
  };

  meta = {
    description = "Music Server and Streamer compatible with Subsonic/Airsonic with my edits";
    mainProgram = "navidrome";
    homepage = "https://github.com/ayla6/navidrome";
    license = lib.licenses.gpl3Only;
    sourceProvenance = with lib.sourceTypes; [fromSource];
    # Broken on Darwin: sandbox-exec: pattern serialization length exceeds maximum (NixOS/nix#4119)
    broken = stdenv.hostPlatform.isDarwin;
  };
})
