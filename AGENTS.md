# AGENTS.md — Match Making

## 1. Propósito

Este documento define el alcance funcional y técnico vigente del proyecto.
Todo agente debe leerlo junto con `planificación.md` antes de modificar código.

Fecha de contexto: 23 de julio de 2026.

El objetivo actual es entregar un MVP sencillo para **encontrar personas,
completar cupos y coordinar un partido**. No se deben incorporar equipos,
resultados, rankings ni historial deportivo en esta etapa.

---

## 2. Resumen del producto

Match Making es una aplicación Flutter para organizar encuentros deportivos
amateurs entre usuarios individuales.

El flujo principal es:

`registro → perfil deportivo → buscar o crear partido → solicitar cupo → aceptar → confirmar asistencia → coordinar`

La unidad central es el partido. El MVP permite amistades explícitas entre
usuarios mediante solicitudes, pero no crea equipos permanentes.

### Propuesta de valor

> Encuentra personas disponibles para practicar tu deporte y coordina el
> encuentro desde una sola aplicación.

---

## 3. Alcance obligatorio del MVP

### 3.1 Registro, autenticación y onboarding

El usuario puede:

- crear una cuenta con correo y contraseña;
- iniciar sesión;
- enviar el formulario de inicio de sesión presionando Enter;
- cerrar sesión;
- completar obligatoriamente su perfil deportivo antes de entrar al flujo
  principal.

El registro debe funcionar como un flujo de varios pasos:

1. Crear la cuenta.
2. Confirmar el correo si Supabase lo exige.
3. Completar nombre, comuna, deportes, nivel por deporte y disponibilidad.
4. Entrar a la aplicación solo cuando el perfil obligatorio esté completo.

Si la confirmación de correo interrumpe el registro, el router debe reanudar
el onboarding después del primer inicio de sesión.

### 3.2 Perfil deportivo

El usuario puede:

- registrar y editar su nombre;
- registrar y editar su comuna;
- seleccionar uno o más deportes;
- indicar su nivel en cada deporte;
- indicar su disponibilidad general;
- ver de forma privada su UUID de usuario;
- copiar su UUID al portapapeles para compartirlo por un canal externo.

El UUID mostrado es `auth.users.id`, que también corresponde a `profiles.id`.
No crear un segundo identificador.

### 3.3 Búsqueda de usuarios por ID

Un usuario autenticado puede buscar otro usuario introduciendo su UUID exacto.

Reglas:

- no se permite búsqueda parcial;
- no se permite enumerar todos los usuarios;
- no se expone correo ni información de autenticación;
- el resultado muestra solo un perfil público mínimo: UUID, nombre visible,
  comuna, deportes y niveles;
- el resultado nunca muestra correo ni disponibilidad general;
- buscar un usuario no crea una amistad, contacto ni equipo;
- desde el resultado se puede enviar una solicitud de amistad mediante una
  acción explícita;
- un ID inexistente debe mostrar un estado vacío comprensible;
- un ID con formato inválido debe validarse antes de consultar Supabase.

### 3.4 Solicitudes y lista de amigos

Un usuario autenticado puede:

- enviar una solicitud de amistad desde un perfil encontrado por UUID;
- consultar solicitudes recibidas y enviadas;
- aceptar o rechazar una solicitud recibida;
- cancelar una solicitud propia pendiente;
- consultar su lista de amigos aceptados;
- eliminar una amistad.

Reglas de interfaz:

- no se puede enviar una solicitud a uno mismo;
- una pareja de usuarios no puede tener dos solicitudes activas;
- si ya existe amistad, la búsqueda debe mostrar ese estado;
- si existe una solicitud pendiente, la UI distingue quién debe responder;
- rechazar, cancelar o eliminar no borra el registro histórico;
- no existen sugerencias automáticas ni búsqueda parcial de personas.

### 3.5 Creación de partidos

El usuario puede crear un partido indicando:

- deporte;
- título;
- fecha y hora;
- comuna;
- lugar;
- nivel esperado;
- cantidad mínima de participantes;
- cantidad máxima de participantes;
- descripción adicional opcional.

Los cupos disponibles se derivan:

`capacidad máxima - participantes aceptados`

No se editan como un contador independiente.

### 3.6 Exploración visual por deporte

La pantalla de búsqueda debe utilizar widgets de deportes en lugar de depender
solo de chips de texto.

Cada widget:

- representa un deporte activo del catálogo;
- muestra el emoji centrado y el nombre del deporte debajo;
- es accesible por teclado y lector de pantalla;
- tiene estado seleccionado;
- filtra o abre los partidos del deporte;
- usa una transición `Hero` hacia una vista de resultados del deporte.

La implementación recomendada es:

