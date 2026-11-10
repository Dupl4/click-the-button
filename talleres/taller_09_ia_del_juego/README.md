# Taller 9 — La IA de su juego (Desarrollo 2D y 3D)

**Asignatura:** Desarrollo de Videojuegos 2D y 3D — Sesión 9, Corte 2  
**Proyecto:** Clicklike 3D  
**Repositorio GitHub:** [Project-Duplaa/Click-the-button-3D](https://github.com/Project-Duplaa/Click-the-button-3D)

---

## 1. Implementación de la IA: Receta A — El Guardia que Patrulla y Ve

Se implementó el script `guardia.gd` y la escena `guardia.tscn` (CharacterBody3D) gobernado por una máquina de estados finitos (FSM) de 5 estados:
* `PATRULLAR`: Recorrido cíclico de waypoints mediante aritmética modular `indice = (indice + 1) % puntos.size()`.
* `ESPERAR`: Pausa de observación en cada waypoint (`espera_tiempo = 1.0 s`).
* `PERSEGUIR`: Aproximación continua hacia `jugador.global_position` a velocidad de persecución (`3.5 m/s`).
* `ATACAR`: Frenado a distancia de melee (`1.2 m`) y ejecución del golpe.
* `BUSCAR`: Exploración del último punto de contacto visual durante `3.0 s` tras perder línea de visión.

### Sensor RayCast3D a Altura del Pecho:
* Nodo RayCast3D `Vision` configurado a `Y = 0.9 m` con `target_position = Vector3(0, 0, -rango_vision)`.
* Verificación con `is_colliding()` y `collider.is_in_group("jugador")`.

### Histéresis de Visión:
* Rango de visión de entrada: `7.0 m`.
* Rango de escape para perder al custodio: `10.0 m`. Evita temblores o cambios espasmódicos de estado.

---

## 2. Commits de Código en GitHub
* `dd618a7` — `T9 Base - grupo jugador`
* `bdd825d` — `T9 N1 - Tarea A - patrulla con indice`
* `250fdd4` — `T9 N2 - Tarea A - vision con rayo`
* `4181c3a` — `T9 N3 - Tarea A - ataca y busca`

---

## 3. Salidas Reales de Simulación en Godot 4
```text
Guardia -> ESPERAR cuadro 2 a 6.0 m
Guardia -> PATRULLAR cuadro 61 a 6.0 m
Guardia -> PERSEGUIR cuadro 98 a 6.13 m
Guardia -> ATACAR cuadro 252 a 1.18 m
```

---

## 4. Documentos Oficiales en Word (.docx)
* `Taller_9_Jhon_Sebastian_Amado.docx`
* `Taller_9_Juan_Sebastian_Prada.docx`
* `Taller_9_Juan_Camilo_Angulo.docx`
