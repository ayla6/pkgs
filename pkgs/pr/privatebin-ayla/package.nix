{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
  nix-update-script,
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "privatebin-ayla";
  version = "0.0.1";

  src = fetchFromGitHub {
    owner = "ayla6";
    repo = "PrivateBin";
    rev = finalAttrs.version;
    sha256 = "sha256-+Ku/2gus0qqJeSuGlJPlECGXnZ6j6YdGH2QSrg5ehzE=";
  };

  installPhase = ''
    runHook preInstall
    mkdir -p $out
    cp -R $src/* $out
    runHook postInstall
  '';

  passthru.updateScript = nix-update-script {};

  meta = {
    changelog = "https://github.com/PrivateBin/PrivateBin/releases/tag/${finalAttrs.version}";
    description = "Minimalist, open source online pastebin where the server has zero knowledge of pasted data";
    homepage = "https://github.com/ayla6/PrivateBin";
    license = with lib.licenses; [
      # privatebin
      zlib
      # dependencies, see https://github.com/PrivateBin/PrivateBin/blob/master/LICENSE.md
      gpl2Only
      bsd3
      mit
      asl20
      cc-by-40
    ];
  };
})
