#!/bin/bash
# Guardarrail de la seccion 1 de CLAUDE.md, aplicado por la herramienta y no por
# la memoria del agente: las credenciales de Drive NUNCA entran a un commit.
#
# Por que importa aqui mas que en otros repos: este repo es PUBLICO y
# DriveCredentials.swift lleva el refresh token que comparten Aprende, Toss y
# Karol. Un commit con ese archivo no se arregla borrandolo despues: queda en el
# historial y hay que revocar el token, lo que tumba el feedback de las tres apps.
#
# Devuelve "ask" para que Felipe decida; nunca decide por su cuenta.
input=$(cat)
cmd=$(printf '%s' "$input" | jq -r '.tool_input.command // empty')
[ -z "$cmd" ] && exit 0

ask() {
  jq -nc --arg r "$1" \
    '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"ask",permissionDecisionReason:$r}}'
  exit 0
}

# 1. Un commit con credenciales en el stage.
case "$cmd" in
  *git\ commit*)
    staged=$(cd "${CLAUDE_PROJECT_DIR:-.}" 2>/dev/null && git diff --cached --name-only 2>/dev/null)
    leaked=$(printf '%s\n' "$staged" | grep -E '(^|/)DriveCredentials\.swift$|\.p8$|\.p12$|\.mobileprovision$|(^|/)\.env$' || true)
    [ -n "$leaked" ] && ask "Hay credenciales en el stage: $(printf '%s' "$leaked" | tr '\n' ' '). Este repo es publico y ese token lo comparten Aprende, Toss y Karol."
    ;;
esac

# 2. Forzar la entrada de un archivo ignorado (el camino clasico para que
#    DriveCredentials.swift se cuele saltandose .gitignore).
case "$cmd" in
  *git\ add\ *-f*|*git\ add\ *--force*)
    ask "Este 'git add' fuerza un archivo ignorado. Lo ignorado en este repo son las credenciales de Drive y los artefactos de build." ;;
esac

# 3. Quitar la regla del .gitignore que protege las credenciales.
case "$cmd" in
  *.gitignore*)
    case "$cmd" in
      *DriveCredentials*|*sed*.gitignore*|*\>\ .gitignore*|*\>.gitignore*)
        ask "Este comando reescribe .gitignore, que es lo unico que mantiene DriveCredentials.swift fuera de un repo publico." ;;
    esac
    ;;
esac
exit 0