- origen: `SportSelectorCard` o widget equivalente;
- destino: encabezado de una ruta o vista filtrada por deporte;
- tag estable: `sport-${sport.id}`;
- emoji obtenido del catálogo o de un mapeo central por `sport.id`;
- tenis y pádel pueden compartir `🎾`, porque el nombre visible debajo del
  emoji identifica claramente cada deporte.

No usar el mismo icono de fútbol para todos los deportes.

### 3.7 Búsqueda y filtros de partidos

Los partidos pueden filtrarse por:

- deporte;
- fecha;
- comuna;
- nivel;
- existencia o cantidad mínima de cupos disponibles.

La lista y el detalle muestran:

- deporte;
- fecha y hora;
- comuna y lugar;
- nivel;
- participantes aceptados;
- capacidad máxima;
- cupos disponibles;
- estado actual.

### 3.8 Gestión de participantes

Los usuarios pueden:

- solicitar incorporarse a un partido abierto;
- cancelar su propia solicitud;
- consultar el estado de su solicitud;
- consultar participantes aceptados cuando estén autorizados;
- consultar cupos disponibles;
- confirmar o rechazar su asistencia después de ser aceptados.

El organizador puede:

- consultar solicitudes;
- aceptar o rechazar solicitudes;
- consultar participantes y confirmaciones;
- designar coorganizadores si se completa ese flujo.

### 3.9 Gestión y coordinación del encuentro

Los organizadores autorizados pueden:

- editar fecha, hora, comuna o lugar;
- confirmar el encuentro;
- cancelar el encuentro;
- informar cambios a los participantes aceptados.

Los organizadores y participantes aceptados pueden usar un chat básico
asociado al partido para coordinarse.

Los avisos estructurados de cambios importantes no deben depender únicamente
del chat.

---

## 4. Funcionalidades posteriores al MVP

No implementar estas capacidades durante el plan actual:

- creación de equipos;
- equipos permanentes;
- búsqueda de equipo rival;
- lados local y rival;
- resultados o marcadores;
- confirmación o disputa de resultados;
- recomendaciones sobre equipos rivales;
- historial de partidos jugados;
- rankings;
- estadísticas deportivas;
- torneos o ligas;
- sistema de amigos o contactos;
- pagos o reservas;
- notificaciones push;
- geolocalización en tiempo real.

Los enums o columnas ya existentes para `rival_team` o `completed` pueden
permanecer por compatibilidad, pero no justifican construir esos flujos ahora.
No crear migraciones destructivas solo para eliminarlos.

---

## 5. Roles

### Organizador principal

Es el creador del partido. Administra datos, solicitudes, estado y
coordinación.

### Coorganizador

Usuario autorizado por el organizador principal para colaborar con la gestión.
Esta capacidad no implica crear equipos.

### Participante

Busca partidos, solicita un cupo, confirma asistencia y accede a la
coordinación cuando fue aceptado.

---

## 6. Flujos obligatorios

### Flujo A — Registro y perfil

1. El usuario ingresa correo y contraseña.
2. Crea su cuenta.
3. Confirma su correo cuando corresponda.
4. Completa nombre y comuna.
5. Selecciona al menos un deporte y su nivel.
6. Registra disponibilidad.
7. El sistema valida que el perfil esté completo.
8. Entra a la pantalla principal.

### Flujo B — Login por teclado

1. El usuario ingresa correo.
2. Presiona Tab o selecciona contraseña.
3. Ingresa contraseña.
4. Presiona Enter.
5. Se ejecuta la misma validación y acción que el botón “Iniciar sesión”.
6. Mientras se autentica, no se permiten envíos duplicados.

### Flujo C — Compartir y buscar ID

1. El usuario abre su perfil.
2. Ve su UUID en una sección privada.
3. Lo copia al portapapeles.
4. Lo comparte fuera de la aplicación.
5. Otro usuario pega el UUID en “Buscar usuario”.
6. La aplicación valida el formato y consulta el perfil público mínimo.

### Flujo D — Solicitud de amistad

1. El usuario encuentra un perfil mediante UUID.
2. Envía una solicitud de amistad.
3. El receptor consulta sus solicitudes pendientes.
4. Acepta o rechaza.
5. Al aceptar, ambos aparecen en sus listas de amigos.
6. Cualquiera puede eliminar posteriormente la amistad.

### Flujo E — Explorar por deporte

1. La aplicación carga deportes activos.
2. Muestra widgets con el emoji y el nombre del deporte debajo.
3. El usuario selecciona un deporte.
4. Se navega con `Hero` a resultados filtrados.
5. Puede aplicar filtros adicionales.

### Flujo F — Participar

1. El usuario abre un partido.
2. Consulta detalles y cupos.
3. Solicita participar.
4. El organizador acepta o rechaza.
5. Si fue aceptado, confirma asistencia.
6. Accede a avisos y chat para coordinar.

