{
  nix-update-script,
  lib,
  stdenv,
  fetchFromGitHub,
  cmake,
  pkg-config,
  meson,
  ninja,
  qt6,
}:
stdenv.mkDerivation rec {
  pname = "oplpctools";
  version = "3.1";

  src = fetchFromGitHub {
    owner = "brainstream";
    repo = "OPL-PC-Tools";
    rev = version;
    hash = "sha256-Qn7V/N2K+0BQUXj9lirZsWzTvXcxqbBOTOLYS4rmuUk=";
  };

  nativeBuildInputs = [cmake pkg-config meson ninja qt6.wrapQtAppsHook];
  buildInputs = [qt6.qtbase qt6.qttools];

  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin
    cp oplpctools $out/bin/
    runHook postInstall
  '';

  passthru.updateScript = nix-update-script {};

  meta = with lib; {
    homepage = "https://github.com/brainstream/OPL-PC-Tools";
    description = "OPL PC Tools";
    platforms = ["x86_64-linux"];
    license = licenses.mit;
    mainprogram = "oplpctools";
  };
}
