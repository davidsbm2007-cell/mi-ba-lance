# Finanzas App ("Mi Balance") — Estado del proyecto

Actualizado: 2026-10-28 (base local Drift/SQLite implementada)

Documento para retomar el desarrollo. Plan original: `C:\Users\david\.claude\plans\quiero-hacer-una-app-mossy-milner.md`.

## 1. Resumen

App multiplataforma (Android, iOS/iPadOS, web/escritorio) para registrar gastos e ingresos, con presupuestos, metas, deudas y reportes en PDF. Objetivo comercial: Latinoamérica, multimoneda, 30 días gratis y luego suscripción cobrada con PayPhone (Ecuador, USD).

**Estado actual: prototipo funcional 100% local, con base SQLite (Drift).** Toda la UI principal existe y guarda en una base local cuyo esquema es espejo del de Supabase. No hay login, backend conectado, sincronización, notificaciones, widgets nativos, inversiones ni pagos.

## 2. Entorno y verificación

| Item | Valor |
|---|---|
| Flutter | 3.47.8 stable, Dart 3.13.7 (`C:\development\src\flutter`) |
| Proyecto Flutter | `app/` — paquete `finanzas_app`, id Android `com.finanzasapp.finanzas_app` |
| `flutter analyze` | Sin problemas (verificado 2026-10-28) |
| `flutter test` | 30 tests pasan (verificado 2026-10-28) |
| Git | **La carpeta NO es un repositorio git.** Hacer `git init` es lo primero recomendado. |
| `flutter doctor` | No ejecutado; falta confirmar toolchain Android/iOS. |
| Mac/Xcode | No disponible en esta máquina (necesario para compilar iOS/iPadOS y widgets WidgetKit). |
| Web | `flutter build web` compila y la app corre con sqlite3.wasm (ver §5 sobre la prueba pendiente en navegador real). |
| Android | `flutter build apk --debug` compila y la app corre en el emulador `Medium_Phone_API_37.0`; los datos persisten tras cerrar y reabrir (verificado 2026-10-28). Se instalaron en el SDK: NDK 28.2.13676358, plataformas android-34/35 y CMake 3.22.1. |

Ejecutar: `cd app && flutter run -d chrome` (o `-d windows` / emulador). Tests: `flutter test`.

## 3. Estructura

```
finanzas-app/
  README.md
  PROJECT_STATE.md          <- este archivo
  app/                      <- Flutter
    lib/
      main.dart, app.dart   <- init (locale 'es', base de datos, ProviderScope) y rutas go_router
      data/                 <- base local (ver §4)
      core/                 <- app_state, ids (uuid), theme, widgets, dialogs, format
      features/
        dashboard/  transactions/  movements/  budgets/  goals/  cards/
        debts/  reports/  settings/  shell/  demo/
    test/                   <- analytics, data, report_pdf, summary, widget tests
    assets/fonts/           <- Roboto (para el PDF)
    web/                    <- sqlite3.wasm + drift_worker.js (base en navegador)
  backend/supabase/
    migrations/0001_init.sql, 0002_local_parity.sql, 0003_cards.sql
```

## 4. Qué está hecho

**Navegación** (`app.dart`, `features/shell`): ShellRoute con pestañas `/` (dashboard), `/movimientos`, `/presupuestos`, `/deudas`, `/metas`, `/reportes`, `/config`, más `/add` fuera del shell. Layout adaptable: barra lateral en escritorio, pestañas en móvil.

**Estado:** Riverpod 3 (`Notifier`/`NotifierProvider`). Mes seleccionado global (`selectedMonthProvider`). Los notifiers de movimientos, presupuestos, metas y deudas mantienen la lista en memoria (la UI lee sin esperar) y escriben cada cambio en la base local.

