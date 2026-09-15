# ARGOS — Plan UX/UI

> Documento de diseño de producto para la app móvil (Flutter) y el portal web (Angular).
> Describe el sistema visual, los patrones de interacción, la navegación por rol, los
> flujos críticos y cada pantalla con su estructura, interacciones, estados y datos.
> Se lee junto con el [PRD](../ARGOS%20PRD.md) y los planes por fase. La fuente de verdad
> de los tokens sigue siendo `APP/packages/design_system/lib/tokens` y
> `WEB/src/app/shared/tokens/argos-tokens.css`; este documento los extiende y dice cómo
> usarlos.

---

## 0. Cómo usar este documento

* Antes de construir una pantalla, buscar su ficha en las secciones 6 (app) o 7 (web).
  La ficha dice qué roles la ven, qué muestra, qué hace cada control, qué estados tiene y
  de qué endpoints se alimenta.
* Todo componente nuevo se agrega primero al inventario de la sección 3.6 y al paquete
  de design system correspondiente; las pantallas solo componen.
* Cada ficha termina en la lista de verificación de la sección 9 antes de darse por
  hecha.
* La sección 10 mapea cada pantalla a la fase que la construye.

---

## 1. Principios de experiencia

ARGOS tiene tres tipos de usuario con contextos muy distintos. Los principios se derivan
de ellos.

| Usuario | Contexto real | Consecuencia de diseño |
| --- | --- | --- |
| Personal de campo (limpieza, mantenimiento, seguridad) | Teléfono de gama media, a veces con guantes o manos mojadas, sol directo, señal intermitente, poca atención disponible, uso diario y repetitivo | Objetivos táctiles grandes (mínimo 48 dp), alto contraste, un solo botón principal por pantalla, texto de cuerpo 16 px, todo lo frecuente a un toque desde "Hoy", funcionamiento sin conexión para leer y fotografiar, cero configuración |
| Administradores y supervisores | Escritorio o laptop, sesiones largas, muchas propiedades y personas, necesitan comparar y decidir | Densidad media, tablas con filtros persistentes, calendario como vista central, panel de detalle lateral sin perder contexto, atajos de teclado en tablas, exportación |
| Huéspedes y propietarios | Uso ocasional, sin entrenamiento, sin contraseña (huésped), expectativa de "app de hotel" | Lenguaje sin jerga, una sola pantalla principal con todo lo relevante, confirmaciones claras por correo y en pantalla, nada de menús profundos |

Principios que aplican a todo:

1. **Una acción principal por pantalla.** El botón dorado aparece una sola vez; todo lo
   demás es secundario (teal) o terciario (texto).
2. **El estado siempre es visible.** Toda tarea, ticket, reserva o período muestra su
   estado con color, icono y texto; nunca solo color.
3. **Nada se pierde.** Formularios largos guardan borrador local; fotos y checkpoints se
   encolan si no hay red; cerrar una hoja con cambios pide confirmación.
4. **Lo que no puedes hacer, no aparece.** La interfaz se construye desde los permisos y
   banderas del tenant. No hay botones deshabilitados "por falta de permiso"; el
   elemento no existe. La excepción es una acción bloqueada por estado (ej. cerrar tarea
   sin fotos), que se muestra deshabilitada con el motivo al lado.
5. **Feedback inmediato.** Todo toque responde en menos de 100 ms (ripple o cambio de
   opacidad); operaciones de más de 300 ms muestran esqueleto o spinner en el botón;
   acciones completadas confirman con toast o marca de verificación.
6. **Español directo.** Tuteo, verbos en infinitivo en botones ("Iniciar limpieza",
   "Registrar depósito"), mensajes de error que dicen la causa y la salida.
7. **Fechas y montos locales.** Zona horaria y moneda del tenant; "Hoy", "Mañana" y
   "Lunes 16" antes que fechas numéricas; cifras tabulares en tablas.

---

## 2. Sistema visual

### 2.1 Identidad

Teal profundo como base de marca (autoridad, calma) y dorado como acento de acción.
Neutros cálidos arena en fondos para que las fotos y los estados destaquen. Serif
(EB Garamond) reservada para títulos, saludos y números protagonistas; sans (Verdana en
app, Verdana/Geneva en web) para todo lo operativo. La combinación da un aire de
hospitalidad sin perder legibilidad en campo.

### 2.2 Color

Tokens existentes (no cambian):

| Token | Valor | Uso |
| --- | --- | --- |
| `primary` | #003841 | Fondos de marca, títulos, navegación activa, botón secundario |
| `secondary` | #C5873C | Botón primario, métricas destacadas, indicador de tab activo, acento de tarjeta en progreso |
| `tealMuted` | #3A6168 | Iconos secundarios, texto sobre teal lavado |
| `tealWashed` | #E6EEEC | Fondo de mapa, chip informativo |
| `success` | #5A8A6B | Operativo, completado, en vivo |
| `error` | #892F26 | Error, crítico, incidencia |
| `canvas` #E7E4DD · `background` #F4F1EA · `surfaceSoft` #FBFAF6 · `surface` #FFFFFF | | Capas de fondo, de más profunda a más elevada |
| `textPrimary` #003841 · `textBody` #5A5A52 · `textSecondary` #7D7D72 · `textMuted` #9A9A90 | | Jerarquía de texto |
| `borderField` #E2DED3 · `border` #EDE9DE · `divider` #F0ECE2 · `track` #EFEBE0 | | Bordes y pistas |
| `disabled` | #B0B0A6 | Deshabilitado |

Tokens nuevos que se agregan a ambos design systems (mismos valores):

| Token | Valor | Uso |
| --- | --- | --- |
| `warning` | #9A6722 | Texto y borde de advertencia (retraso, vencido, pendiente de acuse) |
| `warningSoft` | #F6E7D2 | Fondo de insignia de advertencia |
| `successSoft` | #E3EEE6 | Fondo de insignia de éxito |
| `errorSoft` | #F3E1DE | Fondo de insignia de error |
| `infoSoft` | #E6EEEC | Fondo de insignia informativa (= tealWashed) |
| `neutralSoft` | #EFEBE0 | Fondo de insignia neutra (= track) |
| `overlay` | rgba(0,56,65,0.55) | Scrim de modales y hojas |
| `offline` | #5A5A52 | Barra de estado sin conexión |

Semántica de estados (color de insignia + icono + texto, siempre los tres):

| Dominio | Estado | Insignia |
| --- | --- | --- |
| Tarea | pendiente | neutralSoft / textBody / reloj |
| | en progreso | infoSoft / primary / play |
| | finalizada | successSoft / success / check |
| | validada | successSoft / primary / check doble |
| | retrasada | warningSoft / warning / alerta |
| | cancelada | neutralSoft / textMuted / x |
| Incidencia | abierta | warningSoft / warning |
| | asignada / en progreso | infoSoft / primary |
| | resuelta / cerrada | successSoft / success |
| Urgencia | baja · media | neutralSoft · infoSoft |
| | alta · crítica | warningSoft · errorSoft |
| Reserva | pendiente | warningSoft |
| | confirmada | infoSoft |
| | con check-in | successSoft |
| | con check-out | neutralSoft |
| | cancelada / no-show | errorSoft |
| Depósito | pendiente · recibido · devuelto · retenido | warningSoft · infoSoft · successSoft · errorSoft |
| Activo | operativo · requiere atención · en reparación · fuera de servicio | successSoft · warningSoft · infoSoft · errorSoft |
| Nómina | borrador · en revisión · cerrada | neutralSoft · warningSoft · successSoft |

Contraste: todo texto sobre `background` o `surface` usa `textBody` o más oscuro
(mínimo 4.5:1). `textMuted` solo en etiquetas de 11 px en mayúsculas y nunca para
información necesaria. Texto sobre `primary`: blanco o blanco al 70 %; nunca al 45 % para
información necesaria (el mock de inicio web usa 45 % para texto decorativo; se sube a 60 %).

