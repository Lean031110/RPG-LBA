# Firebase para RPG LBA Asset Factory

## Papel de Firebase
Firebase es opcional y complementario. Firestore puede guardar estado operacional ligero: asset_id, estado de revisión, timestamps, job_id, enlaces a GitHub PR/Actions y comentarios. GitHub sigue siendo la fuente de verdad del catálogo y del historial.

No almacenar modelos 3D, texturas grandes, workflows únicos ni secretos en Firestore.

## Plan Spark y cuotas consultadas
- Spark no-cost no requiere método de pago.
- Cloud Firestore: 1 GiB almacenado, 50.000 lecturas/día, 20.000 escrituras/día, 20.000 borrados/día y 10 GiB de salida/mes. Solo una base de datos por proyecto recibe la cuota gratuita.
- Firebase Hosting: hasta 10 GB de almacenamiento y 10 GB/mes de transferencia sin coste, según la tabla de cuotas vigente.
- Firebase Cloud Messaging (FCM) es no-cost.
- Cloud Functions y ciertos servicios de Google Cloud requieren Blaze; no diseñar el MVP dependiendo de ellos.
- Firestore backups, PITR, TTL deletes, restore y clone no están incluidos en el uso gratuito. Mantener exportaciones JSON independientes y probarlas.
- Monitorizar Usage & billing. En Spark, al alcanzar el límite de cuota gratuita, algunas operaciones/servicios se bloquean hasta el siguiente periodo o hasta cambiar de plan. No habilitar Blaze sin autorización explícita del propietario.

## Modelo de datos propuesto
Colecciones:
- assets/{asset_id}: estado actual, categoría, ruta GitHub, hash, licencia y PR asociado.
- jobs/{job_id}: proveedor, tipo de tarea, estado, timestamps, retry_count, resultado y enlace al run.
- reviews/{review_id}: asset_id, reviewer_uid, decisión, notas, timestamp.
- provider_quotas/{provider_id}: cuota conocida, última consulta, reset_at, estado y fuente.
- system/health: estado de integraciones y última comprobación.

No duplicar todo el catálogo en Firestore; sincronizar solo campos operativos o crear una proyección regenerable desde GitHub.

## Seguridad
- Firestore Security Rules: denegar por defecto; permitir únicamente usuarios autenticados autorizados.
- Activar App Check cuando se publique un frontend.
- Nunca incluir service-account JSON en frontend, repositorio, n8n workflow export ni prompt.
- El service account solo se usa en backend/secret store, con permisos mínimos.
- No confiar en el cliente para aprobar assets, alterar licencias o cambiar estados a APPROVED/INTEGRATED.
- Los secretos nunca se envían por Telegram.

## Estado
No existe todavía un Firebase project conectado a este repositorio. Proyecto, reglas desplegadas, Auth, Firestore y FCM: NOT CONFIGURED / NOT TESTED. Z.ai debe crear configuración local, validar reglas con Emulator Suite y pedir al propietario que cree/autorice el proyecto y añada secretos; no activar facturación.
