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
  taglib,
  zlib,
  nixosTests,
  nix-update-script,
  ffmpegSupport ? true,
  versionCheckHook,
}:
buildGoModule (finalAttrs: {
  pname = "navidrome-ayla";
  version = "0.0.1";

  src = fetchFromGitHub {
    owner = "ayla6";
    repo = "navidrome";
    rev = "v${finalAttrs.version}";
    hash = "sha256-D5klksBww/lp/hEcXpLaGHZjdN+ED4hComqgtQ7e5+I=";
  };

  vendorHash = "sha256-BMqfBS5ssL1OhQEoBHC6G75sbb6jykdlz2mkJQGpMd8=";

  npmRoot = "ui";

  npmDeps = fetchNpmDeps {
    inherit (finalAttrs) src;
    sourceRoot = "${finalAttrs.src.name}/ui";
    hash = "sha256-EA2WM7xaqP7rS0pjx+yXwpjdauaduvDefmFH73eByxI=";
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

  CGO_CFLAGS = lib.optionals stdenv.cc.isGNU ["-Wno-return-local-addr"];

  postPatch = ''
    patchShebangs ui/bin/update-workbox.sh
  '';

  preBuild = ''
    make buildjs
  '';

  tags = [
    "netgo"
  ];

  nativeInstallCheckInputs = [versionCheckHook];
  doInstallCheck = true;

  postFixup = lib.optionalString ffmpegSupport ''
    wrapProgram $out/bin/navidrome \
      --prefix PATH : ${lib.makeBinPath [ffmpeg-headless]}
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
    maintainers = with lib.maintainers; [
      ayla6
    ];
    # Broken on Darwin: sandbox-exec: pattern serialization length exceeds maximum (NixOS/nix#4119)
    broken = stdenv.hostPlatform.isDarwin;
  };
})