**Funcionalidades (UI + lógica):**
- Dashboard: tarjetas y gráficos con fl_chart, barra de captura rápida (ícono de categoría = gasto, "3 puntos" = ingreso) — `dashboard_cards.dart` (730 líneas, el archivo más grande), `analytics.dart`, `quick_add_bar.dart`.
- Movimientos: alta, listado por mes, filas (`tx_row.dart`), validación de monto inválido.
- Presupuestos por categoría con límite.
- **Tarjetas** (`features/cards/`): tarjetas de crédito y débito registradas a mano. Crédito: cupo, lo usado, disponible, día de corte y de pago (con "en N días"); acciones *Registrar pago* y *Consumo*. Débito: saldo. Resumen con deuda en tarjetas, cupo disponible y próximo pago. Modelo `BankCard`, tabla `cards` (Drift `schemaVersion 2`, con migración `from < 2`) y `0003_cards.sql` para Supabase.
- Metas de ahorro con abonos.
- Deudas ("quién me debe") con cobro de abonos.
- Reportes con exportación PDF (`pdf` + `printing`, `report_pdf.dart`).
- Configuración: perfil, moneda, interruptores de notificaciones (solo UI), cargar datos de ejemplo, borrar todo.
- Datos demo (`features/demo`).
- Tema claro/oscuro, textos en español (`es`, fallback `en`).

**Base de datos local (Drift + SQLite)** — `app/lib/data/`:
- `database.dart`: tablas espejo de Supabase (`profiles`, `accounts`, `categories`, `transactions`, `budgets`, `investments`, `goals`, `debts`, `subscriptions`, `payments`). Mismos nombres de tabla y columna, ids UUID en texto, montos en centavos, `updated_at` y `deleted_at` en todo lo sincronizable. Al crearse siembra perfil local (`kLocalUserId`), prueba gratis de 30 días y las categorías base. `schemaVersion = 2` (v2 agrega la tabla `cards`).
- `database.g.dart`: generado. Regenerar con `dart run build_runner build` al cambiar `database.dart`.
- `connection.dart`: `driftDatabase(...)`: archivo SQLite en Android/iOS/escritorio; en web sqlite3.wasm con almacenamiento compartido vía `drift_worker.js`.
- `local_repository.dart`: lee/escribe; categorías por nombre a id, **borrado lógico** (`deleted_at`), `replace*` para datos demo y borrar todo.
- `providers.dart`: `databaseProvider`, `repositoryProvider`, `snapshotProvider` y `dataOverrides(db)`. `main()` y los tests inicializan con esto.
- `legacy_import.dart`: pasa una sola vez los datos viejos de `SharedPreferences` a la base (ids viejos a UUID estables). Las claves viejas quedan como respaldo, sin leerse.
- Ids: `core/ids.dart` (`newId()` UUID v4, `stableId(seed)` UUID v5 para demo).

**Backend (solo esquema):** `0001_init.sql` define `profiles`, `accounts`, `categories`, `transactions` (soft delete + `updated_at`), `budgets`, `investments`, `subscriptions` (trialing/active/past_due/expired, 30 días de prueba), `payments` (idempotencia por `client_transaction_id` y `provider_transaction_id`), trigger `handle_new_user` (crea perfil + suscripción en trial), RLS por usuario (suscripción y pagos son solo lectura para el cliente) y función `has_active_access(uid)`. La migración `0002_local_parity.sql` (todavía **no aplicada** a ningún proyecto) pasa los montos a centavos, añade `occurred_at`, presupuestos recurrentes (`month` nulo), columnas de sync, tablas `goals` y `debts`, y el trigger `touch_updated_at`.

## 4b. Diseño visual (pulido 2026-10-28)

Superficie de **trabajo** (app de finanzas): manda la lectura rápida y la consistencia; el color va en los datos, no en el marco.

