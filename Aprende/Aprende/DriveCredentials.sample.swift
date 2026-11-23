// Plantilla committeable. El archivo real DriveCredentials.swift está en .gitignore
// y contiene los valores reales. Para inicializar una checkout nueva:
//
//   cp DriveCredentials.sample.swift DriveCredentials.swift
//   # reemplazar los placeholders con los valores reales
//
// Cómo obtener los valores:
// 1. Crear proyecto en Google Cloud Console → habilitar Google Drive API.
// 2. Credentials → OAuth 2.0 Client ID → Desktop app.
// 3. Con el client_id/client_secret, hacer un OAuth flow una vez (scope
//    drive.file) para obtener un refresh_token de larga vida.
// 4. Pegar los tres valores en DriveCredentials.swift.
//
// Aprende reusa las mismas credenciales que Toss y KarolPhotoBooth (mismo
// proyecto de Google Cloud / mismo refresh_token); solo cambia `rootFolderName`
// a "Aprende" para aislar sus carpetas en Drive. El scope `drive.file` hace que el client
// solo vea archivos que él mismo creó, así que ambas apps conviven en la misma
// cuenta sin colisión.
//
// El refresh_token no expira mientras no se revoque manualmente desde la
// cuenta de Google, y se usa para obtener access_tokens frescos en runtime.
//
// El bloque de abajo va envuelto en `#if false` para que este archivo (que
// sí se commitea) no colisione con la declaración real al compilar.

#if false
import Foundation

enum DriveCredentials {
    static let clientId = "REPLACE_ME_CLIENT_ID.apps.googleusercontent.com"
    static let clientSecret = "REPLACE_ME_CLIENT_SECRET"
    static let refreshToken = "REPLACE_ME_REFRESH_TOKEN"

    // Scope mínimo: la app solo ve archivos que ella misma creó.
    static let scope = "https://www.googleapis.com/auth/drive.file"

    // Nombre fijo del folder raíz en Drive. Todo el feedback cuelga de aquí.
    static let rootFolderName = "Aprende"

    // Flag derivado: true solo si los 3 valores fueron reemplazados.
    static var isConfigured: Bool {
        !clientId.hasPrefix("REPLACE_ME")
            && !clientSecret.hasPrefix("REPLACE_ME")
            && !refreshToken.hasPrefix("REPLACE_ME")
    }
}
#endif
