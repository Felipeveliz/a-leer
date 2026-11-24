#!/bin/bash
# Un archive de Release ocupa varios GB entre .xcarchive y el .ipa exportado, y
# los runtimes de simulador otro tanto. El 18 de noviembre la Mac se quedo con
# 118 MB libres y eso tumbo una prueba a media ejecucion en otro proyecto.
libres=$(df -g / 2>/dev/null | awk 'NR==2 {print $4}')
[ -z "$libres" ] && exit 0
if [ "$libres" -lt 10 ]; then
  echo "Aviso: quedan ${libres} GB libres en el disco. Un archive de Release necesita varios GB; limpiar Aprende/build/ y ~/Library/Developer/Xcode/Archives antes de subir un build."
fi
exit 0
