# Taller 8 — Cámara 3D y Límites del Nivel (Desarrollo 2D y 3D)

**Asignatura:** Desarrollo de Videojuegos 2D y 3D — Sesión 8  
**Proyecto:** Clicklike 3D  
**Repositorio GitHub:** [Project-Duplaa/Click-the-button-3D](https://github.com/Project-Duplaa/Click-the-button-3D)

---

## 1. Tarea Implementada: Tarea A — Cámara Suave y Clamping

Se creó el script `camara_sigue.gd` asignado a Camera3D para seguir al custodio con suavizado e interpolación temporal, además de restringir el desplazamiento del jugador dentro de la arena.

### Niveles y Commits de Código:
* **Nivel 1:** `d097a18` — `T8 N1 - Tarea A - camara pegada`  
  *Seguimiento rígido manteniendo un offset cenital de `(0, 9.5, 8.0)` mirando en ángulo de -50° hacia el jugador.*
* **Nivel 2:** `a75f72c` — `T8 N2 - Tarea A - camara con suavizado`  
  *Interpolación de posición mediante `global_position = global_position.lerp(destino, suavizado * delta)` eliminando tirones de movimiento.*
* **Nivel 3:** `2edbda9` — `T8 N3 - Tarea A - limites del nivel`  
  *Restricción física de bordes usando `clampf` sobre los límites `X: [-12.0, 12.0]` y `Z: [-12.0, 12.0]` impidiendo que el personaje caiga al vacío.*

---

## 2. Documentos Oficiales en Word (.docx)
* `Taller_8_Jhon_Sebastian_Amado.docx`
* `Taller_8_Juan_Sebastian_Prada.docx`
* `Taller_8_Juan_Camilo_Angulo.docx`
