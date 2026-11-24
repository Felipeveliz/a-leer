#!/bin/bash
# La seccion 8 de CLAUDE.md pide que cada cambio que toque red, compras o datos
# guardados llegue tambien a privacidad.html y soporte.html: el revisor de Apple
# las lee, y la 1.0 llego a revision diciendo que la app no se conecta a internet
# cuando ya tenia compras y consulta de version. Es una regla que depende de que
# el agente se acuerde, asi que la recuerda la herramienta.
input=$(cat)
archivo=$(printf '%s' "$input" | jq -r '.tool_input.file_path // empty')
[ -z "$archivo" ] && exit 0

case "$(basename "$archivo")" in
  UpdateChecker.swift|UpdateGate.swift|StoreManager.swift|CafeView.swift|FeedbackService.swift|DriveFeedbackClient.swift|IdeaView.swift|PracticeLog.swift|PerfilStore.swift|ProgressStore.swift|HojaStore.swift|PrivacyInfo.xcprivacy)
    echo "Recordatorio: acabas de tocar $(basename "$archivo"), que entra en red, compras o datos guardados. Revisa si privacidad.html y soporte.html siguen diciendo la verdad (CLAUDE.md seccion 8)."
    ;;
esac
exit 0
