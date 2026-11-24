#!/usr/bin/env python3
"""Guardarrail de la seccion 1 de CLAUDE.md, aplicado por la herramienta y no por
la memoria del agente: las credenciales de Drive NUNCA entran a un commit.

Por que importa aqui mas que en otros repos: este repo es PUBLICO y el archivo
de credenciales lleva el refresh token que comparten Aprende, Toss y Karol. Un
commit con ese archivo no se arregla borrandolo despues: queda en el historial y
hay que revocar el token, lo que tumba el feedback de las tres apps.

Decide "deny", no "ask" (Felipe, 23 de noviembre): un hook que pregunta
interrumpe incluso con los permisos en bypass, y aqui no hay nada que decidir.
Lo que si hay que decidir se pregunta en el chat, no en un dialogo de permiso.

Esta en Python y no en bash por un falso positivo real del 23 de noviembre:
buscando los textos sueltos en el comando completo, un 'git add -A' inocente
quedo bloqueado porque la ruta del scratchpad contenia "-felipeveliz" y el
mensaje del commit nombraba el archivo de credenciales. Un guardarrail que
bloquea lo bueno se acaba apagando, asi que aqui se parten los argumentos de
verdad y solo cuenta lo que es de veras una ruta de ese comando.
"""
import json
import os
import re
import shlex
import subprocess
import sys

SECRETO = re.compile(
    r"(^|/)DriveCredentials\.swift$|\.p8$|\.p12$|\.mobileprovision$|(^|/)\.env$"
)
SEPARADORES = {"&&", "||", "|", ";", "&", "\n"}


def niega(razon):
    json.dump({"hookSpecificOutput": {
        "hookEventName": "PreToolUse",
        "permissionDecision": "deny",
        "permissionDecisionReason": razon,
    }}, sys.stdout)
    sys.exit(0)


def comandos(texto):
    """Parte una linea de shell en comandos sueltos, ya tokenizados."""
    try:
        piezas = shlex.split(texto, comments=False)
    except ValueError:            # comillas sin cerrar: no adivinamos nada
        return []
    actual, salida = [], []
    for pieza in piezas:
        if pieza in SEPARADORES:
            if actual:
                salida.append(actual)
            actual = []
        else:
            actual.append(pieza)
    if actual:
        salida.append(actual)
    return salida


def staged_en(raiz):
    try:
        hecho = subprocess.run(
            ["git", "diff", "--cached", "--name-only"],
            cwd=raiz, capture_output=True, text=True, timeout=10,
        )
    except (OSError, subprocess.SubprocessError):
        return []
    return hecho.stdout.split()


def main():
    try:
        entrada = json.load(sys.stdin)
    except (json.JSONDecodeError, ValueError):
        return
    cmd = (entrada.get("tool_input") or {}).get("command") or ""
    if not cmd:
        return

    for argv in comandos(cmd):
        if len(argv) < 2 or os.path.basename(argv[0]) != "git":
            continue
        sub, args = argv[1], argv[2:]

        # 1. Un commit con credenciales en el stage. Se mira el stage de verdad,
        #    no el texto del comando: el commit puede nombrar el archivo en su
        #    mensaje sin estarlo subiendo.
        if sub == "commit":
            filtrado = [f for f in staged_en(os.environ.get("CLAUDE_PROJECT_DIR") or ".")
                        if SECRETO.search(f)]
            if filtrado:
                niega("Hay credenciales en el stage: " + " ".join(filtrado)
                      + ". Este repo es publico y ese token lo comparten Aprende, Toss y"
                      " Karol. Sacalo con 'git restore --staged' y vuelve a commitear.")

        # 2. Forzar la entrada de un archivo ignorado: el camino clasico para que
        #    las credenciales se cuelen saltandose .gitignore.
        if sub == "add":
            forzado = any(
                a == "--force"
                or (a.startswith("-") and not a.startswith("--") and "f" in a[1:])
                for a in args
            )
            if not forzado:
                continue
            filtrado = [a for a in args if not a.startswith("-") and SECRETO.search(a)]
            if filtrado:
                niega("Ese 'git add' forzado mete credenciales a un repo publico: "
                      + " ".join(filtrado) + ". Estan en .gitignore a proposito.")


if __name__ == "__main__":
    main()
