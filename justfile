
secret-edit:
  git secret reveal
  ${EDITOR:-${VISUAL:-vi}} .env
  git secret hide
  git add .env.secret
  git add .gitsecret
