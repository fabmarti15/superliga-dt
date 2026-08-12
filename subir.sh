#!/bin/bash
# Sube el sitio al repo superliga-dt con git puro. No necesita gh ni brew.
# Requisito: el repo https://github.com/fabmarti15/superliga-dt ya debe existir y estar vacío.
set -e
cd "$(dirname "$0")"
REMOTE="https://github.com/fabmarti15/superliga-dt.git"

[ -d .git ] || { git init -q; git branch -M main; }
git add -A
git commit -q -m "Sitio de Súper Liga: reglamento completo y venta oficial" || echo "(sin cambios que commitear)"
git remote remove origin 2>/dev/null || true
git remote add origin "$REMOTE"
git push -u origin main

echo ""
echo "✔ Subido. Verifica que CONTEXTO.md NO esté en el repo:"
git ls-files | grep -q '^CONTEXTO.md$' && echo "  ⚠️  ERROR: CONTEXTO.md quedó incluido" || echo "  ✅ CONTEXTO.md excluido, bien"
echo ""
echo "  Repo:  https://github.com/fabmarti15/superliga-dt"
echo "  Sitio: https://fabmarti15.github.io/superliga-dt/"
