# Surfing the Terminal

*Un compendio personal de tips, trucos y atajos para moverse con fluidez en la terminal (Zsh, Bash, etc).*

---

## Índice

1. [Expansión de comandos](#expansión-de-comandos)
2. [Aliases y funciones útiles](#aliases-y-funciones-útiles)
3. [Historial avanzado](#historial-avanzado)
4. [Mover y renombrar archivos](#mover-y-renombrar-archivos)
5. [Trabajando con rutas](#trabajando-con-rutas)
6. [Tips varios y bonus](#tips-varios-y-bonus)

---

## [1. Expansión de comandos](#expansión-de-comandos)

* `Esc .` o `Alt .` → Pega la última palabra del último comando.
* `!$` → Última palabra del último comando (ej: `cd !$`).
* `!!` → Repetir último comando completo.
* `^old^new` → Reemplaza en el último comando (ej: `^cat^bat`).

---

## [2. Aliases y funciones útiles](#aliases-y-funciones-útiles)

* Crear un alias temporal o permanente en `~/.zshrc`.
* Ejemplo:

```bash
alias gs='git status'
```

* Alias que muestran el comando real antes de ejecutarlo (aprendizaje):

```bash
alias gco='echo git checkout; git checkout'
```

* Excluir algunos alias (como `cat` o `ls`) para no afectar su uso normal.

* Ejemplo de función para imprimir comando original:

```bash
my_alias() {
  echo "Comando real: comando"
  comando "$@"
}
```

---

## [3. Historial avanzado](#historial-avanzado)

* `history` → Ver historial.
* `fc -nl -1` → Último comando ejecutado.
* `!!` → Repetir comando anterior.
* `!grep` → Último comando que comenzó con "grep".
* `^pattern1^pattern2` → Corrección rápida en línea.

---

## [4. Mover y renombrar archivos](#mover-y-renombrar-archivos)

* Mover/renombrar sin repetir ruta:

```bash
mv archivo.txt !#:h
```

Esto usa la ruta de la última palabra.

* Alternativas:

  * `Alt .` para repetir la última palabra.
  * Usar `!$` o alias/función para automatizar.

---

## [5. Trabajando con rutas](#trabajando-con-rutas)

* Pegar última ruta con `Alt .` o `Esc .`
* `pushd` y `popd` para navegar entre carpetas.
* Atajos de Zsh:

  * `~` = home
  * `-` = carpeta anterior (`cd -`)
* Crear symlinks para evitar repetir rutas largas.

---

## [6. Tips varios y bonus](#tips-varios-y-bonus)

* `alias updir='cd !$'` → Saltar al último directorio.

* `mkdir -p` → Crear carpetas sin error si ya existen.

* `rsync` para copias seguras en lugar de `cp`.

* `ls -lh` → Listado legible.

* `du -sh *` → Tamaño de carpetas.

* Usar `setopt interactivecomments` en Zsh para permitir comentarios en línea.

---
### Move to media management

#### Convert images to webp

```bash
for img in lib/imgs/*; do
  cwebp -q 80 "$img" -o "${img%.*}.webp"
done
```

#### Compress images

```bash
for img in lib/imgs/*; do
  convert "$img" -quality 80 "${img%.*}.jpg"
done
```
---

## Notas finales

Este documento está pensado para ser **dinámico y en evolución**. Cada truco que aprendas o descubras lo puedes agregar aquí.

Puedes organizarlo por herramientas (git, tmux, fzf, etc) o por categorías como productividad, navegación, archivos, etc.
