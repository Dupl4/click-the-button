# Taller 10 — Clicklike: el primer ciclo jugable (Desarrollo 2D y 3D)

**Asignatura:** Desarrollo de Videojuegos 2D y 3D — Sesión 10, Corte 2  
**Proyecto:** Clicklike 3D  
**Repositorio GitHub:** [Project-Duplaa/Click-the-button-3D](https://github.com/Project-Duplaa/Click-the-button-3D)

---

## 1. Tareas Individuales del Equipo

| Integrante | Tarea Oficial | Archivos Creados | Responsabilidad Técnica |
| :--- | :--- | :--- | :--- |
| **Juan Camilo Angulo Camelo** | **Tarea A (Receta P: La Partida)** | `partida.gd` | FSM de ciclo de partida (`JUGANDO`, `GANO`, `PERDIO`), run de 15 min (900 s), control de pausa (`get_tree().paused`), variables estáticas `intentos` y `mejor_tiempo`. |
| **Juan Sebastián Prada Jurado** | **Tarea B (Receta O: El Objetivo)** | `cofre.gd`, `cofre.tscn`, `salida.gd`, `salida.tscn` | Area3D con detección dual (cuerpo físico del jugador y click de ratón), reducción de objetivos faltantes en grupo y apertura del portal de salida. |
| **Jhon Sebastián Amado Duarte** | **Tarea C (Receta H: Peligro y Salud)** | `salud.gd`, `hud.gd`, `hud.tscn` | Componente de salud desacoplado con señales `cambio` y `sin_vida`, temporizador de invulnerabilidad (`i-frames`), 3 vidas con reaparición y animación de parpadeo. |

---

## 2. Commits de Código en GitHub

### Tarea A (Juan Camilo Angulo)
* `6d5dc12` — `T10 N1 - Tarea A - fin de partida`
* `bcf2f28` — `T10 N2 - Tarea A - metas y pausa`
* `a423629` — `T10 N3 - Tarea A - reinicio y record`

### Tarea B (Juan Sebastián Prada)
* `87d02fe` — `T10 N1 - Tarea B - objetivo con area`
* `78411ea` — `T10 N2 - Tarea B - cuenta y avisa`
* `f9e88fd` — `T10 N3 - Tarea B - salida al final`

### Tarea C (Jhon Sebastián Amado)
* `ab11f2a` — `T10 N1 - Tarea C - vida en el hud`
* `e446a65` — `T10 N2 - Tarea C - sin vida pierde`
* `5b4b4db` — `T10 N3 - Tarea C - reaparecer`

### Avance del Proyecto (Integración de Equipo)
* `fac9c3d` — `T10 Avance - conectar anomalia, cofres, salud y ciclo jugable`

---

## 3. Avance del Proyecto en `main.tscn`
Se conectaron todos los componentes individuales en una única escena jugable:
1. El jugador derrota guardias con autoataques a distancia / cuerpo a cuerpo o clicks manuales sobre la arena.
2. Cada guardia derrotado arroja gemas de XP o monedas de oro con atracción magnética.
3. Se recolectan los 3 cofres (o se les da click directo) para abrir el portal de salida `Salida`.
4. El custodio dispone de 3 vidas con reaparición en `(0, 0.5, 0)` tras sufrir daño de los guardias.
5. Al cruzar el portal o sobrevivir el límite temporal de la run, la partida finaliza con victoria registrando el récord global.

---

## 4. Documentos Oficiales en Word (.docx)
* `Taller_10_Juan_Camilo_Angulo.docx`
* `Taller_10_Juan_Sebastian_Prada.docx`
* `Taller_10_Jhon_Sebastian_Amado.docx`
