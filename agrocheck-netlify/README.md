# AgroCheck – Plataforma web con IA (Netlify + Supabase)

**Objetivo:** Plataforma web para exportadores agroindustriales. Permite registrar lotes, subir documentos, usar un asistente IA (embebido con Jotform) para validar calidad y documentación, y emitir una constancia en PDF cuando todo está conforme.

- **Frontend:** HTML + JS (sin build), Tailwind CDN
- **Backend-as-a-service:** Supabase (Auth, DB, Storage)
- **IA:** Jotform (iframe provisto)
- **Deploy:** Netlify (conecta tu repo de GitHub)

## Estructura
```
.
├─ index.html
├─ assets/
│  ├─ css/styles.css
│  └─ js/
│     ├─ env.js           # URL y Anon Key de Supabase (prellenado para demo)
│     ├─ supabaseClient.js
│     ├─ certificate.js
│     └─ app.js
├─ images/
│  └─ logo_agrocheck.png  # Cambia por tu logo
├─ public/
│  └─ env.example.js      # Plantilla
└─ supabase.sql           # Esquema y políticas (ejecuta en Supabase SQL Editor)
```

## Pasos rápidos (resumen)
1) Crea el proyecto en Supabase y **ejecuta** `supabase.sql` (SQL Editor).
2) En Supabase > Auth > URL config, agrega tu dominio de Netlify a **Redirect URLs**.
3) En `assets/js/env.js` coloca tu `SUPABASE_URL` y `SUPABASE_ANON_KEY` (ya viene prellenado para prueba).
4) Sube este folder a GitHub y conéctalo a Netlify (deploy sin build).
5) ¡Listo! Regístrate, elige plan y crea tu primer lote.

Lee las instrucciones detalladas en el mensaje del asistente o en este README.
