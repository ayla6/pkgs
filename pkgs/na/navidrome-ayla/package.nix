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
  version = "0.0.4";

  src = fetchFromGitHub {
    owner = "ayla6";
    repo = "navidrome";
    rev = "v${finalAttrs.version}";
    hash = "sha256-YE1tIzDnfWmVbqb7Zz2Pfs3a5gqu9u0Czhj2uECDNkE=";
  };

  vendorHash = "sha256-eDDYqEhTWEU/WaDMxKyM2c2ox6GYQh4v3oSwFZmY+9Y=";

  npmRoot = "ui";

  npmDeps = fetchNpmDeps {
    inherit (finalAttrs) src;
    sourceRoot = "${finalAttrs.src.name}/ui";
    hash = "sha256-vAPIFx1r4Pka/b3SPF1OhAFmZCj7rmPuihKcauURDik=";
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
    "-X github.com/navidrome/navidrome/consts.gitTag=v${finalAttrs.version}"
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
