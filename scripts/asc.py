#!/usr/bin/env python3
"""Cliente mínimo de la API de App Store Connect, para no depender de la sesión
del navegador (ESTANDAR.md §4 / S-001).

Firma el token ES256 con openssl, así que no hace falta instalar nada: esta Mac
no tiene PyJWT ni cryptography.

La llave privada se lee del disco, se usa para firmar y **nunca se imprime**;
tampoco el token. Si algo falla, el mensaje no lleva ninguno de los dos.

Uso:
    asc.py estado                      ¿qué versiones hay y en qué estado?
    asc.py leer <archivo>              baja la descripción de la versión editable
    asc.py escribir <archivo>          sube ese archivo como descripción
    asc.py novedades <archivo>         sube "Novedades de esta versión"

Variables de entorno:
    ASC_KEY_ID     identificador de la llave (el del nombre del .p8)
    ASC_ISSUER_ID  identificador del emisor (Users and Access > Integrations)
    ASC_KEY_FILE   ruta del .p8  (por omisión ~/.appstoreconnect/private_keys/AuthKey_<KEY_ID>.p8)
    ASC_APP_ID     identificador de la app en App Store Connect
"""
import base64
import json
import os
import subprocess
import sys
import time
import urllib.error
import urllib.request

API = "https://api.appstoreconnect.apple.com"
# Idioma de la ficha. Aprende solo está localizada en español de México.
LOCALE = "es-MX"
# Estados en los que App Store Connect deja editar la metadata de una versión.
EDITABLES = {
    "PREPARE_FOR_SUBMISSION", "DEVELOPER_REJECTED", "REJECTED",
    "METADATA_REJECTED", "WAITING_FOR_REVIEW", "INVALID_BINARY",
}


def muere(mensaje):
    print(mensaje, file=sys.stderr)
    sys.exit(1)


def b64(datos):
    return base64.urlsafe_b64encode(datos).rstrip(b"=")


def der_a_crudo(der):
    """La firma que da openssl viene en DER (SEQUENCE de dos enteros) y el token
    la necesita como r||s de 32 bytes cada uno."""
    if der[0] != 0x30:
        raise ValueError("firma inesperada")
    i = 2 if der[1] < 0x80 else 3 + (der[1] & 0x7F) - 1
    salida = b""
    for _ in range(2):
        if der[i] != 0x02:
            raise ValueError("firma inesperada")
        largo = der[i + 1]
        entero = der[i + 2:i + 2 + largo].lstrip(b"\x00")
        salida += entero.rjust(32, b"\x00")
        i += 2 + largo
    return salida


def token():
    key_id = os.environ.get("ASC_KEY_ID") or muere("falta ASC_KEY_ID")
    issuer = os.environ.get("ASC_ISSUER_ID") or muere("falta ASC_ISSUER_ID")
    ruta = os.environ.get("ASC_KEY_FILE") or os.path.expanduser(
        f"~/.appstoreconnect/private_keys/AuthKey_{key_id}.p8")
    if not os.path.exists(ruta):
        muere(f"no encuentro la llave en {ruta}")

    ahora = int(time.time())
    cabecera = {"alg": "ES256", "kid": key_id, "typ": "JWT"}
    cuerpo = {"iss": issuer, "iat": ahora, "exp": ahora + 600,
              "aud": "appstoreconnect-v1"}
    firmable = b64(json.dumps(cabecera).encode()) + b"." + b64(json.dumps(cuerpo).encode())
    try:
        der = subprocess.run(["openssl", "dgst", "-sha256", "-sign", ruta],
                             input=firmable, capture_output=True, check=True).stdout
    except subprocess.CalledProcessError:
        # A propósito no se reproduce la salida de openssl: puede llevar material
        # de la llave.
        muere("openssl no pudo firmar con esa llave")
    return (firmable + b"." + b64(der_a_crudo(der))).decode()


def llama(ruta, metodo="GET", cuerpo=None):
    pedido = urllib.request.Request(
        ruta if ruta.startswith("http") else API + ruta, method=metodo,
        data=json.dumps(cuerpo).encode() if cuerpo is not None else None,
        headers={"Authorization": "Bearer " + token(),
                 "Content-Type": "application/json"})
    try:
        with urllib.request.urlopen(pedido, timeout=60) as r:
            crudo = r.read()
            return json.loads(crudo) if crudo else {}
    except urllib.error.HTTPError as e:
        detalle = e.read().decode(errors="replace")
        try:
            errores = json.loads(detalle).get("errors", [])
            detalle = "\n".join(
                f"  [{x.get('status')}] {x.get('title')}: {x.get('detail')}" for x in errores)
        except ValueError:
            pass
        muere(f"La API contestó {e.code}:\n{detalle}")


def app_id():
    return os.environ.get("ASC_APP_ID") or muere("falta ASC_APP_ID")


def versiones():
    datos = llama(f"/v1/apps/{app_id()}/appStoreVersions?limit=10")["data"]
    return [(v["id"], v["attributes"]["versionString"], v["attributes"]["appStoreState"])
            for v in datos]


def version_editable():
    for vid, numero, estado in versiones():
        if estado in EDITABLES:
            return vid, numero, estado
    muere("ninguna versión está en un estado editable; mira 'estado'")


def localizacion(version_id):
    for loc in llama(f"/v1/appStoreVersions/{version_id}/appStoreVersionLocalizations")["data"]:
        if loc["attributes"]["locale"] == LOCALE:
            return loc
    muere(f"la versión no tiene localización {LOCALE}")


def main():
    if len(sys.argv) < 2:
        muere(__doc__)
    orden = sys.argv[1]

    if orden == "estado":
        for vid, numero, estado in versiones():
            marca = "editable" if estado in EDITABLES else "bloqueada"
            print(f"  {numero:8} {estado:28} {marca}   id {vid}")
        return

    if orden in {"leer", "escribir", "novedades"} and len(sys.argv) < 3:
        muere(f"uso: asc.py {orden} <archivo>")

    if orden == "leer":
        # Leer no cambia nada, asi que vale tambien sobre una version publicada:
        # es la unica forma de ver el texto vivo sin la consola.
        vid, numero, estado = versiones()[0]
    else:
        vid, numero, estado = version_editable()
    loc = localizacion(vid)
    campo = "whatsNew" if orden == "novedades" else "description"

    if orden == "leer":
        texto = loc["attributes"]["description"] or ""
        with open(sys.argv[2], "w", encoding="utf-8") as f:
            f.write(texto)
        print(f"  versión {numero} ({estado}) · descripción de {len(texto)} caracteres"
              f" guardada en {sys.argv[2]}")
        return

    with open(sys.argv[2], encoding="utf-8") as f:
        texto = f.read()
    if len(texto) > 4000:
        muere(f"{len(texto)} caracteres: el campo admite 4000")
    llama(f"/v1/appStoreVersionLocalizations/{loc['id']}", "PATCH",
          {"data": {"type": "appStoreVersionLocalizations", "id": loc["id"],
                    "attributes": {campo: texto}}})
    print(f"  versión {numero} ({estado}) · {campo} actualizado, {len(texto)} caracteres")


if __name__ == "__main__":
    main()
