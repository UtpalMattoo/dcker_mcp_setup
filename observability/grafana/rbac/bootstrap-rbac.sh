#!/bin/sh
set -eu

GRAFANA_URL="${GRAFANA_URL:-http://lgtm:3000}"
GRAFANA_ADMIN_USER="${GRAFANA_ADMIN_USER:-admin}"
GRAFANA_ADMIN_PASSWORD="${GRAFANA_ADMIN_PASSWORD:-admin}"
DEV_USER="${GRAFANA_DEV_VIEWER_USER:-}"
DEV_PASS="${GRAFANA_DEV_VIEWER_PASSWORD:-}"
RESTRICTED_USER="${GRAFANA_RESTRICTED_USER:-}"
RESTRICTED_PASS="${GRAFANA_RESTRICTED_PASSWORD:-}"

api() {
  method="$1"
  path="$2"
  body="${3:-}"

  if [ -n "$body" ]; then
    curl -fsS -u "$GRAFANA_ADMIN_USER:$GRAFANA_ADMIN_PASSWORD" \
      -H "Content-Type: application/json" \
      -X "$method" "$GRAFANA_URL$path" \
      -d "$body"
  else
    curl -fsS -u "$GRAFANA_ADMIN_USER:$GRAFANA_ADMIN_PASSWORD" \
      -H "Content-Type: application/json" \
      -X "$method" "$GRAFANA_URL$path"
  fi
}

extract_number() {
  printf "%s" "$1" | sed -n 's/.*"id"[[:space:]]*:[[:space:]]*\([0-9][0-9]*\).*/\1/p' | head -n 1
}

extract_uid() {
  printf "%s" "$1" | sed -n 's/.*"uid"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -n 1
}

wait_for_grafana() {
  i=0
  until [ "$i" -ge 60 ]; do
    if curl -fsS "$GRAFANA_URL/api/health" >/dev/null 2>&1; then
      return 0
    fi
    i=$((i + 1))
    sleep 2
  done
  echo "Grafana health endpoint did not become ready in time" >&2
  exit 1
}

create_user_if_configured() {
  username="$1"
  password="$2"

  if [ -z "$username" ] || [ -z "$password" ]; then
    echo "Skipping optional user creation; credentials not supplied"
    return 0
  fi

  lookup="$(curl -fsS -u "$GRAFANA_ADMIN_USER:$GRAFANA_ADMIN_PASSWORD" "$GRAFANA_URL/api/users/lookup?loginOrEmail=$username" || true)"
  user_id="$(extract_number "$lookup")"

  if [ -n "$user_id" ]; then
    echo "$user_id"
    return 0
  fi

  payload="{\"name\":\"$username\",\"email\":\"$username@example.local\",\"login\":\"$username\",\"password\":\"$password\"}"
  created="$(api POST "/api/admin/users" "$payload")"
  user_id="$(extract_number "$created")"
  if [ -z "$user_id" ]; then
    echo "Failed to create user $username" >&2
    exit 1
  fi

  api PATCH "/api/org/users/$user_id" "{\"role\":\"Viewer\"}" >/dev/null || true
  echo "$user_id"
}

ensure_team() {
  team_name="$1"

  teams="$(api GET "/api/teams/search?name=$team_name")"
  team_id="$(printf "%s" "$teams" | sed -n 's/.*"id"[[:space:]]*:[[:space:]]*\([0-9][0-9]*\).*/\1/p' | head -n 1)"

  if [ -n "$team_id" ]; then
    echo "$team_id"
    return 0
  fi

  created="$(api POST "/api/teams" "{\"name\":\"$team_name\"}")"
  team_id="$(printf "%s" "$created" | sed -n 's/.*"teamId"[[:space:]]*:[[:space:]]*\([0-9][0-9]*\).*/\1/p' | head -n 1)"
  if [ -z "$team_id" ]; then
    echo "Failed to create team $team_name" >&2
    exit 1
  fi
  echo "$team_id"
}

ensure_folder() {
  folder_title="$1"

  uid_guess="$(printf "%s" "$folder_title" | tr '[:upper:] ' '[:lower:]-' | tr -cd 'a-z0-9-')"
  existing="$(api GET "/api/folders/$uid_guess" || true)"
  existing_uid="$(extract_uid "$existing")"
  if [ -n "$existing_uid" ]; then
    echo "$existing_uid"
    return 0
  fi

  created="$(api POST "/api/folders" "{\"title\":\"$folder_title\"}")"
  folder_uid="$(extract_uid "$created")"
  if [ -z "$folder_uid" ]; then
    echo "Failed to create folder $folder_title" >&2
    exit 1
  fi
  echo "$folder_uid"
}

add_user_to_team() {
  team_id="$1"
  user_id="$2"
  [ -z "$user_id" ] && return 0
  api POST "/api/teams/$team_id/members" "{\"userId\":$user_id}" >/dev/null || true
}

set_folder_permissions() {
  folder_uid="$1"
  dev_team_id="$2"
  restricted_team_id="$3"

  if [ "$folder_uid" = "$DEV_FOLDER_UID" ]; then
    payload="{\"items\":[{\"teamId\":$dev_team_id,\"permission\":1},{\"role\":\"Admin\",\"permission\":4},{\"role\":\"Editor\",\"permission\":2}]}"
  else
    payload="{\"items\":[{\"teamId\":$restricted_team_id,\"permission\":1},{\"role\":\"Admin\",\"permission\":4}]}"
  fi

  api POST "/api/folders/$folder_uid/permissions" "$payload" >/dev/null
}

wait_for_grafana

DEV_TEAM_ID="$(ensure_team "obs-dev")"
RESTRICTED_TEAM_ID="$(ensure_team "obs-restricted")"

DEV_USER_ID="$(create_user_if_configured "$DEV_USER" "$DEV_PASS")"
RESTRICTED_USER_ID="$(create_user_if_configured "$RESTRICTED_USER" "$RESTRICTED_PASS")"

add_user_to_team "$DEV_TEAM_ID" "$DEV_USER_ID"
add_user_to_team "$RESTRICTED_TEAM_ID" "$RESTRICTED_USER_ID"

DEV_FOLDER_UID="$(ensure_folder "Development Observability")"
RESTRICTED_FOLDER_UID="$(ensure_folder "Restricted Logs")"

set_folder_permissions "$DEV_FOLDER_UID" "$DEV_TEAM_ID" "$RESTRICTED_TEAM_ID"
set_folder_permissions "$RESTRICTED_FOLDER_UID" "$DEV_TEAM_ID" "$RESTRICTED_TEAM_ID"

echo "Grafana RBAC bootstrap complete"