- **Tipografía:** Figtree (variable, OFL) incluida en `app/assets/fonts/`; cifras con `kTabular` (alineadas en columna). Roboto sigue solo para el PDF.
- **Marco:** barra lateral clara sobre el mismo fondo, separada por una línea de 1px; ítem activo = pastilla gris neutra; marca propia (`BrandMark`, tres barras sobre azul marino), botón *Nuevo movimiento* arriba y fila de usuario abajo. Móvil: una sola barra inferior con Resumen, Movimientos, Tarjetas, Presupuestos y *Más* (Deudas, Metas, Reportes, Configuración) y un botón flotante *+* para registrar un movimiento. Se eliminó la barra de íconos de gasto rápido por categoría: la categoría se elige en la pantalla de alta.
- **Superficies planas:** sin sombras ni degradados; tarjeta = fondo blanco + línea 1px, radio 12 (`AppCard`). La única superficie oscura es la tarjeta de saldo, en azul marino plano.
- **Color con significado:** teal = dato principal; el estado de un presupuesto lo decide el porcentaje mostrado (<80% teal, 80–100% ámbar, >100% rojo) y el color de un cambio dice bueno/malo, no sube/baja. Botones primarios en azul marino (el turquesa claro no alcanza contraste con texto blanco); en oscuro, turquesa con texto marino.
- **Cifras como tipografía:** ingresos/gastos/ahorro y los resúmenes de deudas son una sola tarjeta dividida en columnas, sin íconos en círculos.
- **Gastos por categoría:** lista ordenada con barra fina (una sola tonalidad) en lugar del anillo de colores.
- **Primera lectura de cada pantalla:** el resumen abre con "Llevas $X de $Y presupuestados este mes" y presupuestos nombra la categoría más cercana a su límite.
- **Movimiento de carga:** las cifras de dinero suben desde $0,00 (`AnimatedMoney`), las barras de progreso se llenan y las líneas de los gráficos crecen desde la base (`GrowIn`), todo en `app/lib/core/motion.dart`. Se repite al cambiar de pestaña o de mes y se desactiva con "reducir movimiento" del sistema.
- **Tokens:** `app/lib/core/theme.dart` (`Brand`, `buildTheme`). Componentes compartidos: `app/lib/core/widgets.dart`.

## 5. Qué NO está hecho (brechas respecto al plan)

| Área | Estado |
|---|---|
| Autenticación | No existe. `kUserName = 'David'` es una constante en `core/app_state.dart`. |
| Supabase en la app | `supabase_flutter` está en pubspec pero **no se usa** en `lib/`. |
| Sincronización | No existe. La base local ya trae `updated_at`/`deleted_at` e ids UUID para subir/bajar cambios. |
| Esquema local vs. Supabase | Alineados en diseño (0002). Falta aplicar 0002 en un proyecto real y probar el ida y vuelta. |
| Web en navegador real | Con almacenamiento compartido no se pudo probar: el panel de navegador de la app bloquea `fetch` dentro de SharedWorkers. Sin worker la app corre bien (en memoria). **Probar en Chrome/Safari/Firefox reales** que los datos persistan al recargar. |
| Inversiones | Tabla en SQL y local; **sin pantalla ni modelo** en la app. |
| Multimoneda | Las tablas ya guardan `currency` (USD por defecto); la UI y `format.dart` siguen fijos en USD. |
| Gastos recurrentes | Campo `recurrence` en SQL y local; no implementado en la app. |
| Edge Functions | `backend/supabase/functions/` **no existe** (el README menciona `payphone-webhook` y `billing-cron`, pero no están creadas). |
| Pagos PayPhone / trial en la app | Sin pantalla de plan, sin gating, sin integración. |
| Notificaciones (FCM + locales) y tips | No existen; los switches de Configuración no hacen nada. |
| Widgets nativos | `home_widget` está en pubspec, sin uso; sin código Glance (Android) ni WidgetKit (iOS). |
| CI, analítica, crash reporting | No configurados. |
| Docs de privacidad/términos | No existen. |
| Dependencias | 16 paquetes con versión mayor nueva incompatible (informativo, no bloquea). |

## 6. Decisiones abiertas / riesgos (del plan, siguen vigentes)

1. **Políticas de tiendas:** Apple/Google exigen IAP/Play Billing para suscripciones digitales. Decidir: cobrar solo en web con PayPhone, o IAP en las apps y PayPhone en web.
2. **PayPhone es principalmente Ecuador (USD).** Diseñar pagos detrás de una interfaz `PaymentProvider`; confirmar con PayPhone: cobro recurrente, webhook/consulta de estado, sandbox.
3. **Credenciales de PayPhone** solo como secretos del backend, nunca en la app.
4. **Datos financieros sensibles:** cifrado, borrado de cuenta, política de privacidad.
5. **Android/iOS:** no se ha verificado un build de release ni el identificador definitivo (`com.finanzasapp.finanzas_app` es el predeterminado).

