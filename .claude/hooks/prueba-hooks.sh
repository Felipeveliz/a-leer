#!/bin/bash
# Prueba de los hooks. Existe por la leccion mas cara del harness de TallerMaster:
# cuatro hooks no dispararon nunca porque leian el comando de una variable de
# entorno, cuando Claude Code entrega la llamada como JSON por la entrada
# estandar. Un guardarrail que no dispara es peor que no tenerlo, porque se da
# por hecho que esta protegiendo.
#
# La otra mitad de la prueba es que NO estorbe: un guardarrail que bloquea lo
# bueno se acaba apagando, y eso deja el repo sin proteccion ninguna.
#
#   bash .claude/hooks/prueba-hooks.sh
#
set -u
H="$(cd "$(dirname "$0")" && pwd)"
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
fallos=0

ok()    { printf '  ok    %s\n' "$1"; }
falla() { printf '  FALLA %s\n' "$1"; fallos=$((fallos + 1)); }

# Dos repos de mentiras: uno con las credenciales en el stage y otro limpio.
# Hacen falta los dos, porque la mitad de las pruebas es que el hook distingue
# entre un commit que SUBE el archivo y uno que solo lo NOMBRA.
nuevo_repo() {
  (cd "$1" && git init -q . && git config user.email t@t && git config user.name t) >/dev/null 2>&1
}
sucio="$tmp/sucio"; limpio="$tmp/limpio"
mkdir -p "$sucio/Aprende/Aprende" "$limpio"
nuevo_repo "$sucio"; nuevo_repo "$limpio"
(cd "$sucio" && echo 'let token = "x"' > Aprende/Aprende/DriveCredentials.swift \
  && git add -A -f) >/dev/null 2>&1
(cd "$limpio" && echo hola > a.txt && git add a.txt) >/dev/null 2>&1

decision() { # decision <repo> <comando>  → "deny", "" o lo que haya contestado
  printf '{"tool_input":{"command":%s}}' "$(jq -Rn --arg c "$2" '$c')" \
    | CLAUDE_PROJECT_DIR="$1" "$H/guard-bash.py" \
    | jq -r '.hookSpecificOutput.permissionDecision // empty' 2>/dev/null
}

niega() { # niega <descripcion> <repo> <comando>
  [ "$(decision "$2" "$3")" = "deny" ] && ok "$1" || falla "$1 — no bloqueo"
}

pasa() { # pasa <descripcion> <repo> <comando>
  d=$(decision "$2" "$3")
  [ -z "$d" ] && ok "$1" || falla "$1 — estorbo con: $d"
}

echo "guard-bash.py — bloquea"
niega "commit con las credenciales en el stage" "$sucio"  "git commit -m x"
niega "add forzado de las credenciales"         "$limpio" "git add -f Aprende/Aprende/DriveCredentials.swift"
niega "add forzado con la opcion larga"         "$limpio" "git add --force Aprende/Aprende/DriveCredentials.swift"
niega "credenciales en el segundo comando"      "$sucio"  "cd /x && git commit -m y"

echo "guard-bash.py — no estorba"
pasa "compilar"                  "$limpio" "xcodebuild -scheme Aprende build"
pasa "leer .gitignore"           "$limpio" "cat .gitignore"
pasa "add forzado de un build"   "$limpio" "git add -f Aprende/build/Aprende.ipa"
pasa "add normal"                "$limpio" "git add -A"
pasa "commit con el stage limpio" "$limpio" "git commit -m x"
# La regresion del 23 de noviembre: con el stage limpio, un commit cuyo MENSAJE
# nombra el archivo y cuya ruta lleva "-f" dentro. La version en bash lo
# bloqueaba por error, buscando los textos sueltos en el comando completo.
pasa "commit que solo nombra el archivo" "$limpio" \
     "git add -A && git commit -F /tmp/x-felipeveliz/m.txt  # DriveCredentials.swift"

echo "recordatorio-web.sh"
aviso=$(echo '{"tool_input":{"file_path":"/x/StoreManager.swift"}}' | "$H/recordatorio-web.sh")
case "$aviso" in *privacidad.html*) ok "avisa al tocar StoreManager.swift" ;;
  *) falla "no avisa al tocar StoreManager.swift" ;; esac
aviso=$(echo '{"tool_input":{"file_path":"/x/Theme.swift"}}' | "$H/recordatorio-web.sh")
[ -z "$aviso" ] && ok "calla al tocar Theme.swift" || falla "avisa de mas en Theme.swift"

echo "session-start.sh"
"$H/session-start.sh" >/dev/null 2>&1 && ok "corre sin error" || falla "sale con error"

echo
if [ "$fallos" -eq 0 ]; then echo "Los hooks responden y no estorban."; exit 0; fi
echo "$fallos prueba(s) fallaron."; exit 1
