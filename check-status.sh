#!/usr/bin/env bash
set -e

CONTAINER_NAME="${1:-mongo-blog}"

if ! command -v docker >/dev/null 2>&1; then
  echo "[ERREUR] Docker n'est pas disponible dans ce terminal."
  exit 1
fi

if ! docker inspect "$CONTAINER_NAME" >/dev/null 2>&1; then
  echo "[ERREUR] Conteneur '$CONTAINER_NAME' introuvable."
  exit 1
fi

RUNNING="$(docker inspect -f '{{.State.Running}}' "$CONTAINER_NAME")"
if [ "$RUNNING" != "true" ]; then
  echo "[ERREUR] Le conteneur '$CONTAINER_NAME' n'est pas en cours d'execution."
  exit 1
fi
echo "[OK] Conteneur actif"

ROOT_USER="$(docker exec "$CONTAINER_NAME" printenv MONGO_INITDB_ROOT_USERNAME || true)"
ROOT_PASS="$(docker exec "$CONTAINER_NAME" printenv MONGO_INITDB_ROOT_PASSWORD || true)"

if [ -z "$ROOT_USER" ] || [ -z "$ROOT_PASS" ]; then
  echo "[ERREUR] Variables MONGO_INITDB_ROOT_USERNAME / MONGO_INITDB_ROOT_PASSWORD absentes."
  exit 1
fi

PING_RESULT="$(docker exec "$CONTAINER_NAME" mongosh --quiet --authenticationDatabase admin -u "$ROOT_USER" -p "$ROOT_PASS" --eval 'db.getSiblingDB("blog_db").runCommand({ ping: 1 }).ok' | tr -d '\r\n[:space:]')"
if [ "$PING_RESULT" != "1" ]; then
  echo "[ERREUR] Ping MongoDB KO sur blog_db."
  exit 1
fi
echo "[OK] MongoDB repond"

POSTS_COUNT="$(docker exec "$CONTAINER_NAME" mongosh --quiet --authenticationDatabase admin -u "$ROOT_USER" -p "$ROOT_PASS" --eval 'db.getSiblingDB("blog_db").posts.countDocuments({})' | tr -d '\r\n[:space:]')"
case "$POSTS_COUNT" in
  ''|*[!0-9]*)
    echo "[ERREUR] Impossible de lire le nombre de documents dans blog_db.posts."
    exit 1
    ;;
esac

if [ "$POSTS_COUNT" -lt 5 ]; then
  echo "[ERREUR] blog_db.posts contient $POSTS_COUNT document(s), minimum attendu: 5."
  exit 1
fi
echo "[OK] Donnees accessibles (posts: $POSTS_COUNT)"

MONGOD_USER="$(docker exec "$CONTAINER_NAME" sh -lc "ps -o user= -C mongod | head -n 1" | tr -d '\r\n[:space:]')"
if [ -z "$MONGOD_USER" ]; then
  echo "[ERREUR] Impossible d'identifier l'utilisateur du process mongod."
  exit 1
fi
if [ "$MONGOD_USER" = "root" ]; then
  echo "[ERREUR] Le process mongod tourne en root."
  exit 1
fi

echo "[OK] Utilisateur process mongod: $MONGOD_USER"
echo "[OK] Check termine avec succes"