Modo oscuro: **no en esta versión**. Los tokens son semánticos para poder añadirlo
después; ninguna pantalla usa valores crudos.

### 2.3 Tipografía

Escala (existente, con dos adiciones):

| Estilo | Fuente | Tamaño / peso | Uso |
| --- | --- | --- | --- |
| display | Garamond 600 | 46 / 1.0 | Login, números héroe |
| pageTitle | Garamond 600 | 30 / 1.1 | Título de página y saludo |
| sectionTitle **(nuevo)** | Garamond 600 | 22 / 1.2 | Título de sección en web y cabeceras de hoja en app |
| cardTitle | Garamond 600 | 17 | Título de tarjeta |
| body | Verdana 400 | 16 / 1.5 en app · 14 / 1.6 en web | Cuerpo |
| bodySmall **(nuevo)** | Verdana 400 | 13 / 1.5 | Metadatos en tarjetas y tablas |
| data | Verdana 700 | 13, cifras tabulares | Valores en tablas |
| label | Verdana 400 | 11, +1 px, mayúsculas | Etiquetas de campo y chips |
| button | Verdana 700 | 14 | Botones |
| mono **(nuevo)** | ui-monospace | 14 | Códigos de reserva, placas, SKU, TOTP |

En app el cuerpo sube a 16 px (el actual 14 es pequeño para campo). Todos los estilos
respetan el escalado del sistema hasta 1.3×; las tarjetas crecen en alto, nunca truncan.

### 2.4 Geometría, elevación, iconos, movimiento

* Espaciado en múltiplos de 4: 4, 8, 12, 16, 24, 32, 48. Gutter horizontal 16 en
  teléfono, 24 en tablet, 28 en web.
* Radios: campo 12, tarjeta 18, hero 20, píldora 9999. Hojas inferiores en app: 24
  arriba.
* Elevación: `card` (0 8 20 rgba(0,56,65,.10)) para tarjetas flotantes; `cta` para el
  botón dorado; hojas y modales usan `card` más el scrim `overlay`. Nada más.
* Iconos: Material Symbols Rounded, un solo peso (400), tamaños 18 / 24 / 32. En web,
  `app-icon` mapea los mismos nombres a SVG de Material Symbols para que ambas
  plataformas compartan catálogo. Nunca emoji.
* Ilustraciones de estados vacíos: trazo teal sobre `tealWashed`, máximo 120 px, un
  set de ocho (sin tareas, sin conexión, sin resultados, sin permisos, sin
  notificaciones, sin reservas, inventario vacío, todo al día).
* Movimiento: `fast` 150 ms (estados de botón), `base` 250 ms (aparición de tarjetas,
  cambio de tab, expandir), `slow` 400 ms (hojas y modales). Entrada ease-out, salida
  ease-in y un 30 % más corta. Listas escalonan 30 ms por elemento (máximo 8). Se
  respeta "reducir movimiento" del sistema: todo pasa a fundido de 100 ms.
* Fotos: miniaturas cuadradas 72 px con radio 12; visor a pantalla completa con
  pellizco para ampliar y comparación "antes / después" deslizable.

### 2.5 Densidad y retícula

* App: una columna, ancho mínimo probado 360 px, alto mínimo 640. Barra inferior de
  navegación de 64 dp más safe area. Botón principal fijo al pie cuando la pantalla
  es un formulario o una ejecución.
* Web: sidebar 260 px (colapsable a 72 con solo iconos), topbar 64 px, contenido
  máximo 1280 px centrado. Breakpoints 768 (tablet: sidebar colapsado, tablas con
  columnas prioritarias) y 1024 (escritorio). Por debajo de 768 el portal sigue
  operable para admin en teléfono con menú hamburguesa; no se diseña para huésped.
* Tablas web: fila de 48 px, cabecera fija, columnas ordenables con indicador,
  selección múltiple opcional, acciones de fila en menú "más" al final.

### 2.6 Inventario de componentes

Regla de capas: tokens → átomos → moléculas → organismos → plantillas → pantallas.
Marcado con (E) lo que ya existe, (N) lo nuevo, y la fase en que se necesita.

**App (`packages/design_system`)**

| Capa | Componente | Fase |
| --- | --- | --- |
| Átomos | PrimaryButton (E), SecondaryButton (E), TertiaryButton (E), DangerButton (N, 2), IconButton (N, 1, 48 dp), AppTextField (E), PinField (N, 1), OtpField (N, 1), AppChip (E), StatusBadge (E, ampliar variantes), SummaryChip (E), ProgressBar (E), Avatar (N, 1), Skeleton (N, 1), Toggle (N, 1), Stepper numérico (N, 2, para cantidades), Checkbox grande (N, 2, 32 dp), PhotoThumb (N, 2), OfflineBar (N, 1) | |
| Moléculas | LabeledField (E), SectionHeader (E), AppCard (E), TaskCard (E, añadir variante retrasada y de mantenimiento), WeekStrip (E), ItineraryHeader (E), ListTile (N, 1), EmptyState (N, 1), ErrorState (N, 1), ConfirmSheet (N, 1), SearchField (N, 2), FilterChips (N, 2), ChecklistItemRow (N, 2, casilla + texto + miniaturas + cámara), PhotoGrid (N, 2), BeforeAfterPair (N, 2), QuantityRow (N, 2, artículo + custodia + devuelto + consumido), TimelineItem (N, 2), NotificationTile (N, 3), UrgencySelector (N, 3), ReservationCard (N, 4), GuestTile (N, 4), AlarmCard (N, 4), SlotPicker (N, 4), ClockButton (N, 5, botón circular de marcaje), MetricTile (N, 5), MessageBubble (N, 6) | |
| Organismos | LoginForm (E), LoginPanel (E), TenantPicker (N, 1), BiometricPrompt (N, 1), TaskExecutionHeader (N, 2), ChecklistSection (N, 2), CustodyReconciliation (N, 2), IncidentForm (N, 3), GuestRegistrationForm (N, 4), DocumentCapture (N, 4, cámara con guía), InspectionForm (N, 4), SecurityDashboardHeader (N, 4), AvailabilityCalendar (N, 4), PayslipViewer (N, 5), ChatComposer (N, 6) | |
| Plantillas | ArgosScaffold (E), TabScaffold (N, 1, barra inferior + safe areas), FormScaffold (N, 1, scroll + botón fijo al pie), DetailScaffold (N, 2, cabecera colapsable con estado), SheetScaffold (N, 1) | |

**Web (`shared/`)**

| Capa | Componente | Fase |
| --- | --- | --- |
| Átomos | button (E: primary, secondary, tertiary, danger, icon), input (E), select (N, 1), textarea (N, 1), checkbox / radio / toggle (N, 1), badge (E, variantes de estado), avatar (E), icon (E), logo (E), skeleton (N, 1), tooltip (N, 1), kbd (N, 2) | |
| Moléculas | form-field (E), search-bar (E), live-pill (E), card (E), stat-tile (N, 1), filter-bar (N, 2, chips + fecha + búsqueda con estado en URL), date-range-picker (N, 2), pagination-cursor (N, 2), empty-state (N, 1), toast (N, 1), confirm-dialog (N, 1), dropdown-menu (N, 1), tabs (N, 1), timeline (N, 2), photo-gallery (N, 2), before-after (N, 2), permission-matrix-cell (N, 1), status-select (N, 2), file-uploader (N, 2, arrastrar, progreso, validación), user-picker (N, 2, buscador de colaboradores con avatar) | |
| Organismos | sidebar (E, construido desde permisos), topbar (E, campana + selector de empresa + perfil), data-table (N, 1, ordenable, columnas prioritarias, selección, acciones), detail-drawer (N, 2, panel lateral 480 px con pestañas), week-calendar (N, 2, arrastrar y soltar), occupancy-calendar (N, 4, propiedades × días), kanban-board (N, 3), permission-matrix (N, 1), checklist-editor (N, 2, secciones e ítems reordenables), payroll-grid (N, 5, tabla editable con totales), chat-panel (N, 6), alert-panel (N, 3), notification-tray (N, 3) | |
| Plantillas | auth-layout (E), main-layout (E), list-page (N, 1: título + filtros + tabla + drawer), detail-page (N, 2: cabecera + pestañas), settings-page (N, 1: navegación secundaria izquierda) | |

