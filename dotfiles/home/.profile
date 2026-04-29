if [[ -f "$HOME/.zprofile" ]]; then
  source "$HOME/.zprofile"
fi

if [[ -f "$HOME/.local/bin/env" ]]; then
  source "$HOME/.local/bin/env"
fi
