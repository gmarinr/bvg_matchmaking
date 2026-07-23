# Match Making

Aplicación Flutter para coordinar partidos deportivos amateur. El MVP se
centra en el partido y en el flujo completo entre un organizador y sus
participantes.

## Flujo principal

`registro -> perfil -> crear o buscar partido -> solicitar -> aceptar -> confirmar`

El sistema debe permitir que un usuario cree un partido, otro usuario lo
encuentre y solicite participar, y que el organizador gestione la solicitud y
el estado del encuentro.

## Alcance del MVP

- Autenticación con Supabase Auth.
- Perfil deportivo básico.
- Creación y búsqueda de partidos.
- Solicitudes y gestión de participantes.
- Confirmación de asistencia y estados del partido.
- Seguridad mediante Row Level Security.

No se implementan equipos permanentes, rankings, torneos, pagos,
notificaciones push ni geolocalización en tiempo real.

## Arquitectura

La aplicación usa una estructura por funcionalidades:

```text
lib/
├── app/
├── core/
└── features/
    ├── auth/
    ├── home/
    ├── matches/
    └── profile/
```

La UI depende de contratos de repositorio. Los repositorios falsos permiten
ejecutar la aplicación sin backend; cuando existen las variables de entorno,
Riverpod inyecta las implementaciones de Supabase.

## Base de datos

Las migraciones se encuentran en:

`supabase/migrations/20260722000000_initial_matchmaking_schema.sql`

`supabase/migrations/20260723000000_harden_private_helpers.sql`

`supabase/migrations/20260723010000_revoke_public_helper_execute.sql`

Incluye:

- perfiles, deportes, deportes por usuario, partidos y participaciones;
- enums alineados con `lib/core/domain/enums.dart`;
- semillas iniciales de deportes;
- restricciones de integridad y unicidad;
- triggers para crear la participación del organizador y sincronizar cupos;
- políticas RLS para autenticación, perfiles, partidos y participaciones.

La migración inicial y los ajustes de seguridad ya fueron aplicados al proyecto
Supabase configurado mediante MCP. En otro proyecto deben aplicarse en orden
antes de probar la persistencia remota.

## Configuración segura

No se guardan credenciales en el repositorio. La URL y la clave publicable de
Supabase se pasan en tiempo de ejecución:

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://tu-proyecto.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=tu-clave-publicable
```

Nunca usar `service_role` en Flutter ni subir archivos `.env` con secretos.
La seguridad depende de RLS, no de ocultar la clave publicable.

## Verificación

```bash
flutter pub get
flutter analyze
flutter test
```

Sin variables de Supabase, la aplicación usa datos falsos en memoria y permite
validar la navegación y la UI. Con variables configuradas, usa los
repositorios reales.

## Rama de trabajo

El desarrollo de base de datos se realiza en `feat/database`, creada a partir
de `feat/frontend-ui`. La rama original de UI no se modifica desde este
trabajo.
