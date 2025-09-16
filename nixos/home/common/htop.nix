{
  programs.htop = {
    enable = true;
    settings = {
      color_scheme = 6;
      fields = [
        "PID"
        "USER"
        "STATE"
        "PERCENT_CPU"
        "PERCENT_MEM"
        "TIME"
        "COMM"
      ];
      highlight_base_name = 1;
    };
  };
}
