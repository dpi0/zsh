copydir(){
	print -n $PWD | wl-copy
}

copylastcommand(){
	fc -ln -1 | tr -d '\n' | wl-copy
}

copybuffer() {
	if command -v wl-copy &>/dev/null; then
		echo "$BUFFER" | wl-copy
	else
		echo "Error! Couldn't copy current line. wl-copy not present"
	fi
}

speedtest(){
	curl -s https://raw.githubusercontent.com/sivel/speedtest-cli/master/speedtest.py | python -
}

# launch-waybar(){
#     CONFIG_FILES="$DOTFILES/waybar/config.jsonc $DOTFILES/waybar/style.css "
#     
#     #$DOTFILES/waybar/config2.jsonc
#     
#     trap "killall waybar" EXIT
#     
#     while true; do
#         waybar &
#         inotifywait -e create,modify $CONFIG_FILES
#         killall waybar
#     done
# }
#

f() {
	search_term="$1"

	SELECTED_FILE=$(
	fzf \
		--query="$search_term" \
		--exact \
		--extended \
		--preview="bat --style=numbers --color=always --line-range :500 {}" \
		--preview-window="right:50%" \
		--ansi
	)

	if [ -n "$SELECTED_FILE" ]; then
		file_extension="${SELECTED_FILE##*.}"

		case "$file_extension" in
			"pdf")
				zathura "$SELECTED_FILE"
				;;
			"txt" | "py" | "rs" | "go" | "md")
				nvim "$SELECTED_FILE"
				;;
			*)
				nvim "$SELECTED_FILE"
				;;
		esac

	# Print the selected file value to stdout
	echo "$SELECTED_FILE" | wl-copy
	echo "$SELECTED_FILE"
	fi
}

# cd into dir
ff() {
	local selected_file
	selected_file=$(
	fzf \
		--query="$search_term" \
		--exact \
		--extended \
		--preview="bat --style=numbers --color=always --line-range :500 {}" \
		--preview-window="right:50%" \
		--ansi
	)
	if [[ -n $selected_file ]]; then
		local parent_dir
		parent_dir=$(dirname "$selected_file")
		cd "$parent_dir" || echo "Failed to change directory"
	else
		echo "No file selected"
	fi
}

fh() {
	selected_command=$(history -E 1 | sort -k1,1nr | fzf | awk '{$1=""; $2=""; $3=""; print $0}' | sed 's/^[ \t]*//')
	echo "$selected_command" | wl-copy
}

finh() {
	cat /var/log/pacman.log | grep -E "\[ALPM\] (installed|removed|upgraded|upgraded|downgraded)" | awk '{print $1, $2, $3, $4, $5, $6}' | sort -r | fzf
}

# search all installed packages
fin() {
	pacman -Qq | fzf --preview='pacman -Qi {}'
}

in() {
	paru -Slq | fzf -q "$1" -m --preview 'paru -Si {1}' | xargs -ro paru -S
}


paste() {
  local file="$1"
  local extension="${file##*.}"
  
  # Generate the URL
  local url=$(jq -Rns '{text: inputs}' < "$file" | \
    curl -s -H 'Content-Type: application/json' --data-binary @- https://bin.bloerg.net | \
    jq -r --arg ext "$extension" '. | "https://bin.bloerg.net\(.path).\($ext)"')
  
  # Copy URL to clipboard
  echo "$url" | wl-copy
  
  # Show notification
  dunstify "URL copied to clipboard" "$url"
  
  # Output URL to terminal
  echo "$url"
}

extract() {
  if [ -f "$1" ]; then
    local target_dir="${2:-.}"

    # Create the target directory if it doesn't exist
    if [ ! -d "$target_dir" ]; then
        mkdir -p "$target_dir"
    fi

    case "$1" in
        *.zip) unzip "$1" -d "$target_dir" ;;
        *.tar.gz) tar -xzvf "$1" -C "$target_dir" ;;
        *.tar.xz) tar -xJf "$1" -C "$target_dir" ;;
        *.tar.bz2) tar -xjvf "$1" -C "$target_dir" ;;
        *.tar) tar -xvf "$1" -C "$target_dir" ;;
        *) echo "Unsupported format" ;;
    esac

  else
    echo "'$1' is not a valid file"
  fi
}

compress() {
  if [ "$#" -lt 3 ]; then
    echo "Usage: compress_files <file1> <file2> ... <output-file>"
    echo "   or: compress_files * <output-file>"
    return 1
  fi

  local files=()
  local output_file=""

  # Check if the first argument is an asterisk (*)
  if [ "$1" = "*" ]; then
    files=("${@:2:$#-2}")
  else
    files=("${@:1:$#-1}")
  fi

  output_file="${!#}"

  # Check if 'zip' command is available
  if command -v zip &> /dev/null; then
    local extension=".zip"
    zip -r "$output_file$extension" "${files[@]}"
  else
    local extension=".tar.gz"
    eval "tar -czvf '$output_file$extension' ${files[@]}"
  fi

  echo "Compression operation completed successfully. Output file: $output_file$extension"
}