---

## 7. Estados vigentes

### Estado del partido: `match_status`

- `draft`
- `open`
- `full`
- `confirmed`
- `cancelled`

`completed` puede permanecer en el esquema como estado técnico reservado, pero
el MVP no presenta historial ni resultados.

### Estado de participación: `participation_status`

- `pending`
- `accepted`
- `rejected`
- `cancelled`

### Confirmación de asistencia: `attendance_status`

- `unknown`
- `confirmed`
- `declined`

El modo `recruitment_mode` del MVP es únicamente `players`.
`rival_team` queda reservado para una etapa futura.

---

## 8. Reglas de negocio

1. Todo usuario debe completar el onboarding antes de acceder a partidos.
2. El perfil obligatorio requiere nombre, comuna, al menos un deporte con
   nivel y disponibilidad.
3. El UUID propio se muestra solo dentro del perfil del usuario autenticado.
4. La búsqueda de usuarios acepta únicamente UUID exactos.
5. La búsqueda no expone correo, teléfono ni datos de autenticación.
6. Buscar un usuario no crea una amistad automáticamente.
7. Un usuario no puede enviarse una solicitud de amistad a sí mismo.
8. Solo el destinatario acepta o rechaza una solicitud.
9. Solo el solicitante cancela su solicitud pendiente.
10. Cualquiera de los dos usuarios puede eliminar una amistad aceptada.
11. No puede existir más de una solicitud o amistad activa para la misma
    pareja de usuarios.
12. Todo partido tiene un organizador principal.
13. Los cupos se derivan de capacidad y participaciones aceptadas.
14. Un usuario no puede solicitar dos veces el mismo partido.
15. El organizador no solicita cupo en su propio partido.
16. Solo organizadores aceptan o rechazan solicitudes de participación.
17. Solo participantes aceptados confirman asistencia.
18. Un partido sin cupos pasa a `full`.
19. Un partido cancelado no recibe solicitudes.
20. Solo organizadores y aceptados acceden al chat.
21. Cambios de fecha, hora o lugar generan un aviso interno.
22. No guardar resultados, recomendaciones ni historial deportivo.

---

## 9. Modelo de datos vigente

### `profiles`

- `id`: mismo UUID de `auth.users.id`
- `display_name`
- `commune`
- `avatar_url` opcional
- `general_availability`
- `created_at`
- `updated_at`

### `sports`

- `id`
- `name`
- `is_active`

Los emojis no se persisten en Supabase. Se resuelven mediante un mapeo central
en Flutter por `sport.id`.

### `user_sports`

- `user_id`
- `sport_id`
- `skill_level`

Clave única: `user_id + sport_id`.

### `friendships`

- `id`
- `requester_id`
- `addressee_id`
- `status`: `pending`, `accepted`, `rejected` o `cancelled`
- `created_at`
- `updated_at`

Solo puede existir una relación activa (`pending` o `accepted`) por pareja de
usuarios, sin importar quién la inició.

### `matches`

- `id`
- `organizer_id`
- `sport_id`
- `title`
- `description`
- `start_at`
- `commune`
- `location_text`
- `skill_level`
- `min_participants`
- `max_participants`
- `status`
- `created_at`
- `updated_at`

### `match_participations`

- `id`
- `match_id`
- `user_id`
- `role`
- `participation_status`
- `attendance_status`
- `created_at`
- `updated_at`

### `match_updates`

Avisos estructurados para cambios relevantes:

- `id`
- `match_id`
- `created_by`
- `type`
- `summary`
- `metadata`
- `created_at`

### `messages`

- `id`
- `match_id`
- `sender_id`
- `content`
- `created_at`

No crear tablas de equipos, resultados, recomendaciones o historial.

---

## 10. Arquitectura y stack

- Flutter y Dart.
- Material Design.
- Riverpod.
- go_router.
- Supabase Auth y PostgreSQL.
- Row Level Security.
- Supabase Realtime solo donde aporte al chat o avisos.

Estructura:

```text
lib/
├── app/
├── core/
└── features/
    ├── auth/
    ├── profile/
    ├── users/
    ├── friendships/
    ├── matches/
    ├── notifications/
    └── chat/
```

Reglas:

- La UI depende de contratos de repositorio.
- No consultar Supabase directamente desde widgets.
- Mantener repositorios falsos y Supabase equivalentes.
- Mantener sincronizados enums Dart y PostgreSQL.
- No actualizar dependencias mayores sin migrar el código y `pubspec.lock`.
- Centralizar el emoji de cada deporte; no dispersar literales por widgets.

---

## 11. Seguridad y privacidad

- El usuario administra su propio perfil y deportes.
- El UUID no es una contraseña, pero su exposición debe ser intencional.
- La búsqueda por UUID requiere sesión autenticada.
- La consulta devuelve solo campos públicos mínimos.
- Correo y `general_availability` se excluyen tanto del resultado SQL como del
  modelo Dart usado por la búsqueda.