---

## 3. Patrones transversales

### 3.1 Estados de pantalla

Toda pantalla o sección de datos implementa los seis estados, en este orden de
prioridad:

| Estado | App | Web |
| --- | --- | --- |
| Cargando | Esqueleto con la silueta de las tarjetas (nunca spinner central) a partir de 300 ms | Esqueleto de filas de tabla o de tarjetas |
| Vacío | Ilustración + título + una frase + acción si el rol puede crear ("Sin tareas hoy. Disfruta el descanso." / "Aún no hay propiedades. Crea la primera.") | Igual, centrado en el área de contenido |
| Error | Tarjeta con causa y botón "Reintentar"; si es 401 se cierra sesión; si es 402 (tenant suspendido) pantalla completa de solo lectura | Igual, más el id de la petición para soporte |
| Sin conexión | Barra gris fija bajo la topbar "Sin conexión · mostrando datos guardados hace 12 min"; acciones que requieren red se deshabilitan con nota | Banner; el portal no funciona sin conexión salvo lo ya cargado |
| Sin permiso | No se llega; si se llega por deep link: "No tienes acceso a esto" con botón a inicio | Redirección a inicio con toast |
| Solo lectura | Chip "Solo lectura" en cabecera (owner, tenant suspendido); botones de escritura ausentes | Igual |

### 3.2 Listas, filtros y búsqueda

* Listas con paginación por cursor y carga al llegar al final (app) o botón "Cargar
  más" (web, además de scroll).
* Filtros como chips horizontales en app (estado, propiedad, fecha) y como barra en web.
  El estado del filtro se guarda en la URL (web) o en el provider de la pestaña (app)
  para que "volver" lo conserve.
* Búsqueda con retardo de 300 ms, mínimo 2 caracteres, resultados agrupados por tipo
  cuando es global (web: propiedades, colaboradores, reservas, huéspedes por nombre,
  placa o código).
* Deslizar en filas de app solo para acciones reversibles y con pista visible
  (icono revelado); nunca para eliminar.

### 3.3 Formularios

* Etiqueta siempre visible encima del campo; el placeholder solo es ejemplo.
* Validación al salir del campo; error en rojo debajo del campo con causa y solución.
  Al enviar con errores, foco en el primero y resumen arriba si hay más de tres.
* Campos obligatorios con asterisco; opcionales con "(opcional)" solo si son minoría.
* Teclado correcto por tipo (correo, teléfono, numérico, decimal para montos).
* Botón de envío con spinner interno y bloqueado durante la petición; éxito con toast
  de 3 s y navegación de regreso o al detalle creado.
* Formularios de más de un paso (registro de huésped, cierre de tarea, inspección)
  muestran indicador de paso, permiten volver y guardan borrador local.
* Cerrar una hoja con cambios pregunta "¿Descartar cambios?".

### 3.4 Captura de fotos

* Cámara integrada (no galería por defecto) con botón de 72 dp, flash, cambio de
  cámara, y miniatura de las últimas tomas. Galería permitida solo para incidencias y
  adjuntos administrativos.
* Compresión a 1600 px lado mayor, JPEG 80, marca de agua discreta con fecha, hora y
  código de propiedad en la esquina inferior.
* Cada foto muestra su estado de subida (en cola, subiendo con porcentaje, lista,
  error con reintento). El conteo "3/5 fotos requeridas" está en la sección.
* Documentos de identidad: guía de encuadre rectangular, detección de brillo, se piden
  frente y reverso por separado, vista previa con "Repetir" y "Usar esta foto".

### 3.5 Confirmaciones, toasts y destructivo

* Acciones destructivas (cancelar reserva, eliminar propiedad, suspender usuario,
  revocar sesión) siempre con diálogo que nombra el objeto y el efecto, botón rojo a la
  derecha, y cuando es posible con deshacer en toast de 6 s.
* Toasts en la parte inferior (app) o inferior derecha (web), 3 a 5 s, con una acción
  como máximo, sin robar foco, anunciados a lectores de pantalla.
* Confirmaciones de éxito grandes (pantalla completa con check animado 400 ms) solo en
  tres momentos: tarea cerrada, check-in completado, nómina cerrada.

### 3.6 Navegación y regreso

* App: barra inferior con 4 o 5 destinos por rol, etiqueta e icono; badge numérico en
  Alertas y Chat. Flujos de ejecución (tarea, check-in, inspección) abren a pantalla
  completa sobre la barra y vuelven al origen al terminar. El gesto de regreso del
  sistema nunca cancela un envío en curso.
* Web: sidebar como navegación primaria; secciones con subnavegación por pestañas en
  la página; migas de pan a partir del tercer nivel; el detalle se abre en drawer
  lateral desde tablas (mantiene lista y filtros) y en página completa desde enlaces
  directos.
* Deep links: `argos://task/{id}`, `argos://ticket/{id}`, `argos://reservation/{id}`,
  `argos://alarm/{id}`, `argos://chat/{id}`, `argos://invite?token=`,
  `argos://guest?token=`. Toda notificación push lleva uno. Web: toda entidad tiene
  URL propia.

### 3.7 Tiempo, moneda y texto

* "Hoy 09:30", "Mañana", "Lun 16 jun", "16 jun 2026" según distancia. Ventanas como
  "09:00 – 11:00". Duraciones "1 h 20 min".
* Montos "Q 1,250.00"; en tablas alineados a la derecha con cifras tabulares.
* Nombres de propiedad con su código entre paréntesis en listas ("Torre A 504 (TA-504)").
* Códigos y placas en `mono`, mayúsculas.

### 3.8 Accesibilidad

* Contraste 4.5:1 en texto, 3:1 en iconos y bordes de campo.
* Objetivos táctiles 48 dp con 8 dp de separación; iconos pequeños con área extendida.
* Etiquetas de accesibilidad en todos los botones de icono; orden de foco igual al visual;
  anillo de foco de 2 px dorado en web.
* Escalado de texto del sistema soportado; "reducir movimiento" respetado.
* Ningún significado solo por color; estados con icono y texto.

---

## 4. Arquitectura de navegación

### 4.1 App móvil: destinos por rol

| Rol | Barra inferior | Acceso desde "Más" o perfil |
| --- | --- | --- |
| cleaner | Hoy · Semana · Inventario · Alertas · Perfil | Asistencia, Incidencias, Chat, Mis métricas, Mis boletas, Disciplina, Sesiones |
| maintenance | Hoy · Tickets · Inventario · Alertas · Perfil | Igual que cleaner |
| supervisor | Hoy · Equipo · Reservas* · Alertas · Más | Inventario, Incidencias, Inspecciones, Chat, Métricas de equipo, Perfil |
| admin (en app) | Hoy · Equipo · Reservas* · Alertas · Más | Todo lo de supervisor, más aprobaciones rápidas |
| security | Seguridad · Alarmas · Áreas* · Alertas · Perfil | Incidencias, Asistencia, Chat |
| owner | Mis propiedades · Reportes · Perfil | Incidencias |
| guest | Mi reserva · Áreas* · Chat* · Ayuda | — |

\* Solo si la bandera del tenant está activa; si no, el destino no existe y la barra
tiene un elemento menos. La pestaña "Hoy" es la pantalla inicial de todo colaborador;
"Seguridad" la de security; "Mi reserva" la del huésped.

### 4.2 Portal web: sidebar por permisos

Orden fijo; cada entrada aparece solo si el rol tiene el permiso y la bandera está activa:

