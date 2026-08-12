#!/bin/bash
# Publica el sitio de Súper Liga en GitHub + GitHub Pages.
# Uso: descomprime el zip, entra a la carpeta y corre:  bash publicar.sh
set -e

REPO="superliga-dt"

echo "→ Revisando GitHub CLI…"
if ! command -v gh >/dev/null 2>&1; then
  echo "Falta la herramienta gh. Instálala con:  brew install gh"
  exit 1
fi

if ! gh auth status >/dev/null 2>&1; then
  echo "→ Iniciando sesión en GitHub (se abre el navegador)…"
  gh auth login -h github.com -p https -w
fi

USER=$(gh api user --jq .login)
echo "→ Cuenta: $USER"

if [ ! -d .git ]; then
  git init -q
  git branch -M main
fi
git add -A
git -c user.name="$USER" commit -q -m "Sitio de Súper Liga: reglamento completo y venta oficial" || true

if gh repo view "$USER/$REPO" >/dev/null 2>&1; then
  echo "→ El repo ya existe, empujando cambios…"
  git remote remove origin 2>/dev/null || true
  git remote add origin "https://github.com/$USER/$REPO.git"
  git push -u origin main --force
else
  echo "→ Creando el repositorio…"
  gh repo create "$REPO" --public --source=. --remote=origin \
    --description "Súper Liga — Donde tú eres el DT. Juego de mesa de fútbol chileno: sitio, reglamento y venta oficial." \
    --push
fi

echo "→ Activando GitHub Pages…"
gh api -X POST "repos/$USER/$REPO/pages" \
  -f "source[branch]=main" -f "source[path]=/" >/dev/null 2>&1 \
  || gh api -X PUT "repos/$USER/$REPO/pages" \
     -f "source[branch]=main" -f "source[path]=/" >/dev/null 2>&1 || true

gh api -X PATCH "repos/$USER/$REPO" -f homepage="https://$USER.github.io/$REPO/" >/dev/null 2>&1 || true

echo ""
echo "✔ Listo."
echo "  Repo:  https://github.com/$USER/$REPO"
echo "  Sitio: https://$USER.github.io/$REPO/"
echo "  (Pages tarda 1 o 2 minutos en levantar la primera vez.)"
