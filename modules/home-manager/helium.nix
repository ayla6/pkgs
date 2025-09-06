{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) literalExpression mkOption types;

  heliumOptions = {
    enable = mkOption {
      type = types.bool;
      default = false;
      example = true;
      description = "Whether to enable Helium browser.";
    };

    package = mkOption {
      type = types.nullOr types.package;
      default = pkgs.helium;
      defaultText = literalExpression "pkgs.helium";
      description = "The Helium package to use.";
    };

    commandLineArgs = mkOption {
      type = types.listOf types.str;
      default = [];
      example = [
        "--enable-logging=stderr"
        "--ignore-gpu-blocklist"
      ];
      description = ''
        List of command-line arguments to be passed to Helium.

        For a list of common switches, see
        [Chrome switches](https://chromium.googlesource.com/chromium/src/+/refs/heads/main/chrome/common/chrome_switches.cc).

        To search switches for other components, see
        [Chromium codesearch](https://source.chromium.org/search?q=file:switches.cc&ss=chromium%2Fchromium%2Fsrc).
      '';
    };

    extensions = mkOption {
      type = with types; let
        extensionType = submodule {
          options = {
            id = mkOption {
              type = strMatching "[a-zA-Z]{32}";
              description = ''
                The extension's ID from the Chrome Web Store url or the unpacked crx.
              '';
              default = "";
            };

            updateUrl = mkOption {
              type = str;
              default = "https://clients2.google.com/service/update2/crx";
              description = ''
                URL of the extension's update manifest XML file.
              '';
            };

            crxPath = mkOption {
              type = nullOr path;
              default = null;
              description = ''
                Path to the extension's crx file.
              '';
            };

            version = mkOption {
              type = nullOr str;
              default = null;
              description = ''
                The extension's version, required for local installation.
              '';
            };
          };
        };
      in
        listOf (coercedTo str (v: {id = v;}) extensionType);
      default = [];
      example = literalExpression ''
        [
          { id = "cjpalhdlnbpafiamejdnhcphjbkeiagm"; } # ublock origin
          {
            id = "dcpihecpambacapedldabdbpakmachpb";
            updateUrl = "https://raw.githubusercontent.com/iamadamdev/bypass-paywalls-chrome/master/updates.xml";
          }
          {
            id = "aaaaaaaaaabbbbbbbbbbcccccccccc";
            crxPath = "/home/share/extension.crx";
            version = "1.0";
          }
        ]
      '';
      description = ''
        List of Helium extensions to install.
        To find the extension ID, check its URL on the
        [Chrome Web Store](https://chrome.google.com/webstore/category/extensions).

        To install extensions outside of the Chrome Web Store set
        `updateUrl` or `crxPath` and
        `version` as explained in the
        [Chrome
        documentation](https://developer.chrome.com/docs/extensions/mv2/external_extensions).
      '';
    };

    dictionaries = mkOption {
      type = types.listOf types.package;
      default = [];
      example = literalExpression ''
        [
          pkgs.hunspellDictsChromium.en_US
        ]
      '';
      description = ''
        List of Helium dictionaries to install.
      '';
    };
    nativeMessagingHosts = mkOption {
      type = types.listOf types.package;
      default = [];
      example = literalExpression ''
        [
          pkgs.kdePackages.plasma-browser-integration
        ]
      '';
      description = ''
        List of Helium native messaging hosts to install.
      '';
    };
  };

  heliumConfig = cfg: let
    configDir = "${config.xdg.configHome}/net.imput.helium";

    extensionJson = ext:
      assert ext.crxPath != null -> ext.version != null;
      with builtins; {
        name = "${configDir}/External Extensions/${ext.id}.json";
        value.text = toJSON (
          if ext.crxPath != null
          then {
            external_crx = ext.crxPath;
            external_version = ext.version;
          }
          else {
            external_update_url = ext.updateUrl;
          }
        );
      };

    dictionary = pkg: {
      name = "${configDir}/Dictionaries/${pkg.passthru.dictFileName}";
      value.source = pkg;
    };

    nativeMessagingHostsJoined = pkgs.symlinkJoin {
      name = "helium-native-messaging-hosts";
      paths = cfg.nativeMessagingHosts;
    };
  in
    lib.mkIf cfg.enable {
      home.packages = lib.mkIf (cfg.package != null) [
        (
          if cfg.commandLineArgs != []
          then
            cfg.package.override {
              commandLineArgs = lib.concatStringsSep " " cfg.commandLineArgs;
            }
          else cfg.package
        )
      ];
      home.file =
        lib.listToAttrs ((map extensionJson cfg.extensions) ++ (map dictionary cfg.dictionaries))
        // {
          "${configDir}/NativeMessagingHosts" = lib.mkIf (cfg.nativeMessagingHosts != []) {
            source = "${nativeMessagingHostsJoined}/etc/chromium/native-messaging-hosts"; # Standard path for Chromium-based browsers
            recursive = true;
          };
        };
    };
in {
  options.programs = {
    helium = heliumOptions;
  };

  config = heliumConfig config.programs.helium;
}