1. Inicio
2. Propiedades (`properties.read`) → Propiedades, Edificios, Plantillas de checklist
3. Colaboradores (`users.read`)
4. Itinerario (`tasks.read`) → Calendario, Tablero del día
5. Inventario (`inventory.read`) → Artículos, Existencias, Movimientos, Custodias, Discrepancias, Solicitudes
6. Mantenimiento (`maintenance.read`) → Incidencias, Activos, Preventivos, Proveedores, Indicadores
7. Reservas (`reservations.read`, bandera) → Calendario, Reservas, Huéspedes, Canales
8. Parqueos (`parking.read`, bandera)
9. Áreas comunes (`shared_areas.read`, bandera)
10. RRHH (`hr.*`) → Asistencia, Nómina, Disciplina
11. Métricas (`metrics.team` o `metrics.all`) → Tablero, Metas e incentivos
12. Alertas (`alerts.read`)
13. Chat (`chat.internal` o `chat.guest`)
14. Bitácora (`audit.read`)
15. Configuración (`tenant.settings`) → Empresa, Usuarios, Roles, Facturación
16. Plataforma (platform admin) → Tenants, Planes, Suscripciones, Bitácora

Topbar: selector de empresa (si hay varias membresías), búsqueda global, campana de
notificaciones, avatar con menú (perfil, sesiones, cerrar sesión).

---

## 5. Flujos críticos

Cada flujo lista los pasos y las pantallas (referencias a las fichas de 6 y 7).

### F1. Inicio de sesión rápido (colaborador)

1. Primer arranque → A2 Login (correo, contraseña). Si el backend responde 428 → A3
   TOTP.
2. Varias membresías → A4 Selección de empresa.
3. A5 Configurar inicio rápido: elegir biometría (si el dispositivo la tiene) o PIN de
   6 dígitos. Se puede omitir.
4. Arranques siguientes → A1 Splash → A6 Desbloqueo (biometría automática, PIN como
   alternativa) → B1 Hoy en menos de 2 s con datos en caché mientras refresca.
5. Si el refresh falla por revocación → A2 con mensaje "Tu sesión fue cerrada por un
   administrador".

### F2. Ejecución y cierre de una limpieza

1. B1 Hoy → tocar tarjeta → B3 Detalle (dirección, acceso, checklist previo, reserva).
2. "Iniciar limpieza" → pide ubicación → B4 Ejecución: secciones del checklist.
3. Por ítem: marcar casilla; si requiere foto, la fila muestra cámara y contador; antes
   y después como par.
4. B6 Insumos y daños: cantidades usadas, reportar incidencia sin salir.
5. "Cerrar limpieza" → B7 Conciliación: lista de custodia con devuelto y consumido;
   diferencias resaltadas en ámbar con nota opcional.
6. Validación local: fotos requeridas completas, ubicación obtenida, conciliación
   confirmada. Si falta algo, el botón muestra el motivo ("Faltan 2 fotos en Baño").
7. Envío → B8 Resumen con check animado, duración, fotos, discrepancias creadas →
   volver a Hoy con la tarjeta ya en "Finalizada".
8. Sin red en el paso 7: estado "Lista para cerrar", se cierra sola al reconectar;
   la tarjeta lo indica.

### F3. Reporte de incidencia (cualquier rol)

B12 Reportar: propiedad (preseleccionada si viene de tarea o reserva), activo
(lista), urgencia (4 chips con color), descripción, fotos → enviar → toast con número
de ticket → el admin la ve en W-G1 y en alertas.

### F4. Check-in de venta directa (supervisor/admin en app)

1. C5 Reservas de hoy → tocar → C6 Detalle de reserva → "Hacer check-in".
2. Paso 1 huéspedes: por cada persona, C7 Registro (nombre, correo, tipo y número de
   documento) → C8 Captura frente → reverso → vista previa.
3. Paso 2 depósito: monto por defecto del canal, método, referencia → "Registrar".
4. Paso 3 confirmar: resumen, hora real, "Confirmar check-in" → pantalla de éxito →
   correo al huésped con acceso a la app.

### F5. Alarma de check-out (seguridad)

Push "Check-out en 30 min · Torre A 504" → toca → D2 Alarma: reserva, huéspedes,
placas, parqueo, botón "Marcar atendida" con nota → vuelve a D1 Tablero con la alarma
tachada. Si no se atiende en 60 min, aparece en W-L Alertas del admin.

### F6. Reserva de área común (huésped)

F1 Mi reserva → "Áreas comunes" → F3 lista con disponibilidad de hoy → F4 día y
bloques (ocupados en gris, seleccionable en teal) → "Reservar 16:00 – 17:00" →
confirmación inmediata + correo → F5 Mis reservas con opción de cancelar hasta 1 h
antes.

### F7. Cierre de nómina (admin web)

W-J2 Períodos → "Nuevo período" → W-J3 Detalle en borrador → "Calcular" → tabla con
totales por colaborador; celdas editables en revisión; discrepancias de asistencia con
enlace → "Pasar a revisión" → ajustes → "Cerrar período" (diálogo que resume totales) →
descargas de Excel y boletas → cada colaborador ve B20.

### F8. Invitación de un colaborador

W-O2 Usuarios → "Invitar" (correo, rol, propiedades asignadas) → correo con enlace →
móvil: A8 Aceptar invitación (nombre, contraseña) → A5 inicio rápido → B1.

---

## 6. Pantallas de la app móvil

Formato de ficha: **Roles** · **Propósito** · **Estructura** (de arriba abajo) ·
**Interacciones** · **Estados** · **Datos**.

### A. Acceso y sesión

#### A1 · Splash / arranque
Roles: todos. Propósito: decidir a dónde ir en menos de 1 s. Estructura: logo centrado
sobre teal, indicador discreto. Interacciones: ninguna. Estados: con refresh → A6; sin
refresh → A2; sin red y con caché → B1 en modo sin conexión; sin red y sin caché → A10.
Datos: almacenamiento seguro y caché de sesión.

#### A2 · Iniciar sesión
Roles: todos los usuarios con contraseña. Estructura: panel de marca arriba (logo,
frase), tarjeta con correo, contraseña con mostrar/ocultar, "Olvidé mi contraseña",
botón dorado "Iniciar sesión", enlace "Soy huésped, tengo un código" → A9.
Interacciones: validación al salir del campo, envío con Enter, spinner en botón.
Estados: error de credenciales bajo el formulario ("Correo o contraseña incorrectos");
429 con tiempo de espera; 428 → A3; membresías múltiples → A4. Datos: `POST /auth/login`.

#### A3 · Código de verificación (TOTP)
Estructura: título, texto "Abre tu app de autenticación", OtpField de 6 dígitos con
avance automático, "Verificar". Estados: código incorrecto (campo en rojo, se limpia),
intentos agotados. Datos: `POST /auth/login` con `totp_code`.

#### A4 · Elegir empresa
Estructura: lista de tarjetas con logo, nombre y rol en cada empresa; la última usada
primero y marcada. Interacciones: tocar entra; "Recordar mi elección" (toggle) para
saltar esta pantalla. Datos: `POST /auth/select-tenant`.

#### A5 · Configurar inicio rápido
Estructura: ilustración, "Entra más rápido la próxima vez", opción biometría (si
disponible) con icono del sistema, opción PIN, "Ahora no". Interacciones: PIN se
define dos veces en PinField. Estados: biometría no inscrita en el dispositivo → solo PIN.

#### A6 · Desbloqueo
Estructura: logo, nombre del usuario y empresa, prompt biométrico automático, PinField
como alternativa, "Usar contraseña". Estados: 3 fallos de PIN → contraseña obligatoria;
refresh revocado → A2 con mensaje.

#### A7 · Recuperar contraseña
Estructura: correo, "Enviar enlace"; pantalla de confirmación "Revisa tu correo" con
reenviar a los 60 s. La página de restablecer es web (W-A4), se abre desde el correo.

