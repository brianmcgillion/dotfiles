{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    imagemagick # for image-dired

    # :lang latex & :lang org (latex previews)
    texlive.combined.scheme-full

    # TODO Use some secrets managment tool to lock sensitive conf files.
    gnutls # for TLS connectivity

    # :lang org & :org-roam2
    graphviz
    gnuplot
    # :lang org +dragndrop
    wl-clipboard
    maim
  ];
}
