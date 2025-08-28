{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.services.vibe-trading-ai;
  vibe-trading-ai = pkgs.callPackage ./package.nix { };
in
{
  options = {
    services.vibe-trading-ai = {
      enable = lib.mkEnableOption "Enable the nextjs app";

      hostname = lib.mkOption {
        type = lib.types.str;
        default = "0.0.0.0";
        example = "127.0.0.1";
        description = ''
          The hostname under which the app should be accessible.
        '';
      };

      port = lib.mkOption {
        type = lib.types.port;
        default = 3000;
        example = 3000;
        description = ''
          The port under which the app should be accessible.
        '';
      };

      openFirewall = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = ''
          Whether to open ports in the firewall for this application.
        '';
      };
    };
  };

  config =
    let
      model = builtins.readFile ./../ollama-model.txt;
    in
    lib.mkIf cfg.enable {
      users.groups.vibe-trading-ai = { };
      users.users.vibe-trading-ai = {
        isSystemUser = true;
        group = "vibe-trading-ai";
      };

      systemd.services.vibe-trading-ai = {
        wantedBy = [ "multi-user.target" ];
        description = "Nextjs App.";
        after = [ "network.target" ];
        environment = {
          HOSTNAME = cfg.hostname;
          PORT = toString cfg.port;
          MODEL = model;
          DATABASE_URL = "postgres://vibe-trading-ai?host=/run/postgresql";
          BASE_RPC_URL = "https://mainnet.base.org";
          CHAINLINK_BASE_ETH_USD = "0x71041dddad3595F9CEd3DcCFBe3D1F4b0a16Bb70";
          NEXT_PUBLIC_BASE_URL = "http://localhost:3000";
        };
        serviceConfig = {
          ExecStart = "${lib.getExe vibe-trading-ai}";
          User = "vibe-trading-ai";
          Group = "vibe-trading-ai";
          CacheDirectory = "nextjs-app";
        };
      };

      systemd.services.vibe-trading-ai-database = {
        wantedBy = [ "multi-user.target" ];
        description = "Init Database.";
        after = [ "postgresql.target" ];
        environment = config.systemd.services.vibe-trading-ai.environment;
        serviceConfig = {
          User = "vibe-trading-ai";
          Group = "vibe-trading-ai";
          CacheDirectory = "nextjs-app";
        };
        script = ''
          cd ${vibe-trading-ai}/share/homepage
          ${lib.getExe pkgs.nodejs} ./scripts/init-db.js
        '';
      };

      networking.firewall = lib.mkIf cfg.openFirewall {
        allowedTCPPorts = [ cfg.port ];
      };

      # Enable ollama with requested model loaded. Accessible in your app on http://localhost:11434 (but not exposed to outside environment).
      nixpkgs.config.allowUnfree = true;

      systemd.services.ollama.serviceConfig.DynamicUser = lib.mkForce false;
      systemd.services.ollama.serviceConfig.ProtectHome = lib.mkForce false;
      systemd.services.ollama.serviceConfig.StateDirectory = [ "ollama/models" ];
      services.ollama = {
        enable = true;
        user = "ollama";
        loadModels = [ model ];
      };
      systemd.services.ollama-model-loader.serviceConfig.User = "ollama";
      systemd.services.ollama-model-loader.serviceConfig.Group = "ollama";
      systemd.services.ollama-model-loader.serviceConfig.DynamicUser = lib.mkForce false;

      services.postgresql = {
        enable = true;
        ensureDatabases = [ "vibe-trading-ai" ];
        ensureUsers = [
          {
            name = "vibe-trading-ai";
            ensureDBOwnership = true;
          }
        ];
        authentication = pkgs.lib.mkOverride 10 ''
          #type database  DBuser  auth-method
          local sameuser  all     peer
        '';
      };
    };
}
