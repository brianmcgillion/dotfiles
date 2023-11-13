_: {
  programs = {
    fzf = {
      enable = true;
      defaultCommand = "git ls-files --cached --others --exclude-standard | fd --type f --type l --hidden --follow --exclude .git";
      defaultOptions = [
        "--reverse"
        "--multi --inline-info --preview='[[ \\$(file --mine {}) =~ binary ]] && echo {} is a binary file || (bat --style=numbers --color=always {} || cat {}) 2>/dev/null | head -300' --preview-window='right:hidden:wrap' --bind='f3:execute(bat --style=numbers {} || less -f {}),f2:toggle-preview,ctrl-d:half-page-down,ctrl-u:half-page-up,ctrl-a:select-all+accept,ctrl-y:execute-silent(echo {+} | pbcopy)'"
      ];
      changeDirWidgetCommand = "fd --type d --hidden --follow --exclude .git"; # ALT_C command
      fileWidgetCommand = "fd --hidden --follow --exclude .git"; # CTRL_T command
    };
  };
}
