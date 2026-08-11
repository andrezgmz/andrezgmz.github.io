# Radar en Vivo — guía de puesta en marcha (v3)

Herramienta tipo Kahoot/Menti para el diagnóstico rápido de radar digital al inicio de tu conferencia. Público responde desde el celular con un PIN, tú controlas el ritmo desde `presentador.html`, y al final se genera la misma propuesta que el Módulo 1 de `radar_diagnostico.html`: clasificación global, eje crítico, radar, diagnóstico + acciones por eje (accordion) y Horizontes de Acción H1/H2/H3 — el puente directo hacia "cómo construimos la Hoja de Ruta" en vivo.

## v3 — resultado final ahora es una propuesta completa, no solo un radar

Antes la pantalla final solo mostraba el radar. Ahora el flujo de resultados (`mostrarResumen()` en `presentador.html`) replica el motor completo del Módulo 1 de `radar_diagnostico.html`:
- Clasificación global (Madurez Inicial → Referente Digital) con resumen narrativo.
- Eje crítico detectado (el más bajo de los 8).
- Barras por eje + radar.
- Tarjetas expandibles por eje con diagnóstico (`fb.tx`) y 3 acciones prioritarias (`fb.ac`) según el nivel bajo/medio/alto.
- Horizontes de Acción H1/H2/H3 (los 3 ejes más débiles, los 3 intermedios, los 2 más fuertes) con recomendaciones de ejecución — esto es literalmente el punto donde cierras la sección de diagnóstico y arrancas la construcción de la Hoja de Ruta con la sala.

Todo esto vive solo en `presentador.html` (lo que se proyecta); `radar_vivo_participante.html` no cambió.

## Qué cambió respecto a la v1 (por qué "no funcionaba nada")

La v1 usaba la librería `@supabase/supabase-js` + WebSockets (Realtime) y dependía de 4 archivos sueltos (`presentador.html` + `config.js` + `preguntas.js` + `vivo.html`). Dos fallas probables:

1. `config.js` tenía credenciales de relleno — nunca las completaste, así que nada podía conectar a Supabase.
2. Realtime necesita, además del SQL, un toggle manual en el dashboard de Supabase (Database → Replication) que es fácil de pasar por alto.

Esta v2 corrige ambas cosas: usa **el mismo patrón que ya funciona en `radar_diagnostico.html`** — `fetch()` puro contra la REST API, con tus credenciales reales ya embebidas — y sondea cada 2-3 segundos en vez de depender de WebSockets. Cada vista es **un solo archivo autocontenido**: no hay archivos sueltos que se puedan perder al copiar.

## 1. Único paso pendiente: correr `schema.sql`

Entra a tu proyecto Supabase (el mismo de `radar_diagnostico.html`, `djgqohrwjxymmguefljs`) → SQL Editor → pega el contenido de `schema.sql` → Run. Crea 3 tablas (`sesiones_vivo`, `respuestas_vivo`, `presencia_vivo`) con RLS abierto (sin login, apropiado para una herramienta efímera de conferencia). No necesitas tocar nada más — las credenciales ya están en el código.

## 2. Revisa las 24 preguntas seleccionadas

Elegí 3 preguntas por cada uno de los 8 ejes reales de tu banco de 48 (las tomé directamente del `AXES` de tu `radar_diagnostico.html`). Están en **dos lugares que deben quedar idénticos**: el array `AXES_VIVO` dentro de `presentador.html` y dentro de `radar_vivo_participante.html`. Si cambias una pregunta, cámbiala en ambos archivos exactamente igual (mismo texto, mismo orden) — si no, el presentador y el público verán preguntas distintas.

## 3. Sube la carpeta al repo

Sube `presentador.html`, `radar_vivo_participante.html` y `schema.sql` a `andrezgmz.github.io` (por ejemplo en `/conferencias/`) y haz commit + push.

## 4. Prueba end-to-end ANTES del 8 de septiembre

1. Abre `presentador.html` publicado (no en local — confirma que funciona sobre GitHub Pages real).
2. Clic en Crear sesión → debe aparecer PIN + QR sin errores.
3. Desde tu celular (datos móviles, no la misma red que tu laptop, para simular un asistente real) entra con el PIN.
4. Clic en Iniciar → confirma que la pregunta aparece en el celular en ≤2-3 segundos.
5. Responde → confirma que la barra en la pantalla del presentador se actualiza en el siguiente ciclo de sondeo.
6. Avanza las 24 preguntas y confirma que el radar final se genera.
7. **Repite con 15-20 personas reales antes del evento**, no solo contigo. Un WiFi de auditorio con 30-100 celulares es un escenario distinto.

## 5. Plan B si falla el WiFi del auditorio

Sigue dependiendo de internet (Supabase es la base de datos). Si el WiFi del lugar falla, la herramienta no funciona:

- Lleva tu propio hotspot 4G/5G dedicado como conexión primaria, no confíes en el WiFi del venue.
- Ten lista una diapositiva de respaldo con las mismas 8 preguntas para mano alzada verbal, y sigue con la conferencia usando un radar de ejemplo pregrabado en vez del radar en vivo. Prepárala ahora, no la improvises ese día.

## 6. Simplificaciones conscientes del MVP

- Sin login para crear sesiones — riesgo bajo dado el uso, pero cualquiera con el link de `presentador.html` podría crear una sesión.
- "Conectados" se calcula por heartbeat cada 5 segundos (tabla `presencia_vivo`), no es instantáneo — es normal ver el número moverse con 3-5 segundos de rezago.
- Cada persona vota una vez por pregunta (upsert): si cambia de opinión antes de que avances, se sobreescribe su respuesta, no se duplica.