#### A8 · Aceptar invitación
Se abre por deep link. Estructura: "Garrent te invitó como Colaborador de limpieza",
nombre completo, contraseña con medidor de fortaleza, "Crear mi cuenta". Estados: token
vencido con "Pedir nueva invitación". Datos: `POST /auth/invitations/accept`.

#### A9 · Acceso de huésped
Estructura: "Ingresa con tu código de reserva", campo de código (`mono`, mayúsculas
automáticas), correo, "Entrar". Deep link con token salta esta pantalla. Estados:
código vencido o reserva cancelada con mensaje y contacto de la empresa. Datos:
`POST /guest/auth`.

#### A10 · Sin conexión al iniciar
Estructura: ilustración, "Necesitas conexión para entrar la primera vez", "Reintentar".

### B. Colaborador (limpieza y mantenimiento)

#### B1 · Hoy
Roles: cleaner, maintenance, supervisor, admin. Propósito: ver de un vistazo qué hago
hoy y empezar con un toque. Estructura: ItineraryHeader (saludo, fecha, avatar, chips
"4 limpiezas · 1 en progreso · 1 retrasada"), OfflineBar si aplica, tarjeta de
asistencia compacta ("Marcar entrada" si no hay marcaje abierto; si lo hay, hora de
entrada y "Marcar salida"), lista de TaskCard ordenadas por ventana, la tarea en
progreso arriba y con acento dorado. Interacciones: tocar tarjeta → B3; deslizar para
refrescar; tocar chip filtra. Estados: vacío "Sin tareas hoy"; sin conexión muestra la
caché con marca de hora. Datos: `GET /tasks?date=hoy`, `GET /attendance/me`.

#### B2 · Semana
Estructura: WeekStrip con puntos por cantidad de tareas, lista del día seleccionado
igual a B1. Interacciones: deslizar la tira cambia de semana. Datos: `GET /tasks?from&to`.

#### B3 · Detalle de tarea
Estructura: DetailScaffold con cabecera (propiedad, código, estado, ventana), bloque
de dirección con "Cómo llegar" (abre mapas), bloque de acceso (solo si tiene permiso y
la tarea es de hoy; botón "Ver códigos" que revela por 30 s), bloque de reserva
asociada (check-out a las 11:00, 2 huéspedes), notas del admin, vista previa del
checklist (secciones y conteo), línea de tiempo. Botón fijo "Iniciar limpieza" (o
"Continuar"). Interacciones: para supervisor, menú "más": reasignar, reprogramar,
cancelar. Estados: retrasada muestra banda ámbar con "Debió iniciar a las 09:00";
cancelada sin botón. Datos: `GET /tasks/{id}`, `/access-info`, `/events`.

#### B4 · Ejecución: checklist
Estructura: TaskExecutionHeader fijo (propiedad, cronómetro desde inicio, progreso
"7/18", botón "Cerrar limpieza"), secciones colapsables (Habitación 1, Baño…) con
ChecklistItemRow: casilla de 32 dp, texto, chip "Foto requerida", miniaturas y botón
cámara. Interacciones: marcar ítem guarda al instante (local y remoto); tocar cámara
→ B5; tocar miniatura → visor con eliminar; mantener presionado el título de sección
la marca completa; barra de progreso por sección. Estados: ítems con foto pendiente en
ámbar; subida en curso con anillo de progreso en miniatura. Datos:
`PATCH /tasks/{id}/checklist/{item}`, `POST /files/presign-upload`.

#### B5 · Cámara
Ver 3.4. Modo "antes / después" muestra la foto "antes" como referencia semitransparente
al tomar la "después".

#### B6 · Insumos y daños
Estructura: lista de artículos consumibles en custodia con Stepper de cantidad usada;
sección "¿Encontraste algún daño?" con "Reportar incidencia" → B12 en hoja. Datos:
`POST /tasks/{id}/consumptions`.

#### B7 · Cierre: conciliación de custodia
Estructura: título "Antes de cerrar", checklist de requisitos con check o cruz (fotos
requeridas, ubicación, custodia), lista QuantityRow por artículo (custodia 5 · devuelvo
[5] · consumí [0]); las filas con diferencia se resaltan en ámbar y piden nota opcional;
resumen "2 diferencias se registrarán"; botón "Confirmar y cerrar". Interacciones:
Stepper y teclado numérico; "Devolver todo" rellena. Estados: requisito faltante
deshabilita el botón y muestra el motivo debajo; sin red → "Guardar para cerrar al
reconectar". Datos: `GET /inventory/custody/me`, `POST /tasks/{id}/complete`.

#### B8 · Limpieza cerrada
Pantalla completa: check animado, "Torre A 504 · 1 h 20 min · 14 fotos", discrepancias
creadas si las hay, "Volver a Hoy". Se cierra sola en 4 s si no se toca.

#### B9 · Inventario: mi custodia
Estructura: chips de categoría (Todo, Consumibles, Herramientas, Llaves), lista con
artículo, cantidad en custodia, desde cuándo; botones "Sacar artículos" (→ B10) y
"Solicitar reposición" (→ B11); sección "Diferencias abiertas" con estado. Datos:
`GET /inventory/custody/me`, `GET /inventory/discrepancies?user=me`.

#### B10 · Sacar artículos
Estructura: selector de bodega (central o propiedad), buscador, escáner de código
(opcional), lista con Stepper por artículo y existencia disponible, resumen inferior,
"Confirmar salida". Datos: `POST /inventory/movements` tipo `checkout_to_employee`.

#### B11 · Solicitar reposición
Hoja: artículo, bodega, cantidad, nota, "Enviar". Toast de confirmación.

#### B12 · Reportar incidencia
Estructura: propiedad (preseleccionada o selector dentro de mi alcance), activo
(lista agrupada por categoría, "Otro"), UrgencySelector (baja, media, alta, crítica con
color y descripción corta), título, descripción, fotos (cámara o galería), "Enviar
reporte". Datos: `POST /tickets`.

#### B13 · Mis tickets (mantenimiento)
Estructura: chips de estado, lista de tarjetas (propiedad, activo, urgencia, tiempo
abierto), ordenadas por urgencia y antigüedad. Datos: `GET /tickets?assigned=me`.

#### B14 · Detalle de ticket / resolver
Estructura: cabecera con estado y urgencia, descripción y fotos del reporte, activo y
su historial reciente, línea de tiempo, botón "Iniciar" → "Resolver" (hoja: qué se
hizo, costo opcional, fotos). Datos: `POST /tickets/{id}/start`, `/resolve`.

#### B15 · Asistencia
Estructura: ClockButton central (entrada verde / salida teal) con hora actual, estado
"Entraste a las 07:58", mapa pequeño con tu ubicación, historial del mes en lista
(fecha, entrada, salida, horas). Interacciones: tocar botón pide ubicación y foto
opcional; confirmación en toast. Estados: sin permiso de ubicación → explicación y
acceso a ajustes. Datos: `POST /attendance/clock-in|out`, `GET /attendance/me`.

#### B16 · Notificaciones / Alertas
Estructura: pestañas "Nuevas" y "Todas", NotificationTile (icono por tipo, título,
cuerpo, hora relativa, punto si no leída), "Marcar todas". Interacciones: tocar navega
por deep link; deslizar marca leída. Datos: `GET /notifications`.

#### B17 · Perfil
Estructura: avatar, nombre, rol y empresa, "Cambiar de empresa" (si aplica), lista:
Mis métricas, Mis boletas, Disciplina, Asistencia, Chat, Sesiones activas, Inicio
rápido (biometría / PIN), Verificación en dos pasos, Cambiar contraseña,
Notificaciones (preferencias), Acerca de, Cerrar sesión (rojo, separado).

#### B18 · Sesiones activas
Lista de dispositivos con nombre, plataforma, último uso, "Este dispositivo"; "Cerrar
sesión en este" por fila y "Cerrar en todos los demás".

