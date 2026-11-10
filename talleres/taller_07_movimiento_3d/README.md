# Taller 7 — Movimiento del Personaje 3D (Desarrollo 2D y 3D)

**Asignatura:** Desarrollo de Videojuegos 2D y 3D — Sesión 7  
**Proyecto:** Clicklike 3D  
**Repositorio GitHub:** [Project-Duplaa/Click-the-button-3D](https://github.com/Project-Duplaa/Click-the-button-3D)

---

## 1. Tarea Implementada: Tarea A — Cinemática y FSM del Personaje

Se programó en `personaje.gd` (CharacterBody3D) el sistema cinemático con vector de movimiento normalizado, aceleración progresiva y máquina de estados finitos.

### Niveles y Commits de Código:
* **Nivel 1:** `1d294d1` — `T7 N1 - Tarea A - correr y la diagonal`  
  *Implementación de la normalización del vector de entrada con `input_dir.normalized()` para evitar la ventaja de velocidad en diagonales (factor 1.414 reducido a 1.0).*
* **Nivel 2:** `1dbc47f` — `T7 N2 - Tarea A - arranque y frenado`  
  *Suavizado cinemático con aceleración (`aceleracion = 18.0 m/s²`) y desaceleración (`friccion = 24.0 m/s²`) mediante `move_toward`.*
* **Nivel 3:** `fc2bebe` — `T7 N3 - Tarea A - estados con su numero`  
  *FSM determinista con estados: `0: IDLE`, `1: WALK`, `2: RUN` imprimiendo transiciones en consola de depuración.*

---

## 2. Documentos Oficiales en Word (.docx)
* `Taller_7_Jhon_Sebastian_Amado.docx`
* `Taller_7_Juan_Sebastian_Prada.docx`
* `Taller_7_Juan_Camilo_Angulo.docx`
