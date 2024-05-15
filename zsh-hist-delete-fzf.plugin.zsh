hist_delete_fzf() {
  local +h HISTORY_IGNORE=
  local -a ignore
  fc -pa "$HISTFILE"
  selection=$(fc -rl 1 |
  		awk '{ cmd=$0; sub(/^[ \t]*[0-9]+\**[ \t]+/, "", cmd); if (!seen[cmd]++)  print $0}' |
  		fzf --bind 'enter:become:echo {+f1}')
  if [ -n "$selection" ]; then
  	while IFS= read -r line; do ignore+=("${(b)history[$line]}"); done < "$selection"
  	HISTORY_IGNORE="(${(j:|:)ignore})"
  	# Write history excluding lines that match `$HISTORY_IGNORE` and read new history.
  	fc -W && fc -p "$HISTFILE"
  else
  	echo "nothing deleted from history"
  fi
}

if ! type bat >/dev/null 2>&1; then
    # The awk command removes duplicates, and aligns numbers from left to right.
	# This alignment is necessary for the 'bat' function to colorize the output correctly while
	# maintaining proper field index expression.
	export FZF_CTRL_R_OPTS="$(
		cat <<'FZF_FTW'
		--ansi
		--bind "ctrl-d:execute-silent(zsh -ic 'fc -pa $HISTFILE; for i in {+1}; do ignore+=( \"${(b)history[$i]}\" );done;
			HISTORY_IGNORE=\"(${(j:|:)ignore})\";fc -W')+reload:fc -pa $HISTFILE; fc -rl 1 |
			awk '{ cmd=$0; sub(/^[ \t]*[0-9]+\**[ \t]+/, \"\", cmd); if (!seen[cmd]++) {printf \"%-10s\", $1; $1=\"\"; print $0} }' |
			bat --color=always --plain --language sh"
		--bind "start:reload:fc -pa $HISTFILE; fc -rl 1 |
			awk '{ cmd=$0; sub(/^[ \t]*[0-9]+\**[ \t]+/, \"\", cmd); if (!seen[cmd]++) {printf \"%-10s\", $1; $1=\"\"; print $0} }' |
			bat --color=always --plain --language sh"
		--header 'enter select · ^d remove'
		--height 70%
		--preview-window 'hidden:down:border-top:wrap:<70(hidden)'
		--preview 'bat --color=always --plain --language sh <<<{2..}'
		--prompt ' Global History > '
		--with-nth 2..
		FZF_FTW
	)"

else
	export FZF_CTRL_R_OPTS="$(
		cat <<'FZF_FTW'
		--bind "ctrl-d:execute-silent(zsh -ic 'fc -pa $HISTFILE; for i in {+1}; do ignore+=( \"${(b)history[$i]}\" );done;HISTORY_IGNORE=\"(${(j:|:)ignore})\";fc -W')+reload:fc -pa $HISTFILE; fc -rl 1 |
			awk '{ cmd=$0; sub(/^[ \t]*[0-9]+\**[ \t]+/, \"\", cmd); if (!seen[cmd]++) print $0 }'"
		--bind "start:reload:fc -pa $HISTFILE; fc -rl 1 |
			awk '{ cmd=$0; sub(/^[ \t]*[0-9]+\**[ \t]+/, \"\", cmd); if (!seen[cmd]++) print $0 }'"
		--header 'enter select · ^d remove'
		--height 70%
		--preview-window 'hidden:down:border-top:wrap:<70(hidden)'
		--prompt ' Global History > '
		--with-nth 2..
		FZF_FTW
		)"
fi