#### B19 · Mis métricas
Estructura: selector de período (semana, mes), MetricTile ×4 (limpiezas, tiempo
promedio, cumplimiento, retrasos), gráfico de barras semanal, metas activas con
progreso, incentivos ganados. Datos: `GET /metrics/me`.

#### B20 · Mis boletas
Lista por período con neto; tocar abre PayslipViewer (PDF) con compartir. Datos:
`GET /payroll/me`.

#### B21 · Disciplina
Lista de acciones con tipo, fecha, estado de acuse; detalle con descripción, adjuntos y
botón "Confirmo que la recibí" (con nota opcional). Datos: `GET /disciplinary/me`,
`POST .../acknowledge`.

#### B22 · Chat: conversaciones
Lista con avatar o grupo, último mensaje, hora, no leídos; botón "Nueva". Búsqueda.
Datos: `GET /chat/conversations`.

#### B23 · Conversación
Burbujas (propias en teal, ajenas en surface), separadores de día, ChatComposer (texto,
cámara, adjuntar), estado de envío por mensaje. Datos: `GET/POST .../messages`, WS.

### C. Supervisor y admin en app

#### C1 · Equipo hoy
Estructura: resumen (colaboradores activos, tareas por estado), lista por colaborador
con avatar, estado de marcaje, tareas del día como chips de estado; tocar abre su
lista; filtro por propiedad. Datos: `GET /tasks?date`, `GET /attendance?date`.

#### C2 · Reasignar / reprogramar
Hoja: user-picker con disponibilidad (verde libre, ámbar ocupado), fecha y ventana,
motivo, "Confirmar". Datos: `POST /tasks/{id}/assign`, `/reschedule`.

#### C3 · Validar tarea
Estructura: cabecera de tarea, PhotoGrid por sección con BeforeAfterPair, checklist
en solo lectura, consumos, discrepancias, notas del colaborador; botones "Validar" y
"Devolver" (con motivo obligatorio). Datos: `POST /tasks/{id}/validate`, `/reopen`.

#### C4 · Alertas (supervisor)
Igual a B16 más sección "Panel" con contadores por tipo y acciones "Reconocer".

#### C5 · Reservas de hoy
Estructura: pestañas Llegadas / Salidas / Activas, ReservationCard (propiedad, huésped,
hora, canal, estado de depósito, chips "2 adultos", "Parqueo P-12"). Datos:
`GET /reservations?from=hoy&to=hoy`.

