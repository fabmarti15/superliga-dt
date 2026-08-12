#!/bin/bash
# Publica Súper Liga completo: crea el repo, sube, activa Pages y fija el homepage.
# No necesita gh ni brew. Usa la credencial de GitHub que ya tienes guardada en el llavero.
# Uso:  bash publicar-todo.sh

cd "$(dirname "$0")" || exit 1
USER="fabmarti15"
REPO="superliga-dt"
API="https://api.github.com"

# --- Guarda: no correr esto en la carpeta equivocada ---
if [ ! -f index.html ] || [ ! -d img ]; then
  echo "✋ Alto: esta no es la carpeta de Súper Liga (falta index.html o img/)."
  echo "   Estás en: $(pwd)"
  exit 1
fi
echo "→ Carpeta correcta: $(pwd)"

# --- Limpieza de la basura que dejó el puente ---
rm -rf _to_delete
find .git -name "*.lock" -delete 2>/dev/null
find .git/objects -name "tmp_obj_*" -delete 2>/dev/null

# --- Credencial de GitHub desde el llavero (nunca se imprime) ---
TOKEN=$(printf 'protocol=https\nhost=github.com\n\n' | git credential fill 2>/dev/null | sed -n 's/^password=//p')
if [ -z "$TOKEN" ]; then
  echo "✋ No encontré tu credencial de GitHub guardada."
  echo "   Crea el repo a mano en https://github.com/new (nombre: $REPO, Public, sin README)"
  echo "   y después corre:  git push -u origin main"
  exit 1
fi
echo "→ Credencial encontrada."

api() { curl -sS -H "Authorization: Bearer $TOKEN" -H "Accept: application/vnd.github+json" "$@"; }

# --- 1. Crear el repo si no existe ---
CODE=$(api -o /dev/null -w "%{http_code}" "$API/repos/$USER/$REPO")
if [ "$CODE" = "200" ]; then
  echo "→ El repo ya existía."
else
  echo "→ Creando el repo público…"
  RESP=$(api -X POST "$API/user/repos" -d "{\"name\":\"$REPO\",\"description\":\"Súper Liga — Donde tú eres el DT. Juego de mesa de fútbol chileno: sitio, reglamento y venta oficial.\",\"private\":false,\"has_issues\":false,\"has_wiki\":false,\"homepage\":\"https://$USER.github.io/$REPO/\"}")
  echo "$RESP" | grep -q '"full_name"' || { echo "✋ No pude crear el repo. Respuesta:"; echo "$RESP" | head -5; echo "Créalo a mano en https://github.com/new y vuelve a correr esto."; exit 1; }
  echo "   ✔ Creado."
fi

# --- 2. Commit y push ---
git add -A
git commit -q -m "Sitio de Súper Liga: reglamento completo y venta oficial" 2>/dev/null || echo "→ (nada nuevo que commitear)"
git remote remove origin 2>/dev/null
git remote add origin "https://github.com/$USER/$REPO.git"
echo "→ Subiendo…"
git push -u origin main || { echo "✋ Falló el push."; exit 1; }

if git ls-files | grep -q '^CONTEXTO.md$'; then
  echo "   ⚠️  CONTEXTO.md quedó incluido. Avísale a Claude."
else
  echo "   ✔ CONTEXTO.md excluido, como corresponde."
fi

# --- 3. GitHub Pages ---
echo "→ Activando GitHub Pages…"
PC=$(api -o /dev/null -w "%{http_code}" -X POST "$API/repos/$USER/$REPO/pages" -d '{"source":{"branch":"main","path":"/"}}')
[ "$PC" = "409" ] && PC=$(api -o /dev/null -w "%{http_code}" -X PUT "$API/repos/$USER/$REPO/pages" -d '{"source":{"branch":"main","path":"/"}}')
case "$PC" in
  201|204) echo "   ✔ Pages activo." ;;
  *) echo "   ⚠️  Pages devolvió $PC. Si el sitio no carga en 3 min, actívalo en Settings → Pages (main / root)." ;;
esac

# --- 4. Homepage ---
api -o /dev/null -X PATCH "$API/repos/$USER/$REPO" -d "{\"homepage\":\"https://$USER.github.io/$REPO/\"}"
echo "→ Homepage fijado."

echo ""
echo "════════════════════════════════════════"
echo "  Repo:  https://github.com/$USER/$REPO"
echo "  Sitio: https://$USER.github.io/$REPO/"
echo "════════════════════════════════════════"
echo "  Pages tarda 1-2 min la primera vez."
echo "  Copia todo esto y pégaselo a Claude."
