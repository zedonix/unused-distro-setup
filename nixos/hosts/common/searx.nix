{
  lib,
  ...
}:
{
  networking.firewall.allowedTCPPorts = [ 883 ];
  services.searx = {
    enable = true;
    redisCreateLocally = true;
    runInUwsgi = true;

    uwsgiConfig = {
      socket = "/run/searx/searx.sock";
      http = ":8888";
      chmod-socket = "660";
      disable-logging = true;
    };

    settings = {
      general = {
        debug = false;
        instance_name = "SearXNG";
      };

      ui = {
        static_use_hash = true;
        theme_args.simple_style = "dark";
        query_in_title = true;
        center_alignment = true;
        results_on_new_tab = false;
      };

      search = {
        safe_search = 2;
      };

      server = {
        port = 8888;
        bind_address = "0.0.0.0";
        secret_key = "36309a66fded36db141d2c66690cdda18e6d7c141ccd3b6b21cc79b44aea92f9";
        image_proxy = true;
        method = "GET";
        default_locale = "en";
        base_url = "http://localhost:8888";
        public_instance = true;
      };

      engines = lib.mapAttrsToList (name: value: { inherit name; } // value) {
        # "duckduckgo".disabled = true;
        "qwant".disabled = true;
      };

      outgoing = {
        request_timeout = 5.0;
        max_request_timeout = 10.0;
        pool_connections = 100;
        pool_maxsize = 15;
        enable_http2 = true;
      };
    };

    limiterSettings = {
      real_ip.x_for = 1;
      ipv4_prefix = 32;
      ipv6_prefix = 56;
      botdetection.ip_limit.filter_link_local = true;
    };
  };
}
