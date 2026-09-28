SISTEMA DE BASE DE DATOS
CENTRO ESTÉTICO: PROCEDIMIENTOS, CITAS Y PRODUCTOS

[ DESCRIPCIÓN DEL PROYECTO ]
Este repositorio contiene el diseño lógico y físico de la base de
datos para la gestión integral de un Centro Estético. El sistema
permite administrar la atención a clientes, agenda de citas, personal
especializado, catálogo de servicios, control de inventario e insumos.

[ ESTRUCTURA Y ENTIDADES PRINCIPALES ]

CLIENTES 

Información de contacto.

Perfil clínico: Historial de alergias y condiciones médicas.

Programa de fidelización y puntos acumulados.

ESPECIALISTAS / PERSONAL

Datos del personal técnico y profesional.

Certificaciones y especialidades asociadas.

Horarios de disponibilidad operativa.

PROCEDIMIENTOS Y SERVICIOS

Clasificación (Faciales, Corporales, Depilación, etc.).

Detalle de costo base, precio al público y duración estimada.

Lista de insumos requeridos por procedimiento.

GESTIÓN DE CITAS

Programación por fecha, hora y cliente.

Vinculación con procedimiento(s) y especialista asignado.

Control de estados: Pendiente, Completada, Cancelada.

INVENTARIO Y PRODUCTOS

Control de stock de insumos para uso interno y venta directa.

Gestión de proveedores y registro de entradas/salidas.

[ REGLAS DE NEGOCIO INTEGRADAS ]

Consumo de Insumos: Cada procedimiento ejecutado descuenta
automáticamente del inventario el consumo exacto de materiales.

Seguimiento: Posibilidad de enlazar el uso de
productos comerciales directamente a la cita del cliente para
trazabilidad comercial y clínica.

[ TECNOLOGÍAS ]

Lenguaje: SQL

Compatibilidad: MySQL 
