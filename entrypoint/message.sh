#!/env/bin/zsh
# ------------------------------ message.sh -----------------------------------------

message() {
  local text="$1"
  local color="$2"

  case "$color" in
    red)    color_code="\033[0;31m" ;;
    green)  color_code="\033[0;32m" ;;
    yellow) color_code="\033[1;33m" ;;
    cyan)   color_code="\033[0;36m" ;;
    blue)   color_code="\033[0;34m" ;;
    magenta) color_code="\033[0;35m" ;;
    *)      color_code="\033[0m" ;;  # Default (no color)
  esac

  echo -e "${color_code}${text}\033[0m"
}