- Solo los dos usuarios involucrados pueden leer una solicitud o amistad.
- El solicitante crea o cancela su solicitud pendiente.
- Solo el destinatario acepta o rechaza.
- Cualquiera de los dos puede terminar una amistad aceptada.
- No habilitar una política que permita listar indiscriminadamente todos los
  perfiles.
- No exponer `auth.users`, correos ni metadatos privados desde Flutter.
- Los participantes relacionados pueden consultar nombres mínimos necesarios
  para coordinar.
- Solo organizadores editan el partido.
- Solo organizadores y aceptados leen o crean mensajes.
- No usar `service_role` en la aplicación.

---

## 12. Pantallas mínimas

1. Inicio de sesión con envío mediante Enter.
2. Registro.
3. Onboarding obligatorio del perfil.
4. Perfil deportivo con UUID copiable.
5. Búsqueda exacta de usuario por UUID.
6. Solicitudes de amistad recibidas y enviadas.
7. Lista de amigos.
8. Exploración de deportes mediante widgets con emoji.
9. Resultados filtrados por deporte con transición Hero.
10. Lista y filtros de partidos.
11. Crear partido.
12. Editar partido.
13. Detalle con cupos y participantes autorizados.
14. Gestión de solicitudes de participación.
15. Mis participaciones activas.
16. Avisos internos.
17. Chat del partido.

No diseñar pantallas de equipos, resultados ni historial.

---

## 13. Criterios de aceptación

1. Registro e inicio/cierre de sesión funcionales.
2. Presionar Enter en contraseña ejecuta el login una sola vez.
3. Un perfil incompleto es redirigido al onboarding.
4. El onboarding guarda nombre, comuna, deportes, niveles y disponibilidad.
5. El perfil muestra y copia el UUID propio.
6. Un usuario autenticado busca otro mediante UUID exacto.
7. La búsqueda no expone correo ni permite listar usuarios.
8. Se puede enviar, aceptar, rechazar y cancelar una solicitud de amistad.
9. Una amistad aceptada aparece para ambos usuarios y puede eliminarse.
10. RLS impide consultar o modificar amistades ajenas.
11. Los deportes aparecen como widgets con emoji.
12. Seleccionar un deporte ejecuta una transición Hero y filtra partidos.
13. Se puede crear y encontrar un partido.
14. Los filtros incluyen deporte, fecha, comuna, nivel y cupos.
15. Se puede solicitar, aceptar, rechazar y confirmar asistencia.
16. La edición de fecha/hora/lugar genera un aviso.
17. Chat restringido a organizadores y aceptados.
18. RLS rechaza accesos no autorizados.
19. No existen flujos visibles de equipos, resultados ni historial.
20. `flutter analyze` y `flutter test` finalizan correctamente.

---

## 14. Orden de implementación

Seguir el detalle de `planificación.md`:

1. estabilizar análisis y pruebas;
2. onboarding completo;
3. login con Enter;
4. UUID propio, búsqueda segura y amistades;
5. catálogo visual de deportes y Hero;
6. filtros y edición de partidos;
7. participantes y coorganizadores;
8. avisos;
9. chat;
10. revisión integral de RLS y pruebas.

---

## 15. Reglas para agentes

1. Leer `AGENTS.md` y `planificación.md`.
2. No implementar equipos, rival, resultados, recomendaciones ni historial.
3. No confundir una columna existente con una funcionalidad requerida.
4. Agregar migraciones incrementales; no reescribir migraciones aplicadas.
5. Preservar cambios ajenos del árbol de trabajo.
6. Mantener UI, dominio, repositorios, SQL, RLS y pruebas alineados.
7. Probar flujos con al menos dos cuentas.
8. No exponer secretos ni datos de `auth.users`.
9. Aplicar accesibilidad y navegación por teclado en Flutter Web.
10. Documentar cambios de alcance.

---

## 16. Definición de terminado

Una funcionalidad está terminada cuando:

- tiene interfaz usable;
- tiene dominio y repositorios falsos/Supabase;
- persiste correctamente cuando corresponde;
- respeta RLS y privacidad;
- valida carga, vacío, error y entradas;
- tiene pruebas;
- funciona en el flujo completo;
- no introduce capacidades fuera del alcance actual.

---

## 17. Handoff

La primera prioridad es completar el registro/onboarding y estabilizar el
perfil. Después se implementan el login con Enter, el UUID copiable, la
búsqueda exacta, las solicitudes de amistad y la exploración visual por
deportes.

Equipos, búsqueda de rival, resultados, recomendaciones e historial quedan en
un backlog posterior y no deben bloquear este MVP.
