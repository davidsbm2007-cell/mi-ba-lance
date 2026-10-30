# Compilar Mi Balance para iOS (desde una Mac)

La carpeta `app/ios` ya existe (nombre visible "Mi Balance", bundle id `com.finanzasapp.finanzasApp`, iOS mínimo 15.0). Falta lo que solo se puede hacer en Mac.

## Requisitos
- macOS con **Xcode** (App Store) y sus herramientas: `sudo xcode-select --install` y abrir Xcode una vez para aceptar la licencia.
- **Flutter 3.47.x** (el mismo del proyecto; verifica con `flutter --version`).
- **CocoaPods**: `brew install cocoapods`.
- Un **Apple ID** (gratis sirve para probar en tu propio iPhone; la cuenta Developer de pago, USD 99/año, hace falta para TestFlight y App Store).

## Pasos
```bash
cd app
flutter pub get
flutter doctor            # todo en verde en la parte de Xcode/CocoaPods
cd ios && pod install && cd ..
open ios/Runner.xcworkspace
```
1. En Xcode: **Runner → Signing & Capabilities** → marca *Automatically manage signing* y elige tu **Team**. Si el bundle id ya está tomado, cámbialo (por ejemplo `com.tuempresa.mibalance`).
2. Conecta el iPhone (modo desarrollador activado en Ajustes → Privacidad y seguridad) y ejecútalo:
   ```bash
   flutter run --release
   ```
3. Para TestFlight / App Store:
   ```bash
   flutter build ipa --release
   ```
   y sube el `.ipa` con la app **Transporter**.

## Cosas a vigilar
- Primera compilación lenta (descarga de pods).
- Si falla `pod install` por arquitectura en Mac con Apple Silicon: `arch -x86_64 pod install` o `pod repo update`.
- Los datos se guardan en SQLite dentro de la app y en `mi_balance_datos.json` en Documentos; en iOS se borran al desinstalar.
- Íconos y pantalla de inicio: aún son los de Flutter por defecto; cámbialos en `ios/Runner/Assets.xcassets` antes de publicar.
- Versión: `version: 0.9.0+2` en `pubspec.yaml` (0.9.0 = nombre, 2 = número de compilación; súbelo en cada envío).
