# Clicklike

Juego incremental en 2D tipo autobattler desarrollado en **Godot 4**.

## Descripción del Proyecto
Clicklike combina mecánicas de clicker con combate automático y progresión incremental. El jugador selecciona una clase inicial, se enfrenta a oleadas continuas de enemigos, recolecta oro y experiencia mediante clicks y cofres, y desbloquea cartas de mejora y evoluciones de subclase.

## Integrantes del Equipo
* **Parte 1 - Arquitectura Base y Sistemas:** Modelos de datos, recursos de clases y habilidades, componentes de entidad (Health, Hitbox, Hurtbox, Targeting), máquina de estados (FSM) y subsistemas de soporte.
* **Parte 2 - Entidades y Combate:** Jugador, estados de acción, armas y proyectiles, enemigos con escalado por oleadas y lógica de cofres.
* **Parte 3 - Interfaz, Audio e Integración:** HUD principal, modales de selección de cartas y subclase, sintetizador de audio procedimental y escena principal `Main`.

## Características Principales
* **Clases Base y Subclases:** Guerrero, Mago y Arquero, con evoluciones disponibles al nivel 10 (Paladín, Berserker, Archimago, Cronofante, Francotirador y Cazador).
* **Mecánicas de Combate:** Proyectiles con perforación, cortes en abanico y daño de área mágico.
* **Sistema de Niveles (Draft):** Selección de 3 cartas aleatorias al subir de nivel para personalizar las estadísticas.
* **Audio Procedimental:** Generación de efectos de sonido dinámicos en tiempo de ejecución.

## Ejecución
1. Abrir **Godot Engine 4.x**.
2. Importar el proyecto seleccionando el archivo `project.godot`.
3. Ejecutar la escena principal (`res://scenes/Main.tscn`) con `F5`.
