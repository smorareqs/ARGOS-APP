# ARGOS PRD

## Sistema de Gestión de Personal para Propiedades Airbnb

---

# 1. Resumen del Proyecto

ARGOS es una plataforma de gestión del personal de limpieza y mantenimiento para propiedades de alquiler de corto plazo (Airbnb).

El sistema se compone de dos interfaces principales:

* Aplicación móvil para personal de campo.
* Plataforma web administrativa.

La solución es multi-tenant, permitiendo que empresas administradoras o propietarios individuales operen en espacios completamente aislados.

### Objetivos principales

1. Gestión del itinerario de trabajo.
2. Reporte rápido de incidencias y averías.
3. Sistema de alertas y notificaciones.
4. Control de mantenimiento de propiedades.

---

# 2. Arquitectura Multi-Tenant

Cada cliente constituye un tenant independiente.

## Jerarquía del sistema

* Proveedor (ARGOS)
* Cliente / Tenant
* Administradores
* Supervisores
* Empleados

## Aislamiento de datos

Toda la información pertenece exclusivamente a un tenant:

* Propiedades
* Empleados
* Inventario
* Itinerarios
* Bitácora
* Métricas

No existe visibilidad entre clientes.

---

# 3. Roles de Usuario

| Rol           | Plataforma | Descripción                                                   |
| ------------- | ---------- | ------------------------------------------------------------- |
| Empleado      | App móvil  | Ejecuta limpiezas, registra información y reporta incidencias |
| Supervisor    | App móvil  | Supervisa equipos, reasigna trabajo y valida tareas           |
| Administrador | Web        | Gestiona toda la operación                                    |

## Propietarios

La condición de propietario es un atributo, no un rol.

Puede operar como:

* Administrador.
* Usuario de solo lectura.

---

# 4. Aplicación Móvil

La aplicación móvil constituye la herramienta principal del personal operativo.

---

## 4.1 Itinerario

* Vista diaria y semanal.
* Horarios de entrada y salida.
* Información de acceso.
* Estado de tareas.
* Registro de checkpoints.

Estados:

* Pendiente
* En progreso
* Finalizada

---

## 4.2 Actividades

Checklist configurable por propiedad.

Características:

* Habitaciones.
* Baños.
* Cocina.
* Áreas comunes.
* Evidencias fotográficas.
* Observaciones.

---

## 4.3 Equipo

Gestión de herramientas e insumos.

* Productos de limpieza.
* Herramientas.
* Llaves.
* Solicitudes de reposición.
* Reporte de daños.

---

## 4.4 Registro de Datos

* Inicio y fin de jornada.
* Fotografías antes y después.
* Reporte de daños.
* Consumo de insumos.
* Observaciones.

---

## 4.5 Métricas

* Limpiezas realizadas.
* Tiempo promedio.
* Cumplimiento de tareas.
* Progreso de metas.
* Incentivos.

---

# 5. Plataforma Web Administrativa

Centro de control operativo.

---

## 5.1 Apartamentos

* Alta de propiedades.
* Edición.
* Eliminación.
* Configuración de checklists.
* Historial de limpiezas.
* Relación con propietarios.

---

## 5.2 Empleados

* Administración de personal.
* Roles.
* Permisos.
* Horarios.
* Disponibilidad.
* Métricas.

---

## 5.3 Bitácora

Registro cronológico del sistema.

Incluye:

* Limpiezas.
* Evidencias.
* Incidencias.
* Trazabilidad.
* Filtros.

---

## 5.4 Inventario General

* Productos.
* Herramientas.
* Existencias.
* Alertas.
* Movimientos.
* Asignaciones.

---

## 5.5 Control de Itinerario

* Asignación de tareas.
* Calendario.
* Reprogramación.
* Seguimiento.
* Detección de retrasos.

---

## 5.6 Métricas e Incentivos

* Productividad.
* Cumplimiento.
* Rankings.
* Metas.
* Reportes.

---

# 6. Mantenimiento

Permite controlar el estado operativo de cada propiedad.

---

## 6.1 Elementos Controlados

* Cámaras de seguridad.
* Sistemas de agua.
* Pintura.
* Electrodomésticos.
* Plomería.
* Electricidad.
* Aire acondicionado.

---

## 6.2 Reportes desde la App

* Fotografías.
* Descripción.
* Nivel de urgencia.
* Selección del elemento afectado.
* Seguimiento del reporte.

---

## 6.3 Gestión desde la Web

Estados:

* Operativo
* Requiere atención
* En reparación
* Resuelto

Características:

* Asignación de responsables.
* Historial.
* Mantenimientos preventivos.
* Recordatorios.
* Indicadores.

---

# 7. Alertas y Notificaciones

Funcionalidad transversal entre la app y la plataforma web.

---

## 7.1 Notificaciones Push

* Nuevas tareas.
* Cambios de itinerario.
* Reasignaciones.
* Recordatorios.
* Confirmaciones.
* Alertas de inventario.

---

## 7.2 Panel de Alertas

* Elementos averiados.
* Mantenimientos vencidos.
* Retrasos.
* Inventario bajo.
* Filtros de prioridad.

# Visión del Producto

ARGOS busca convertirse en la plataforma operativa integral para la administración de propiedades de alquiler temporal, centralizando la limpieza, mantenimiento, inventario y desempeño del personal en una sola solución.