## 7. Próximos pasos sugeridos (orden)

1. `git init` + primer commit + `.gitignore` en la raíz (excluir `app/build`, `.dart_tool`).
2. Correr `flutter doctor`; probar en un teléfono Android físico.
3. Probar la web en un navegador real (persistencia tras recargar). `drift_worker.js` y `sqlite3.wasm` ya están en `app/web/`; si actualizas `drift` o `sqlite3`, recompila el worker (`dart compile js -O4 web/drift_worker.dart -o web/drift_worker.js`) y baja el wasm de la misma versión del paquete `sqlite3`.
4. **Backend:** crear proyecto Supabase, aplicar migraciones 0001 y 0002, probar RLS.
5. **Auth** con Supabase (email/Google), reemplazar `kUserName` y `kLocalUserId`, conectar perfil.
6. **Sincronización** local y Supabase usando `updated_at`/`deleted_at`: subir filas cambiadas, bajar las del servidor, resolver por `updated_at`.
7. **Suscripción:** pantalla de plan + gating; Edge Functions `payphone-webhook` (verificar estado del lado servidor, idempotente, validar monto) y `billing-cron`; tests con sandbox.
8. Inversiones (pantalla + rendimiento), recurrentes, multimoneda, notificaciones/tips, luego widgets.
9. Resolver política de tiendas antes de publicar.

## 8. Convenciones del código

- Un directorio por feature en `lib/features/<nombre>/` con `*_screen.dart`, `*_dialog.dart`, modelo y provider.
- Modelos de dominio (`Tx`, `Budget`, `Goal`, `Debt`) independientes de Drift; el mapeo vive en `data/local_repository.dart`.
- Ids nuevos siempre con `newId()` (UUID). Si cambias el esquema: editar `data/database.dart`, subir `schemaVersion` con su migración, regenerar con build_runner y replicar el cambio en una migración SQL de Supabase.
- Estado con Riverpod `Notifier`; los providers de datos exponen `replaceAll` y `clear` (usados por demo/borrado).
- Textos de UI en español; fechas con `intl` y locale `es`.
- Colores de marca en `core/theme.dart` (`Brand.*`).
- Tests usan `AppDatabase(NativeDatabase.memory())` + `dataOverrides(db)` y fuentes de `test/test_fonts.dart`.


## Beta 0.9.0 (2026-10-29)

- **Flujo inicial:** guía de bienvenida de 4 pantallas (`features/onboarding/onboarding_screen.dart`) y registro/ingreso de prueba (`register_screen.dart`). Acepta cualquier dato; solo exige un nombre (o un correo al entrar). Se guarda nombre/correo en SharedPreferences (`core/session.dart`); la contraseña nunca se guarda. El nombre se usa en el saludo, el avatar, la barra lateral y el PDF. Configuración permite cerrar sesión y volver a ver la guía. Rutas protegidas con `redirect` de go_router (`app.dart`).
- **Caché de animaciones:** `core/anim_cache.dart`. `AnimatedMoney`, `AppProgress` y `GrowIn` aceptan `cacheKey`; una cifra/barra ya vista no vuelve a animarse desde cero al regresar a la pantalla y, si el dato cambia, viaja desde el valor anterior. Vive mientras la app está abierta.
- **Archivo local de datos:** `data/backup/` escribe `mi_balance_datos.json` (documentos de la app) tras cada cambio en la base (debounce 700 ms); si al abrir la base está vacía y el archivo tiene datos, los restaura. En web no aplica (los datos viven en la base del navegador).
- Pruebas: 36 pasan. Versión `0.9.0+2`. APKs en `dist/` (arm64 para teléfonos, universal para emuladores). Guía iOS: `IOS_BUILD.md`.
- Pendiente: exportar/importar el JSON desde la UI, cuenta real con Supabase, sync, PayPhone, firma de release propia.