#### C6 · Detalle de reserva
Estructura: cabecera con estado, fechas y código en `mono`; bloques: huéspedes (con
estado de registro), depósito, parqueo, áreas reservadas, inspecciones, línea de tiempo;
botón principal según estado ("Hacer check-in", "Hacer check-out", "Registrar
inspección"). Datos: `GET /reservations/{id}`.

#### C7 · Registro de huésped
Formulario en hoja: nombre, correo, teléfono, tipo de documento (segmentado DPI /
Pasaporte), número (`mono`), nacionalidad (solo pasaporte); "Fotografiar documento" →
C8. Reutiliza huésped existente por número (chip "Ya registrado el 3 mar"). Datos:
`POST /reservations/{id}/guests`, `GET /guests?document=`.

#### C8 · Captura de documento
Ver 3.4. Dos pasos (frente, reverso) con progreso y vista previa.

#### C9 · Depósito
Hoja: monto (con valor por defecto), método (segmentado), referencia, nota, "Registrar
depósito"; en check-out: "Devolver" / "Retener" con monto y motivo. Datos:
`POST .../deposit/transactions`.

#### C10 · Inspección
Estructura: tipo (pre-llegada / post-salida) fijado por contexto, lista de áreas de la
plantilla con cámara y comparación contra la inspección anterior (BeforeAfterPair),
"Agregar hallazgo" (área, descripción, severidad, costo estimado, cobrar al depósito,
foto) → lista de hallazgos; "Guardar inspección". Datos: `POST /reservations/{id}/inspections`.

#### C11 · Más
Lista de accesos: Inventario, Incidencias, Inspecciones pendientes, Chat, Métricas de
equipo, Perfil.

### D. Seguridad

#### D1 · Tablero de seguridad
Estructura: SecurityDashboardHeader con fecha y contadores (llegadas, salidas,
activas, alarmas pendientes), búsqueda por nombre o placa, secciones: "Salidas hoy"
(hora, propiedad, huésped, placa, estado de alarma), "Llegadas hoy", "Huéspedes
activos" agrupados por edificio, "Áreas comunes hoy", "Parqueos ocupados". Todo en solo
lectura salvo alarmas. Datos: `GET /security/dashboard?date=hoy`.

#### D2 · Alarmas
Lista de AlarmCard ordenadas por hora (pendientes primero, atendidas tachadas), detalle
con reserva, huéspedes, placas, parqueo, notas del admin, botón "Marcar atendida" con
nota. Datos: `GET /security/alarms`, `POST .../attend`.

#### D3 · Detalle de huésped activo
Nombre, propiedad, fechas, acompañantes, placa y parqueo, áreas reservadas hoy; sin
documentos ni contacto. Datos: `GET /reservations/{id}` con alcance security.

### E. Propietario

#### E1 · Mis propiedades
Tarjetas por propiedad con estado de hoy (limpia, ocupada, con incidencia), próxima
reserva, incidencias abiertas. Datos: `GET /properties` con alcance owner.

#### E2 · Detalle de propiedad (owner)
Pestañas: Limpiezas (historial con fotos), Incidencias, Reservas (sin documentos),
Reportes (ocupación y limpiezas por mes). Botón "Reportar problema" → B12.

#### E3 · Reportes
Selector de mes, MetricTile (ocupación, limpiezas, incidencias, tiempo de resolución),
exportar PDF.

### F. Huésped

#### F1 · Mi reserva
Estructura: cabecera con nombre de la propiedad, fechas grandes ("Jue 18 → Dom 21"),
código; tarjeta "Llegada" con hora y estado; tarjeta "Instrucciones de acceso"
(publicadas por el admin; código de cerradura visible desde 24 h antes si aplica);
accesos: Áreas comunes, Mi parqueo, Chat con la empresa, Reportar un problema;
contacto de emergencia. Estados: antes del check-in, durante, después (solo lectura y
"Gracias por tu visita"). Datos: `GET /guest/reservation`.

#### F2 · Instrucciones de acceso
Texto enriquecido y fotos del admin (cómo llegar, wifi, normas), botón "Cómo llegar".

#### F3 · Áreas comunes
Lista con foto, nombre, horario, capacidad, "Disponible ahora" o próximo bloque libre.

#### F4 · Reservar área
Selector de día (dentro de la estancia), SlotPicker con bloques (libre, ocupado, mío),
regla "Máximo 1 por día", botón "Reservar 16:00 – 17:00". Confirmación con check y
correo. Datos: `GET /shared-areas/{id}/availability`, `POST .../bookings`.

#### F5 · Mis reservas de áreas
Lista con cancelar (hasta 1 h antes) y confirmación.

#### F6 · Mi parqueo
Espacio asignado en grande, placa registrada, indicaciones; si no tiene, "Pide un
espacio por chat".

#### F7 · Reportar un problema
Versión simplificada de B12: qué pasa (chips: limpieza, aire, agua, luz, ruido, otro),
descripción, fotos.

#### F8 · Chat con la empresa
B23 con una sola conversación; cabecera con nombre de la empresa y horario de atención.

#### F9 · Ayuda
Preguntas frecuentes del tenant, contacto, "Cerrar sesión de huésped".

---

## 7. Pantallas del portal web

### W-A. Acceso

#### W-A1 · Iniciar sesión
Auth-layout a dos columnas (panel de marca con frase y foto; formulario). Correo,
contraseña, "Recordarme en este equipo" (define 30 días), "Olvidé mi contraseña",
botón dorado. 428 → paso TOTP en el mismo panel. Varias membresías → W-A2.

#### W-A2 · Elegir empresa
Tarjetas con logo, nombre y rol; "Entrar como plataforma" para platform admin.

#### W-A3 · Olvidé mi contraseña · W-A4 · Restablecer · W-A5 · Aceptar invitación
Formularios simples en auth-layout con los mismos estados que la app.

### W-B. Inicio

#### W-B1 · Inicio (admin y supervisor)
Estructura: saludo y frase de contexto ("Esto es lo que pasa hoy en Garrent"),
live-pill de equipos en campo; hero teal con "Requiere tu atención" (contador de alertas
altas y lista de 3 con acción); fila de stat-tiles (limpiezas hoy hechas/total,
retrasadas, incidencias abiertas, llegadas y salidas hoy); columna izquierda: donut de
cumplimiento del día, ranking corto de colaboradores; columna derecha: mapa de
propiedades con pines por estado (limpia, en limpieza, ocupada, incidencia) y lista de
mantenimientos próximos. Cada bloque enlaza a su sección. Datos: `GET /dashboard`
(agregado del backend). Supervisor ve lo mismo sin métricas financieras.

#### W-B2 · Inicio (owner)
Tarjetas de sus propiedades con estado y últimas limpiezas, incidencias abiertas y
próximas reservas.

### W-C. Propiedades

#### W-C1 · Propiedades (lista)
list-page: filtros (edificio, estado, con incidencia), búsqueda, data-table (código,
nombre, edificio, asignados como avatares apilados, última limpieza, estado de hoy,
incidencias), acción "Nueva propiedad". Clic en fila → drawer con resumen y "Abrir
ficha".

#### W-C2 · Ficha de propiedad
detail-page: cabecera (nombre, código, edificio, estado, botones Editar y menú
Desactivar); pestañas: Datos (formulario), Acceso (información cifrada con "Mostrar",
bitácora de quién la vio), Checklist (elige plantilla o personaliza con
checklist-editor), Propietarios (user-picker), Asignados (user-picker múltiple),
Activos (lista con estado), Historial (línea de tiempo de limpiezas con galería,
incidencias, reservas, inspecciones).

#### W-C3 · Edificios
Lista y formulario simple; parqueos y áreas comunes del edificio como pestañas si las
banderas están activas.

#### W-C4 · Plantillas de checklist
Lista y checklist-editor: secciones arrastrables, ítems con texto, "requiere foto",
"antes y después"; vista previa como se ve en la app; "Duplicar".

### W-D. Colaboradores

#### W-D1 · Colaboradores (lista)
Tabla: nombre, rol, código, propiedades asignadas, estado (activo, invitado,
suspendido), último acceso; filtros por rol y estado; "Invitar". Drawer con acciones
rápidas (cambiar rol, suspender, reenviar invitación).

#### W-D2 · Ficha de colaborador
Pestañas: Perfil (datos de usuario y sesiones con revocar), Laboral (employees:
código, puesto, ingreso, documentos, IGSS, NIT, esquema de pago y tarifa, en planilla),
Horario (grilla semanal), Propiedades (asignadas), Métricas (B19 en grande),
Asistencia (mes), Disciplina (lista y "Nueva acción"), Nómina (entradas por período).

### W-E. Itinerario

#### W-E1 · Calendario semanal
week-calendar: filas por colaborador (o por propiedad, conmutador), columnas por día,
tareas como bloques con estado; arrastrar entre filas reasigna, entre columnas
reprograma (diálogo de confirmación con motivo); clic abre drawer de tarea; "Nueva
tarea" y "Generar desde reservas" (crea limpiezas de salida pendientes). Sin asignar
aparece en una fila "Sin asignar" arriba. Filtros: propiedad, edificio, tipo.

#### W-E2 · Tablero del día
Columnas por estado (pendiente, en progreso, finalizada, validada) con tarjetas;
retrasadas con banda ámbar; contador por columna; clic → drawer.

#### W-E3 · Drawer / ficha de tarea
Cabecera con estado, propiedad, asignado, ventana; pestañas: Resumen (checklist con
progreso, ubicación de inicio y fin en mapa, duración), Evidencias (photo-gallery por
sección con before-after), Consumos y discrepancias, Línea de tiempo; acciones:
Reasignar, Reprogramar, Validar, Devolver, Cancelar.

#### W-E4 · Nueva / editar tarea
Formulario en drawer: tipo, propiedad, fecha, ventana, asignado (user-picker con
disponibilidad), plantilla, prioridad, notas, reserva relacionada (buscador).

### W-F. Inventario

#### W-F1 · Artículos
Tabla (SKU, nombre, categoría, unidad, mínimo, existencia total con alerta), "Nuevo
artículo", importación CSV.
#### W-F2 · Existencias
Selector de bodega, tabla por artículo con cantidad y mínimo, "Registrar entrada",
"Traslado", "Ajuste" (motivo obligatorio).
#### W-F3 · Movimientos
Tabla cronológica con filtros (tipo, artículo, colaborador, tarea), exportar.
#### W-F4 · Custodias
Tabla colaborador × artículo con cantidades; drawer con historial y "Registrar
devolución".
#### W-F5 · Discrepancias
Tabla con estado, colaborador, artículo, esperado, devuelto, tarea; acciones
"Justificar" (nota) y "Cerrar".
#### W-F6 · Solicitudes de reposición
Lista con aprobar/rechazar y "Marcar surtida" (crea entrada).

### W-G. Mantenimiento

#### W-G1 · Incidencias
kanban-board por estado con tarjetas (urgencia, propiedad, activo, edad, asignado);
filtros; clic → drawer con descripción, fotos, línea de tiempo, asignar a colaborador
o proveedor, costo, cerrar. Vista de tabla alternativa.
#### W-G2 · Activos
Tabla por propiedad/edificio, categoría, estado, próximo preventivo, proveedor; ficha
con documentos (file-uploader), planes, historial de tickets y costos.
#### W-G3 · Preventivos
Calendario mensual de vencimientos y lista; "Nuevo plan".
#### W-G4 · Proveedores
Lista y ficha con activos y tickets atendidos.
#### W-G5 · Indicadores
Stat-tiles y gráficos: abiertas por propiedad (barras), tiempo promedio de resolución
(línea mensual), costo por categoría (barras horizontales).

### W-H. Reservas

#### W-H1 · Calendario de ocupación
occupancy-calendar: filas por propiedad, columnas por día, barras por reserva con
color de canal y estado; hover muestra huésped y depósito; clic → drawer; arrastrar
para crear reserva manual; "Sincronizar iCal ahora".
#### W-H2 · Reservas (lista)
Tabla con código, propiedad, huésped, canal, fechas, estado, depósito; filtros;
"Nueva reserva"; pendientes de completar (importadas) resaltadas.
#### W-H3 · Ficha de reserva
Cabecera (código, estado, propiedad, fechas, canal); pestañas: Huéspedes (registro,
documentos con "Ver documento" solo con permiso y registro en bitácora, fecha de borrado
automático), Depósito (transacciones, registrar), Inspecciones (galerías y hallazgos),
Parqueo, Áreas comunes, Alarmas, Chat, Línea de tiempo; acciones: Confirmar, Check-in,
Check-out, Cancelar, No-show, Reenviar correo al huésped.
#### W-H4 · Nueva reserva
Drawer: propiedad, canal (muestra si exige depósito y check-in), fechas (valida
solapamiento en vivo), huéspedes (buscar por documento o crear), adultos y niños,
monto, depósito, notas, "Enviar correo de confirmación" (toggle).
#### W-H5 · Huéspedes
Directorio con búsqueda por nombre, correo o documento; ficha con estancias, notas y
lista negra.
#### W-H6 · Canales e iCal
Lista de canales con reglas; por propiedad, URLs iCal con estado de última
sincronización y errores.

### W-I. Parqueos y áreas comunes

#### W-I1 · Parqueos
Configuración de espacios por edificio/propiedad; calendario de ocupación por espacio;
asignar a reserva con placa.
#### W-I2 · Áreas comunes
Configuración (nombre, capacidad, horario, bloque, máximo por día, anticipación,
reglas, foto); calendario de reservas del día y semana; reservar en nombre de un
huésped.

### W-J. RRHH

#### W-J1 · Asistencia
Tabla colaborador × día del mes con horas y marcas de alerta (sin salida, fuera de
horario); clic en celda abre marcajes con mapa y "Corregir" (motivo obligatorio);
"Registrar marcaje manual".
#### W-J2 · Nómina: períodos
Lista con estado y totales; "Nuevo período".
#### W-J3 · Nómina: detalle de período
payroll-grid: una fila por colaborador con columnas de días, horas, limpiezas, base,
extras, incentivos, Bono 14, aguinaldo, IGSS, otras deducciones, neto; celdas editables
en revisión con historial de cambio; totales fijos al pie; barra de estado con
"Calcular", "Pasar a revisión", "Cerrar período", "Descargar Excel", "Descargar
boletas". Panel lateral por colaborador con desglose y vista previa de boleta.
#### W-J4 · Disciplina
Lista de acciones con estado de acuse; "Nueva acción" (colaborador, tipo, fecha,
descripción, adjuntos, fechas de suspensión).
#### W-J5 · Configuración de nómina
Tasas, meses de Bono 14 y aguinaldo, días del mes, horas por día, minutos mínimos para
contar un día.

### W-K. Métricas

#### W-K1 · Tablero
Selector de período; stat-tiles; ranking de colaboradores (tabla con cumplimiento,
tiempo, retrasos); gráfico de limpiezas por día; por propiedad; exportar.
#### W-K2 · Metas e incentivos
Lista de metas con progreso del período; incentivos pendientes de aprobación con
aprobar/rechazar en lote.

### W-L. Alertas

#### W-L1 · Panel de alertas
alert-panel: tarjetas por tipo con contador y color de severidad; lista filtrable
(tipo, severidad, propiedad, estado); acciones Reconocer y Resolver; enlace a la
entidad.

### W-M. Chat

#### W-M1 · Chat
chat-panel a tres columnas: lista de conversaciones (pestañas Internas / Huéspedes, no
leídos, búsqueda), conversación, panel de contexto (en huéspedes: reserva, propiedad,
fechas, acciones rápidas). Respuestas rápidas configurables.

### W-N. Bitácora

#### W-N1 · Bitácora
Tabla cronológica con actor, acción, entidad, propiedad, IP; filtros y rango de fecha;
fila expandible con antes/después en JSON legible; exportar.

### W-O. Configuración

#### W-O1 · Empresa
Datos, logo (file-uploader), zona horaria, moneda, horas por defecto de check-in y
check-out, anticipación de alarma, plantilla de instrucciones al huésped, banderas de
funcionalidad (con candado si el plan no las incluye).
#### W-O2 · Usuarios y membresías
Tabla de miembros (rol, estado, último acceso), invitaciones pendientes (reenviar,
revocar), "Invitar" (correo, rol, propiedades, mensaje).
#### W-O3 · Roles y permisos
Lista de roles (sistema con candado, personalizados editables); permission-matrix:
filas por módulo y permiso con descripción, columnas por rol; casillas; permisos
mínimos de admin y guest bloqueados; "Guardar" muestra "Los usuarios con este rol verán
el cambio en su próxima acción".
#### W-O4 · Facturación
Plan actual y límites (uso vs máximo con barras), próxima factura, historial de
facturas con PDF, método de pago, cambiar plan, cancelar.

### W-P. Plataforma (platform admin)

#### W-P1 · Tenants
Tabla (nombre, slug, plan, estado, propiedades, usuarios, creado); "Nuevo tenant"
(nombre, slug con validación en vivo, admin inicial por correo, plan, prueba); acciones
activar/desactivar, reactivar suscripción; drawer con uso.
#### W-P2 · Planes
Lista y formulario de límites y funcionalidades.
#### W-P3 · Suscripciones
Tabla con estado, vencimientos, pagos fallidos.
#### W-P4 · Bitácora de plataforma
Igual a W-N1 con columna de tenant.

---

## 8. Notificaciones y correos

### 8.1 Push
Título corto con el objeto, cuerpo con el dato que importa y deep link. Ejemplos:
"Nueva tarea · Torre A 504" / "Hoy 09:00 – 11:00 · Limpieza de salida".
"Check-out en 30 min · Torre A 504" / "María Pérez · Placa P123ABC · Parqueo 12".
"Discrepancia de inventario" / "Juan devolvió 4 de 5 llaves en TA-504".
Canal de alta prioridad (sonido y pantalla) solo para alarmas de seguridad y
reasignaciones del día.

### 8.2 Correo
Plantilla única: cabecera teal con logo del tenant (o de ARGOS si no tiene), título en
Garamond, cuerpo en sans, un botón dorado, pie con datos de la empresa y motivo del
envío. Correos: invitación, restablecer contraseña, reserva confirmada (con código,
instrucciones y botón "Abrir en la app"), recordatorio de llegada, depósito recibido o
devuelto, reserva de área común, nómina disponible, acción disciplinaria, resumen
diario opcional para admin (alertas activas y tareas del día).

### 8.3 Bandeja en app y web
Agrupada por día, icono por tipo, no leídas con punto dorado, navegación al destino,
"marcar todas". Preferencias por tipo con push y correo como toggles; los críticos
aparecen fijos.

---

## 9. Lista de verificación por pantalla

Antes de dar por terminada una pantalla:

- [ ] Existe ficha en este documento y la pantalla la cumple (estructura, interacciones, estados, datos).
- [ ] Un solo botón primario visible.
- [ ] Estados de cargando (esqueleto), vacío, error y sin conexión implementados.
- [ ] Ningún valor de color, tamaño o fuente fuera de tokens.
- [ ] Objetivos táctiles ≥ 48 dp con 8 dp de separación; iconos con etiqueta de accesibilidad.
- [ ] Texto de cuerpo ≥ 16 px en app; contraste ≥ 4.5:1.
- [ ] Estados con icono + texto, no solo color.
- [ ] Formularios: etiquetas visibles, validación al salir del campo, error junto al campo, teclado correcto, spinner en el botón.
- [ ] Acción destructiva con confirmación y, si es posible, deshacer.
- [ ] Deep link funciona y "volver" conserva filtros y scroll.
- [ ] Probado a 360 px de ancho, con texto del sistema a 1.3× y con "reducir movimiento".
- [ ] La pantalla no muestra nada que el rol no pueda hacer; probado con al menos dos roles.
- [ ] Fechas y montos en zona y moneda del tenant.

---

## 10. Mapa pantallas ↔ fase

| Fase | App | Web |
| --- | --- | --- |
| 1 | A1–A10, B17, B18, shell por rol con pestañas vacías | W-A1–W-A5, main-layout con sidebar por permisos, W-O1 (parcial), W-O2, W-O3, W-P1, W-P4 |
| 2 | B1–B11, C1–C3, C11, E1–E2 (limpiezas), OfflineBar y cola de subida | W-B1 (parcial), W-C1–W-C4, W-D1–W-D2 (sin RRHH), W-E1–W-E4, W-F1–W-F6, W-N1 |
| 3 | B12–B14, B16, C4, F7 (contrato) | W-G1–W-G5, W-L1, notification-tray, W-B1 completo |
| 4 | A9, C5–C10, D1–D3, E2 (reservas), F1–F7, F9 | W-H1–W-H6, W-I1–W-I2, W-O1 (reservas y alarmas) |
| 5 | B15, B19–B21, C1 (asistencia), E3 | W-D2 (RRHH), W-J1–W-J5, W-K1–W-K2 |
| 6 | B22–B23, F8, código de cerradura en F1 | W-M1, W-O4, W-P2–W-P3 |
