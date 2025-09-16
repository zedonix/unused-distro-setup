{
  programs.zathura = {
    enable = true;
    mappings = {
      "u" = "scroll half-up";
      "d" = "scroll half-down";
      "r" = "reload";
      "D" = "toggle_page_mode";
      "R" = "rotate";
      "i" = "recolor";
      "p" = "print";
    };
    options = {
      selection-clipboard = "clipboard";
      database = "sqlite";
      synctex = "true";
    };
  };
}
