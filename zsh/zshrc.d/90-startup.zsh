# Optional noisy startup — OFF by default (set flags in ~/.zshrc.local)

if [[ "${DOTFILES_TUNE_INOTIFY:-0}" == "1" ]]; then
  # WSL / laptop: do this once via sysctl.d, not every shell. Opt-in only.
  sudo sysctl fs.inotify.max_user_instances=65534 >/dev/null 2>&1 || true
  sudo sysctl fs.inotify.max_user_watches=524288 >/dev/null 2>&1 || true
fi

if [[ "${DOTFILES_START_MYSQL:-0}" == "1" ]] && command -v docker >/dev/null 2>&1; then
  dotfiles_log "${BIBlue}> Starting local MYSQL (MAY FAIL IF ALREADY RUNNING, SO CHILL BRUH)"
  docker start mysql 2>/dev/null || \
    docker run -d -p 3306:3306 -e MYSQL_ROOT_PASSWORD=password --name mysql mysql:8
fi

if [[ "${DOTFILES_SHOW_CLUSTER_STATUS:-0}" == "1" ]]; then
  echo -e "${Color_Off} All Done. cleaning up."
  clear
  echo -e "${BICyan}"
  if command -v kubectl >/dev/null 2>&1; then
    echo ">--------------------<  K8s >--------------------<"
    kubectl cluster-info 2>/dev/null || echo "(no cluster)"
  fi
  if command -v docker >/dev/null 2>&1; then
    echo ">--------------------<DOCKER>--------------------<"
    docker ps -a 2>/dev/null || true
  fi
fi

# Reset colours so the prompt isn't cursed
echo -ne "${Color_Off}"
