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
  version = "0.0.6-unstable-2026-03-29";

  src = fetchFromGitHub {
    owner = "ayla6";
    repo = "navidrome";
    rev = "690c1ea36223ec4c9747b2054903053d271813c1";
    hash = "sha256-ZWExX/mHIuacdz7DnjYyJxSnbPsFmiLaCSqzI4zCJwc=";
  };

  vendorHash = "sha256-UQYMzpdV/j7hXj/bbSqEFneGIFiA+zdHdY8nKJAbzTQ=";

  npmRoot = "ui";

  npmDeps = fetchNpmDeps {
    inherit (finalAttrs) src;
    sourceRoot = "${finalAttrs.src.name}/ui";
    hash = "sha256-jY1ee8pWnr5AOIQ3rUSMtxtwqq2SCfchukptE8lh8Po=";
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

  env =
    {
      CGO_CFLAGS_ALLOW = "--define-prefix";
    }
    // lib.optionalAttrs stdenv.cc.isGNU {
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
  doInstallCheck = false;

  postFixup = lib.optionalString ffmpegSupport ''
    wrapProgram $out/bin/navidrome \
      --prefix PATH : ${lib.makeBinPath [
      ffmpeg-headless
      libavif
      libjxl
      libwebp
    ]}
  '';

  npmFlags = ["--legacy-peer-deps"];

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
