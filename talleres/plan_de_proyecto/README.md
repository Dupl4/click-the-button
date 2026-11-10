# PLAN DE PROYECTO: CLICKLIKE 3D
## Supervivencia en el Coliseo Monumental y el Núcleo Móvil

**Asignatura:** Desarrollo de Videojuegos 2D y 3D & Desarrollo Conceptual  
**Corte:** Corte 3 · Noviembre - Diciembre 2026  
**Equipo de Desarrollo:**
* **Jhon Sebastián Amado Duarte** (Líder de Arquitectura / Rol: Guerrero - Tanque)
* **Juan Sebastián Prada Jurado** (Combate y Entidades / Rol: Cazador - Ranger)
* **Juan Camilo Angulo Camelo** (Sistemas, UI y Balance / Rol: Mago - Arcanista)

**Repositorio Oficial:** [Project-Duplaa/Click-the-button-3D](https://github.com/Project-Duplaa/Click-the-button-3D)  
**Versión de Godot:** Godot Engine v4.7.2 Stable (GL Compatibility / Vulkan)

---

## 1. Ficha Técnica y Visión del Proyecto

### Premisa Central:
**Clicklike 3D** es una propuesta innovadora que fusiona la adrenalina del género *Survivor Roguelite* en 3D (al estilo de *Vampire Survivors* y *Brotato*) con la interactividad frenética de los juegos *Clicker*. 

El jugador asume el papel de un combatiente atrapado en un monumental Coliseo romano de 60x60 metros, enfrentándose a oleadas crecientes de enemigos tácticos y enjambres continuos. Mientras maniobra el posicionamiento y la evasión espacial mediante controles cinemáticos de teclado (WASD + Shift para correr), el héroe ejecuta autoataques automáticos acordes a su especialidad. No obstante, el corazón jugable radica en el ratón: el combatiente debe rastrear, apuntar y presionar en tiempo real un **Botón Móvil 3D (el Núcleo)** que recorre la arena a gran velocidad, acelerando, encogiéndose y teletransportándose tras recibir impactos, liberando ondas de choque defensivas y otorgando los recursos necesarios para evolucionar y sobrevivir.

| Parámetro | Especificación Técnica |
| :--- | :--- |
| **Título Oficial** | Clicklike 3D: El Coliseo del Núcleo Móvil |
| **Género** | Clicker Roguelite Survivor en 3D (Autobattler Híbrido) |
| **Motor y Versión** | Godot Engine v4.7.2 Stable |
| **Espacio de Juego** | Arena Coliseo Monumental de 60 x 60 metros con muros de 4.5 m de altura |
| **Modo de Control** | Teclado (WASD + Shift para sprint) + Ratón (Apuntado y click activo sobre el botón móvil) |
| **Condición de Victoria** | Sobrevivir los 15 minutos de la run y resistir/derrotar a la Parca Roja |
| **Condición de Derrota** | Agotar las 2 reapariciones (3 vidas en total) tras caer en combate |
| **Equipo de Desarrollo** | Jhon Sebastián Amado Duarte, Juan Sebastián Prada Jurado, Juan Camilo Angulo Camelo |

---

## 2. Diagnóstico del Estado Actual del Juego (Lo que ya está Construido)

A la fecha de formulación de este plan, el equipo ha desarrollado, verificado y sincronizado en el repositorio una base jugable tridimensional completamente funcional, robusta y libre de errores de ejecución:

| Módulo | Archivos Principales | Estado | Alcance Implementado |
| :--- | :--- | :---: | :--- |
| **Gran Arena 60x60 m** | `arena_coliseo.tscn` | **Construida** | Superficie de 64x64 m, muros de piedra de 4.5 m de altura, cornisas de sillería y 12 columnas con antorchas procedurales titilantes. |
| **Botón Móvil Dinámico** | `boton_movil.tscn` / `.gd` | **Construido** | Pedestal rúnico que patrulla 6 waypoints a 2.8 m/s, acelera (+0.22 m/s/click), se encoge (-2.2%/click) y se teletransporta cada 5 clics. |
| **Cinemática y Cámara** | `personaje.gd`, `camara_sigue.gd` | **Construido** | Movimiento top-down con aceleración/frenado, carrera en Shift, cámara cenital a 12 m con límites elásticos en [-27, 27] m. |
| **Bestiario Base** | `espectro.tscn`, `guardia.tscn`, `bruto.tscn` | **Construido** | 3 arquetipos: Espectro rápido (4.4 m/s, 18 HP), Guardia gladiador (FSM con RayCast3D) y Bruto colosal (220 HP, escala 3.8x). |
| **Feedback de Daño 3D** | `damage_number_3d.tscn` | **Construido** | Etiquetas 3D en billboard con pop, elevación física, desvanecimiento y colores reactivos (oro en clics/críticos, rojo en daño recibido). |
| **Spawner de Oleadas** | `oleadas_spawner.gd` | **Construido** | Generación perimetral a 26 m de radio con escalado de composición (enjambres en oleadas 1-2, guardias en 3-4, brutos en 5+). |
| **HUD y Drafting** | `click_hud.tscn` / `.gd` | **Construido** | Barras de salud, XP, nivel, oro, oleada, cronómetro, contador de clics con velocidad en tiempo real y modal de 3 cartas roguelike. |

---

## 3. Análisis de Brechas: Lo que Hace Falta del Juego (Backlog)

| Código / Brecha | Prioridad | Descripción del Requerimiento y Comportamiento Esperado |
| :--- | :---: | :--- |
| **B1: Metamorfosis y Evolución de Clases** | **Alta** | El personaje arranca como Novato base. Falta implementar el hito de evolución (al alcanzar el Nivel 3 o 15 clics) donde se despliega un modal que permite transformarse en Guerrero (corte melee masivo), Cazador (ametralladora de flechas rápidas) o Mago (orbes arcanos penetrantes), intercambiando el modelo 3D y su repertorio de combate. |
| **B2: Enemigos Tácticos a Distancia** | **Alta** | Actualmente todos los enemigos atacan cuerpo a cuerpo. Falta programar el arquetipo de Arquero/Cultista que mantenga distancia (kiting inverso a 10 m) y dispare proyectiles físicos lentos con trayectoria recta, obligando al jugador a prestar atención a esquivar proyectiles mientras persigue el botón. |
| **B3: Objetivos Secundarios CoD Zombies** | **Media** | Faltan 3 Altares/Tótems ancestrales ubicados en las ruinas de la arena. Si el jugador hace que el botón pase sobre ellos o interactúa con los altares en secuencia, se activa un evento especial (lluvia de oro, activación de torre de apoyo o desbloqueo de reliquia legendaria). |
| **B4: Mini-Jefe y La Parca Roja** | **Alta** | Al minuto 5 debe aparecer un Mini-Jefe con barra de salud dedicada en pantalla y ataques telegrafiados. Al cumplirse el tiempo límite de la run (15 min), debe invocarse La Parca Roja: un jefe colosal con estadísticas extremas que ejecuta al jugador a menos que posea una build perfecta. |
| **B5: Diseño Sonoro Integral (SFX y Música)** | **Media** | Falta implementar un AudioManager desacoplado que gestione el sonido físico del clic del botón, las alertas de oleada, pasos sobre arena, quejidos de daño, impactos de proyectiles y una banda sonora dinámica con percusión romana. |
| **B6: Pantalla de Fin de Partida y Métricas** | **Media** | Falta la interfaz de Game Over / Victoria con resumen analítico de la sesión: tiempo sobrevivido, clics totales al botón móvil, enemigos abatidos, nivel alcanzado y opción de reintento inmediato sin reiniciar el motor. |

---

## 4. Matriz de Asignación de Roles y Responsabilidades

| Integrante | Rol y Especialidad | Módulos y Tareas Asignadas |
| :--- | :--- | :--- |
| **Jhon Sebastián Amado Duarte** | **Líder de Arquitectura & Mecánicas Centrales**<br>*(Guerrero / Tanque)* | 1. FSM de Evolución de Clases en `personaje.gd` (metamorfosis y cambio de malla 3D).<br>2. Implementación del combate del Guerrero (corte giratorio melee y bloqueo).<br>3. Sistema de vidas, contador de reapariciones y disparador de derrota definitiva.<br>4. Optimización de colisiones en la arena y revisión de merges en GitHub. |
| **Juan Sebastián Prada Jurado** | **Ingeniero de Combate, Entidades y Spawners**<br>*(Cazador / Ranger)* | 1. Diseño y programación del enemigo a distancia Arquero/Cultista (`arquero.gd`, `arquero.tscn`).<br>2. Sistema de proyectiles enemigos esquivables y pool de físicas de colisión.<br>3. Especialidad del Cazador: disparo múltiple de flechas y velocidad de ataque escalable.<br>4. Calibración de curvas de spawn y composición de oleadas en `oleadas_spawner.gd`. |
| **Juan Camilo Angulo Camelo** | **Sistemas de Juego, UI, Balance y Secretos**<br>*(Mago / Arcanista)* | 1. Sistema de Objetivos Secundarios tipo CoD Zombies (altares rúnicos interactivos).<br>2. Programación del Jefe Final La Parca Roja (`parca_roja.gd`) y Mini-Jefe con barra de vida.<br>3. Especialidad del Mago: orbes arcanos teledirigidos con daño en área (AOE).<br>4. Integración del AudioManager, diseño sonoro, interfaz de Game Over y balance econométrico. |

---

## 5. Cronograma de Trabajo por Semanas (Sprints de Corte 3)

| Semana / Período | Objetivo Central | Entregables Técnicos y Verificación | Responsables |
| :--- | :--- | :--- | :--- |
| **Semana 1**<br>*(Sprint 1: Nov 9 - Nov 15)* | **Sistema de Evolución y Enemigos a Distancia** | • Integración del modal de selección de evolución al alcanzar Nivel 3 o 15 clics.<br>• Metamorfosis activa a Guerrero, Cazadora o Mago con cambio de modelo Kenney y arma.<br>• Creación de la escena `arquero.tscn` con IA que mantiene distancia y dispara flechas.<br>• *Commit esperado:* `Sprint 1 - Metamorfosis de clases y enemigos a distancia`. | Jhon Amado (Evolución)<br>Juan Prada (Arqueros) |
| **Semana 2**<br>*(Sprint 2: Nov 16 - Nov 22)* | **Easter Eggs de CoD Zombies y Mini-Jefe de Arena** | • Creación de 3 pedestales/altares rúnicos interactivos en los cuadrantes de la arena.<br>• Lógica de puzzle: activar los 3 altares libera un cofre dorado ancestral con reliquia.<br>• Implementación del Mini-Jefe Gladiador de Élite al minuto 5 con barra superior.<br>• *Commit esperado:* `Sprint 2 - Altares easter egg y mini jefe de arena`. | Juan Angulo (Altares)<br>Juan Prada (Mini-Jefe) |
| **Semana 3**<br>*(Sprint 3: Nov 23 - Nov 29)* | **La Parca Roja y Diseño Sonoro Integral** | • Creación del Jefe Final 'La Parca Roja' (`parca_roja.tscn`): aparece al cumplirse los 15 min.<br>• Comportamiento implacable: velocidad superior al héroe, guadaña de sombra y 5000 HP.<br>• Implementación de AudioManager (SFX de clics, pasos, quejidos, flechas y fanfarria).<br>• *Commit esperado:* `Sprint 3 - Jefe final Parca Roja y sistema de audio integrado`. | Juan Angulo (Parca & Audio)<br>Jhon Amado (Balance) |
| **Semana 4**<br>*(Sprint 4: Nov 30 - Dic 6)* | **Pantalla de Fin de Partida, Pulido y Cierre** | • Interfaz de Victoria / Game Over con panel estadístico de métricas de la run.<br>• Auditoría exhaustiva de 0 errores en consola y prueba de estrés a 60 fps con 60+ entidades.<br>• Congelamiento de versión candidata (Release Candidate v1.0) y empaquetado final.<br>• *Commit esperado:* `Sprint 4 - Release final Clicklike 3D y pulido de ciclo de juego`. | Equipo Completo<br>*(Lidera Jhon Amado)* |

---

## 6. Gestión de Riesgos Técnicos y Plan de Contingencia

| Riesgo Identificado | Probabilidad | Estrategia de Mitigación y Contingencia |
| :--- | :---: | :--- |
| **R1: Caída de FPS con Hordas Masivas en 3D** | **Media** | Límite estricto de 45 enemigos concurrentes en pantalla mediante un pool de nodos. Si se supera el umbral, los enemigos lejanos fuera del campo visual son reciclados. |
| **R2: Dificultad para Cliquear el Botón Móvil a Alta Velocidad** | **Baja** | El radio de colisión del raycast (`CollisionShape3D`) del botón se mantendrá siempre con un margen de tolerancia del +35% respecto a su modelo visual. |
| **R3: Desbalance de la Parca Roja (Frustración)** | **Baja** | La Parca Roja tendrá una mecánica de telegraph visual previo (marcas rojas en el suelo) para que el combate sea exigente pero justo. |
| **R4: Conflictos de Fusión en Escenas Compartidas (`main.tscn`)** | **Media** | Política estricta de ramas y escenas heredadas: cada integrante trabaja en escenas secundarias (`.tscn`) desacopladas y la integración a `main.tscn` se realiza en sesiones conjuntas. |

---

## 7. Criterios de Aceptación Académica (Rubro 5.0)

1. **Ciclo Jugable Cerrado:** Menú ➔ Selección de Clase Inicial ➔ Entrada a Arena 60x60 ➔ Combate de 15 min ➔ Batalla de Parca Roja ➔ Pantalla de Resultados.
2. **Interactividad Dual Impecable:** Cero errores de clic sobre el botón móvil en aceleración máxima y teletransporte sin fallos.
3. **Tres Clases Diferenciadas:** Cada clase (Guerrero, Cazador, Mago) cuenta con su modelo 3D independiente y estilo de combate exclusivo.
4. **Trazabilidad en GitHub:** Historial de commits ordenado, continuo y atribuido a los tres integrantes del equipo.

---
*Compromiso de Equipo registrado en noviembre de 2026.*  
*Jhon Sebastián Amado Duarte · Juan Sebastián Prada Jurado · Juan Camilo Angulo Camelo*
