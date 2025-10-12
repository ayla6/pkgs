{
  nix-update-script,

  fetchurl,
  lib,
  makeWrapper,
  patchelf,
  stdenvNoCC,
  bintools,
  makeDesktopItem,
  copyDesktopItems,
  # Linked dynamic libraries.
  alsa-lib,
  at-spi2-atk,
  at-spi2-core,
  atk,
  cairo,
  cups,
  dbus,
  expat,
  fontconfig,
  freetype,
  gcc-unwrapped,
  gdk-pixbuf,
  glib,
  gtk3,
  gtk4,
  libdrm,
  libglvnd,
  libkrb5,
  libX11,
  libxcb,
  libXcomposite,
  libXcursor,
  libXdamage,
  libXext,
  libXfixes,
  libXi,
  libxkbcommon,
  libXrandr,
  libXrender,
  libXScrnSaver,
  libxshmfence,
  libXtst,
  libgbm,
  nspr,
  nss,
  pango,
  pipewire,
  vulkan-loader,
  wayland, # ozone/wayland
  # Command line programs
  coreutils,
  # command line arguments which are always set e.g "--disable-gpu"
  commandLineArgs ? "",
  # Will crash without.
  systemd,
  # Loaded at runtime.
  libexif,
  pciutils,
  # Additional dependencies according to other distros.
  ## Ubuntu
  curl,
  liberation_ttf,
  util-linux,
  wget,
  xdg-utils,
  ## Arch Linux.
  flac,
  harfbuzz,
  icu,
  libopus,
  libpng,
  snappy,
  speechd-minimal,
  ## Gentoo
  bzip2,
  libcap,
  # Necessary for USB audio devices.
  libpulseaudio,
  pulseSupport ? true,
  adwaita-icon-theme,
  gsettings-desktop-schemas,
  # For video acceleration via VA-API (--enable-features=VaapiVideoDecoder)
  libva,
  libvaSupport ? true,
  # For Vulkan support (--enable-features=Vulkan)
  addDriverRunpath,
  # For QT support
  qt6,
}: let
  pname = "helium";

  opusWithCustomModes = libopus.override {withCustomModes = true;};

  deps =
    [
      alsa-lib
      at-spi2-atk
      at-spi2-core
      atk
      bzip2
      cairo
      coreutils
      cups
      curl
      dbus
      expat
      flac
      fontconfig
      freetype
      gcc-unwrapped.lib
      gdk-pixbuf
      glib
      harfbuzz
      icu
      libcap
      libdrm
      liberation_ttf
      libexif
      libglvnd
      libkrb5
      libpng
      libX11
      libxcb
      libXcomposite
      libXcursor
      libXdamage
      libXext
      libXfixes
      libXi
      libxkbcommon
      libXrandr
      libXrender
      libXScrnSaver
      libxshmfence
      libXtst
      libgbm
      nspr
      nss
      opusWithCustomModes
      pango
      pciutils
      pipewire
      snappy
      speechd-minimal
      systemd
      util-linux
      vulkan-loader
      wayland
      wget
    ]
    ++ lib.optional pulseSupport libpulseaudio
    ++ lib.optional libvaSupport libva
    ++ [
      gtk3
      gtk4
      qt6.qtbase
      qt6.qtwayland
    ];

  linux = stdenvNoCC.mkDerivation (finalAttrs: {
    inherit pname meta passthru;
    version = "0.5.5.2";

    src = fetchurl {
      url = "https://github.com/imputnet/helium-linux/releases/download/${finalAttrs.version}/helium-${finalAttrs.version}-x86_64_linux.tar.xz";
      hash = "sha256-EPW7DicU580o3YC+Tffq8AWEpiuydP0HKsUOfh60u1Q=";
    };

    strictDeps = false;

    desktopItems = [
      (makeDesktopItem {
        name = "helium";
        desktopName = "Helium";
        comment = "bullshit-free web browser, wip";
        exec = "helium %U";
        icon = "helium";
        type = "Application";
        categories = ["Network" "WebBrowser"];
        mimeTypes = [
          "text/html"
          "text/xml"
          "application/xhtml+xml"
          "application/xml"
          "application/vnd.mozilla.xul+xml"
          "application/rss+xml"
          "application/rdf+xml"
          "image/gif"
          "image/jpeg"
          "image/png"
          "x-scheme-handler/http"
          "x-scheme-handler/https"
          "x-scheme-handler/chrome"
          "video/webm"
          "application/x-xpinstall"
        ];
        startupNotify = true;
        terminal = false;

        actions = {
          new-window = {
            name = "New Window";
            exec = "helium";
          };
          new-private-window = {
            name = "New Incognito Window";
            exec = "helium --incognito";
          };
        };
      })
    ];

    nativeBuildInputs = [
      makeWrapper
      patchelf
      copyDesktopItems
    ];

    buildInputs = [
      # needed for XDG_ICON_DIRS
      adwaita-icon-theme
      glib
      gtk3
      gtk4
      # needed for GSETTINGS_SCHEMAS_PATH
      gsettings-desktop-schemas
    ];

    unpackPhase = ''
      runHook preUnpack
      tar xf $src --strip-components=1
      runHook postUnpack
    '';

    rpath = lib.makeLibraryPath deps + ":" + lib.makeSearchPathOutput "lib" "lib64" deps;
    binpath = lib.makeBinPath deps;

    installPhase = ''
      runHook preInstall

      exe=$out/bin/helium

      mkdir -p $out/bin $out/share/helium $out/share/icons/hicolor/256x256/apps

      # Copy all helium files to $out/share/helium
      cp -v -a * $out/share/helium/

      # replace bundled vulkan-loader
      rm -v $out/share/helium/libvulkan.so.1
      ln -v -s -t "$out/share/helium" "${lib.getLib vulkan-loader}/lib/libvulkan.so.1"

      # Install icon
      cp -v $out/share/helium/product_logo_256.png $out/share/icons/hicolor/256x256/apps/helium.png

      makeWrapper "$out/share/helium/chrome" "$exe" \
        --prefix QT_PLUGIN_PATH  : "${qt6.qtbase}/lib/qt-6/plugins" \
        --prefix QT_PLUGIN_PATH  : "${qt6.qtwayland}/lib/qt-6/plugins" \
        --prefix NIXPKGS_QT6_QML_IMPORT_PATH : "${qt6.qtwayland}/lib/qt-6/qml" \
        --prefix LD_LIBRARY_PATH : "$rpath" \
        --prefix PATH            : "$binpath" \
        --suffix PATH            : "${lib.makeBinPath [xdg-utils]}" \
        --prefix XDG_DATA_DIRS   : "$XDG_ICON_DIRS:$GSETTINGS_SCHEMAS_PATH:${addDriverRunpath.driverLink}/share" \
        --add-flags "\''${NIXOS_OZONE_WL:+\''${WAYLAND_DISPLAY:+--ozone-platform-hint=auto --enable-features=WaylandWindowDecorations --enable-wayland-ime=true}}" \
        --add-flags ${lib.escapeShellArg commandLineArgs}

      # Make sure that libGL and libvulkan are found by ANGLE libGLESv2.so
      patchelf --set-rpath $rpath $out/share/helium/lib*GL*

      for elf in $out/share/helium/{chrome,chrome_crashpad_handler}; do
        patchelf --set-rpath $rpath $elf
        patchelf --set-interpreter ${bintools.dynamicLinker} $elf
      done

      runHook postInstall
    '';
  });

  passthru.updateScript = nix-update-script { };

  meta = {
    description = "bullshit-free web browser, wip";
    homepage = "https://github.com/imputnet/helium-chromium";
    license = lib.licenses.gpl3;
    platforms = ["x86_64-linux"];
    sourceProvenance = with lib.sourceTypes; [binaryNativeCode];
    mainProgram = "helium";
  };
in
  if stdenvNoCC.hostPlatform.isLinux
  then linux
  else throw "Unsupported platform ${stdenvNoCC.hostPlatform.system}"
