hist_delete_fzf() {
  local +h HISTORY_IGNORE=
  local -a ignore
  fc -pa "$HISTFILE"
  if type bat >/dev/null 2>&1; then
  selection=$(fc -rt '%Y-%m-%d %H:%M' -l 1  |
      awk '{ cmd=$0; if (!seen[cmd]++) print $0}' |
      bat --color=always --plain --language sh |
      fzf --bind 'enter:become:echo {+f1}' --header='Press enter to remove; escape to exit' --height=100% --preview-window 'hidden:down:border-top:wrap:<70(hidden)' --prompt='Global History > ' --with-nth=2.. --ansi --preview 'bat --color=always --plain --language sh <<< {2..}' )
  else
  selection=$(fc -rt '%Y-%m-%d %H:%M' -l 1  |
      awk '{ cmd=$0; if (!seen[cmd]++) print $0}' |
      fzf --bind 'enter:become:echo {+f1}' --header='Press enter to remove; escape to exit' --height=100% --preview-window 'hidden:down:border-top:wrap:<70(hidden)' --prompt='Global History > ' --with-nth=2.. )
  fi

  if [ -n "$selection" ]; then
    while IFS= read -r line; do ignore+=("${(b)history[$line]}"); done < "$selection"
    HISTORY_IGNORE="(${(j:|:)ignore})"
    # Write history excluding lines that match `$HISTORY_IGNORE` and read new history.
    fc -W && fc -p "$HISTFILE"
  fi
}

autoload hist_delete_fzf
zle -N hist_delete_fzf
bindkey ${FZF_HIST_DELETE_BINDKEY:-'^H'} hist_delete_fzf


# Common FZF options with a placeholder for bat_cmd
common_opts="$(
  cat <<'FZF_COMMON'
--bind "ctrl-d:execute-silent(zsh -ic '
  fc -pa $HISTFILE;
  for i in {+1}; do ignore+=( \"${(b)history[$i]}\" ); done;
  HISTORY_IGNORE=\"(${(j:|:)ignore})\";
  fc -W')+reload:fc -pa $HISTFILE;
  fc -rt '%Y-%m-%d %H:%M' -l 1 |
  awk '{if (!seen[$0]++) print $0}' |
  awk '{print $1\"  \"$2, substr($0, index($0,$3))}' |
  $bat_cmd"
--bind "start:reload:fc -pa $HISTFILE;
  fc -rt '%Y-%m-%d %H:%M' -l 1 |
  awk '{if (!seen[$0]++) print $0}' |
  awk '{print $1\"  \"$2, substr($0, index($0,$3))}' |
  $bat_cmd"
--header 'Press enter to select; ^d to remove'
--height 100%
--preview-window 'hidden:down:border-top:wrap:<70(hidden)'
--prompt ' Global History > '
--with-nth 1..
FZF_COMMON
)"

# Check if bat command is available
if type bat >/dev/null 2>&1; then
  bat_cmd="bat --color=always --plain --language sh"
  FZF_CTRL_R_OPTS="$common_opts
--ansi
--preview '$bat_cmd <<<{2..}'"
else
  bat_cmd="sponge"
  FZF_CTRL_R_OPTS="$common_opts"
fi

# Replace the placeholders with the actual commands
FZF_CTRL_R_OPTS="${FZF_CTRL_R_OPTS//\$bat_cmd/$bat_cmd}"

# Export the final FZF_CTRL_R_OPTS
export FZF_CTRL_R_OPTS


#CAUTION
#ALWAYS BACK UP YOUR HISTORY FILE
#Assigning values to the FZF_CTRL_R_OPTS environment variable can solve the deletion part, but not
#always the correct selection. This is because the retrieved number for a selection can diverge, leading to
#the incorrect history entry being returned. The optimal solution is to create a dedicated widget for
#deletion (refer to cenk1cenk2's widget above) using marlonrichert's zsh-hist plugin, or mimic
#the deletion process with a function based on the plugin from marlonrichert. Meanwhile,
#the current fzf-history-widget should remain unchanged.

# The awk command removes duplicates, and aligns numbers from left to right.
# This alignment is necessary for the 'bat' function to colorize the output correctly while
# maintaining proper field index expression.

#Reference https://github.com/junegunn/fzf/issues/3522
#BW
# export FZF_CTRL_R_OPTS="$(
# 	cat <<'FZF_FTW'
# --bind "ctrl-d:execute-silent(zsh -ic 'fc -pa $HISTFILE; for i in {+1}; do ignore+=( \"${(b)history[$i]}\" );done;HISTORY_IGNORE=\"(${(j:|:)ignore})\";fc -W')+reload:fc -pa $HISTFILE; fc -rl 1 |
# 	awk '{ cmd=$0; sub(/^[ \t]*[0-9]+\**[ \t]+/, \"\", cmd); if (!seen[cmd]++) print $0 }'"
# --bind "start:reload:fc -pa $HISTFILE; fc -rl 1 |
# 	awk '{ cmd=$0; sub(/^[ \t]*[0-9]+\**[ \t]+/, \"\", cmd); if (!seen[cmd]++) print $0 }'"
# --header 'enter select · ^d remove'
# --height 70%
# --preview-window 'hidden:down:border-top:wrap:<70(hidden)'
# --prompt ' Global History > '
# --with-nth 2..
# FZF_FTW
# )"

#Color
# export FZF_CTRL_R_OPTS="$(
# 	cat <<'FZF_FTW'
# 	--ansi
# --bind "ctrl-d:execute-silent(zsh -ic 'fc -pa $HISTFILE; for i in {+1}; do ignore+=( \"${(b)history[$i]}\" );done;
# 	HISTORY_IGNORE=\"(${(j:|:)ignore})\";fc -W')+reload:fc -pa $HISTFILE; fc -rl 1 |
# 	awk '{ cmd=$0; sub(/^[ \t]*[0-9]+\**[ \t]+/, \"\", cmd); if (!seen[cmd]++) {printf \"%-10s\", $1; $1=\"\"; print $0} }' |
# 	bat --color=always --plain --language sh"
# --bind "start:reload:fc -pa $HISTFILE; fc -rl 1 |
# 	awk '{ cmd=$0; sub(/^[ \t]*[0-9]+\**[ \t]+/, \"\", cmd); if (!seen[cmd]++) {printf \"%-10s\", $1; $1=\"\"; print $0} }' |
# 	bat --color=always --plain --language sh"
# --header 'enter select · ^d remove'
# --height 70%
# --preview-window 'hidden:down:border-top:wrap:<70(hidden)'
# --preview 'bat --color=always --plain --language sh <<<{2..}'
# --prompt ' Global History > '
# --with-nth 2..
# FZF_FTW
# )"


# fzf-delete-history-widget() {
#     local selected num
#     setopt localoptions noglobsubst noposixbuiltins pipefail no_aliases 2> /dev/null
#     local selected=( $(fc -rl 1 | awk '{ cmd=$0; sub(/^[ \t]*[0-9]+\**[ \t]+/, "", cmd); if (!seen[cmd]++) print $0 }' |
# FZF_DEFAULT_OPTS="--height ${FZF_TMUX_HEIGHT:-40%} ${FZF_DEFAULT_OPTS-} -n2..,.. --bind=ctrl-r:toggle-sort,ctrl-z:ignore ${FZF_CTRL_R_OPTS-} --query=${(qqq)LBUFFER} +m --multi --bind 'enter:become(echo {+1})'" $(__fzfcmd)) )
#     local ret=$?
#     if [ -n "$selected[*]" ]; then
#       hist delete $selected[*]
#     fi
#     zle reset-prompt
#     return $ret
# }