# Taller Sesión 5 — El nivel en papel (Desarrollo Conceptual)

**Asignatura:** Desarrollo Conceptual de Videojuegos — Corte 2, Sesión 5  
**Proyecto:** Clicklike 3D (Incremental Roguelike Autobattler en Godot 4)  
**Equipo:** Jhon Sebastián Amado Duarte, Juan Sebastián Prada Jurado, Juan Camilo Angulo Camelo  
**Repositorio GitHub:** [Project-Duplaa/Click-the-button-3D](https://github.com/Project-Duplaa/Click-the-button-3D)

---

## 1. Ficha Técnica del Nivel y Distribución de Zonas

* **Nombre del Nivel:** La Ciudadela del Núcleo Fragmentado
* **Premisa Espacial:** Arena 3D interconectada dividida en 3 zonas secuenciales con portales de resonancia y puntos de control.

| Zona | Estudiante Responsable | Nombre de la Zona | Función Principal | Escala y Dimensiones | Duración Estimada |
| :---: | :--- | :--- | :--- | :--- | :---: |
| **1** | **Jhon Sebastián Amado** | Zona 1 — Entrada y Corredor Oeste | **Enseñar:** Movimiento, esquive y combate melee | 1 cuadro = 1.5 m (24 m x 18 m) | 150 s (2:30 min) |
| **2** | **Juan Sebastián Prada** | Zona 2 — Plaza de Resonancia Central | **Practicar:** Hordas cruzadas, trampas y kiting | 1 cuadro = 2.0 m (36 m x 28 m) | 210 s (3:30 min) |
| **3** | **Juan Camilo Angulo** | Zona 3 — Sanctum del Coloso | **Evaluar:** Boss fight contra Coloso y supervivencia | 1 cuadro = 2.5 m (40 m x 40 m) | 240 s (4:00 min) |

---

## 2. Tabla de Beats y Ritmo de Juego

### Beats de la Zona 1 (Amado - Guerrero)
1. **Beat 1 (15 s) — [Enseñar]:** Movimiento desde el punto de inicio `(0, 0.5, 0)` con WASD y familiarización de la cámara suave (caminar a 3.2 m/s).
2. **Beat 2 (20 s) — [Enseñar]:** Primer cofre `Cofre1` a la vista; uso de Shift para correr (5.8 m/s) y recoger oro.
3. **Beat 3 (30 s) — [Enseñar]:** Detección del primer Guardia patrullero; activación del autoataque melee a 2.8 m.
4. **Beat 4 (35 s) — [Practicar]:** Encrucijada táctica: bordear obstáculos `Caja1`/`Caja2` o atacar frontalmente al segundo guardia.
5. **Beat 5 (30 s) — [Combinar]:** Combate contra 2 guardias simultáneos apoyando el autoataque con clicks manuales.
6. **Beat 6 (20 s) — [Respiro]:** Zona segura con fuente curativa antes de cruzar hacia la Plaza Central.  
* **Total Zona 1:** 15 + 20 + 30 + 35 + 30 + 20 = **150 segundos**.

---

## 3. Mapa en Cuadrícula y Métricas Espaciales

```text
[ZONA 1: Bastión del Silencio - 16 x 12 cuadros @ 1.5 m/cuadro]
+-------------------------------------------------------+
| [INICIO (P)] . . . . . . . . . . . . . . . [CAJA O1]  |
| . . . . . . . [COFRE R1] . . . . . . . . . . . . . .  |
| . . . . . . . . . . . . . . . [GUARDIA E1] . . . . .  |
| . . . . . [CAJA O2] . . . . . . . . . . . . . . . .   |
| . . . . . . . . . . . . . . . . . . . . . . . . . .   |
| . . . . . . . . . [GUARDIA E2] . . . . . [COFRE R2]   |
| . . . . [FUENTE H1] . . . . . . . . . . . . . . . .   |
| . . . . . . . . . . . . . . . . . . [PORTAL ZONA 2]   |
+-------------------------------------------------------+
```

* **Comprobación 1 (Tiempo de carrera):** Recorrer el pasillo principal de 24.0 m a velocidad de carrera (5.8 m/s) toma `24.0 / 5.8 = 4.13 s`.
* **Comprobación 2 (Zona de peligro del Guardia):** Radio de visión de 7.0 m; el jugador dispone de `7.0 / 3.2 = 2.18 s` para reaccionar al ser detectado.

---

## 4. Registro de Prueba en Papel (Playtesting)
Se ejecutó la prueba en papel con estudiantes de otro equipo registrando:
1. *Observación:* Los jugadores intentaban pasar corriendo entre las dos cajas sin eliminar al guardia.
2. *Problema:* El guardia los alcanzaba por la espalda en el embudo.
3. *Ajuste aplicado:* Se ensanchó el pasillo de 2.0 m a 3.5 m y se reubicó el `Cofre1` como señuelo visible para forzar el ángulo de visión frontal.

---

## 5. Documentos Oficiales en Word (.docx)
* `Taller_Sesion_5_Jhon_Sebastian_Amado.docx`
* `Taller_Sesion_5_Juan_Sebastian_Prada.docx`
* `Taller_Sesion_5_Juan_Camilo_Angulo.docx`
