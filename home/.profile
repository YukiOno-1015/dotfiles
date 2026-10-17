# The following lines were added by Docker Desktop to add commands to your PATH.
export PATH="$PATH:/Users/yukiono/.docker/bin"
# End of Docker Desktop section.

if [[ -f "$HOME/.zprofile" ]]; then
  source "$HOME/.zprofile"
fi

if [[ -f "$HOME/.local/bin/env" ]]; then
  source "$HOME/.local/bin/env"
fi
