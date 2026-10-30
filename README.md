# Finanzas App

App multiplataforma (Android, iOS, iPadOS, web) para registrar gastos e inversiones, con notificaciones, tips y widgets. Prueba gratis de 30 días y luego suscripción cobrada con PayPhone.

Plan completo: `C:\Users\david\.claude\plans\quiero-hacer-una-app-mossy-milner.md`

## Estructura
- `app/` — Flutter con base local Drift/SQLite (ver `PROJECT_STATE.md`)
- `backend/supabase/migrations/` — esquema SQL (`0002` deja la paridad con la base local)
- `backend/supabase/functions/` — Edge Functions (`payphone-webhook`, `billing-cron`)

## Requisitos por instalar
Flutter SDK, Git, Node.js, Supabase CLI, Android Studio. Para iOS/iPadOS se necesita un Mac con Xcode.
