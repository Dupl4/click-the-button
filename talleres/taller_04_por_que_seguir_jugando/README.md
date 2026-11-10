# Taller Sesión 4 — Por qué seguir jugando (Desarrollo Conceptual)

**Asignatura:** Desarrollo Conceptual de Videojuegos — Corte 2, Sesión 4  
**Proyecto:** Clicklike 3D (Incremental Roguelike Autobattler en Godot 4)  
**Equipo:** Jhon Sebastián Amado Duarte, Juan Sebastián Prada Jurado, Juan Camilo Angulo Camelo  
**Repositorio GitHub:** [Project-Duplaa/Click-the-button-3D](https://github.com/Project-Duplaa/Click-the-button-3D)

---

## 1. Distribución de Tramos y Roles

| Integrante | Rol en Clicklike 3D | Tramo Asignado | Enfoque de Balance |
| :--- | :--- | :--- | :--- |
| **Jhon Sebastián Amado Duarte** | Guerrero / Tanque | **Tramo 1: Aprender (Minutos 0 a 10)** | Salud inicial (140 HP), autoataque melee, economía de clicker y drops magnéticos |
| **Juan Sebastián Prada Jurado** | Cazador / Ranger | **Tramo 2: Dominar (Minutos 10 a 25)** | Cadencia de proyectiles, escalado de DPS, sinergias de reliquias y cofres de arena |
| **Juan Camilo Angulo Camelo** | Mago / Arcanista | **Tramo 3: Resolver (Minutos 25 a 45)** | Hechizos de área (AOE), Coloso del Núcleo (5000 HP), supervivencia en 900 s |

---

## 2. Nivel 1 — Cierre de Vacíos Numéricos (4 por Estudiante)

### Tramo 1 (Amado - Guerrero)
1. **Daño de click manual:** Al hacer click sobre la arena o guardia, se inflige 13.5 pts de daño (75% base) y otorga +1 Oro / +1 XP cada 0.25 s.
2. **Escalado de salud de guardias:** `Vida = 25 + (Oleada * 5) HP`. En Oleada 3 = 40 HP.
3. **Experiencia por nivel:** `XP_sig = floor(25 * 1.4^(N-1))`. Nivel 1→2: 25 XP; Nivel 2→3: 35 XP.
4. **Radio de atracción magnética:** `d <= 3.5 m` a una velocidad de atracción de `7.0 m/s`.

### Tramo 2 (Prada - Cazador)
1. **Velocidad de proyectiles:** Proyectiles a `14.0 m/s` con vida máxima de `1.8 s` (alcance útil 25.2 m).
2. **Cofres de arena:** 3 cofres por run, otorgan `40 + (Oleada * 15)` monedas y +1 carta pasiva.
3. **Probabilidad de golpe crítico:** Base 5%, escala +7.5% por carta de Ojo Arcano hasta tope de 65%.
4. **Enfriamiento de disparo:** Cadencia `cd = max(0.2, 0.8 * (0.85^Mejoras))` s.

### Tramo 3 (Angulo - Mago)
1. **Radio de explosión arcana:** Explosión de `3.2 m` de radio infligiendo 35 pts de daño instantáneo.
2. **Vida del Coloso del Núcleo:** `5000 HP` con escudo reflectante de 500 HP cada 90 s.
3. **Temporizador de run:** Límite estricto de `900 s` (15 min / 54 000 cuadros a 60 fps).
4. **Draft de cartas roguelike:** Muestra exactamente 3 opciones ponderadas (45% Común, 35% Rara, 20% Épica).

---

## 3. Nivel 2 — Necesidades Psicológicas Básicas (SDT)

* **Autonomía:** Libertad de seleccionar entre 3 cartas de draft en cada subida de nivel y ruta de navegación en la arena.
* **Competencia:** Retroalimentación inmediata del DPS donde los enemigos pasan de requerir 4 impactos a caer en 1 golpe al optimizar builds.
* **Relación (Necesidad corregida):** Se introduce la regla: *"Si el jugador derrota a 5 guardias seguidos sin sufrir daño, el heraldo de la arena ovaciona con fanfarria sonora y arroja un cofre de bronce adicional en el centro de la arena"*.

---

## 4. Nivel 3 — Curva de Progresión en 6 Pasos (Pico y Respiro)

| Paso | Situación Jugable | Reto / Métrica | Nivel de Habilidad Requerido | Sensación Esperada |
| :---: | :--- | :--- | :---: | :--- |
| **1** | Entrada a la arena | 1 Guardia (25 HP, 2.0 m/s) | 1.0 (Básico) | Seguridad / Aprendizaje |
| **2** | Primera oleada | 2 Guardias (30 HP c/u) | 1.8 (Medio) | Control táctico |
| **3** | Emboscada en pasillo | 4 Guardias + 1 Cazador | 3.2 (Exigente) | Tensión moderada |
| **4** | **PICO:** Mini-jefe Bruto | 1 Bruto (220 HP, carga 4.5 m/s) | **4.6 (Máximo)** | **Adrenalina / Clímax** |
| **5** | **RESPIRO:** Fuente de Maná | 0 enemigos (recupera 50 HP) | 1.2 (Bajo) | Alivio / Gratificación |
| **6** | Transición al Corredor | 3 Guardias de escolta | 2.8 (Estable) | Confianza y preparación |

---

## 5. Nivel 4 — 4 Recompensas y Huecos Temporales

1. **Recompensa 1 (Minuto 2:30):** Primer cofre de arena (+40 Oro).
2. **Recompensa 2 (Minuto 5:00):** Draft de carta Épica al alcanzar Nivel 3.
3. **Recompensa 3 (Minuto 8:15):** Reliquia "Botas de Éter" tras vencer al mini-jefe Bruto (+20% vel. movimiento).
4. **Recompensa 4 (Minuto 10:00):** Desbloqueo del portal de avance hacia la Zona 2.
* **Hueco temporal corregido:** El intervalo entre Minuto 5:00 y 8:15 (3 min 15 s) se dinamizó añadiendo un evento intermedio de anomalía de clicks que otorga gemas de XP cada 60 s.

---

## 6. Documentos Oficiales en Word (.docx)
En esta misma carpeta se encuentran los informes formateados y listos para calificación:
* `Taller_Sesion_4_Jhon_Sebastian_Amado.docx`
* `Taller_Sesion_4_Juan_Sebastian_Prada.docx`
* `Taller_Sesion_4_Juan_Camilo_Angulo.docx`
