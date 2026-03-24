_require_gh() {
  if ! command -v gh >/dev/null 2>&1; then
    echo "GitHub CLI fehlt: brew install gh"
    return 1
  fi
}

prmain() {
  _require_gh || return 1
  local current
  current="$(git branch --show-current)"
  if [ "$current" = "main" ]; then
    echo "Du bist bereits auf main — kein PR noetig."
    return 1
  fi
  git push -u origin "$current" 2>/dev/null
  gh pr create --base main --head "$current" --fill
}

prstaging() {
  _require_gh || return 1
  gh pr create --base staging --head main --fill
}

prprod() {
  _require_gh || return 1
  gh pr create --base prod --head staging --fill
}

prall() {
  local current
  current="$(git branch --show-current)"

  if [ "$current" = "main" ]; then
    echo "Auf main: PR main -> staging, dann staging -> prod"
    prstaging && prprod
    return $?
  fi

  if [ "$current" = "staging" ]; then
    echo "Auf staging: PR staging -> prod"
    prprod
    return $?
  fi

  echo "Auf $current: PR $current -> main"
  prmain
}
