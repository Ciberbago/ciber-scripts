#!/usr/bin/env fish
#
# Vuelca las variables UNIVERSALES de fish de un plugin, como lineas 'set -U'
# listas para volver a aplicarse en otra maquina.
#
# Existe porque plugins como tide guardan su configuracion en variables
# universales, no en un archivo propio. Copiar ~/.config/fish/fish_variables al
# repo no sirve: ahi conviven las de tide con fish_color_*, EDITOR, la lista de
# plugins de fisher y todo lo demas.
#
#   fish scripts/common/fish-dump-universals.fish > dotfiles/common/tide.fish
#
# Sin argumentos captura tide, que es para lo que lo usa el playbook. Se le
# pueden pasar patrones (glob de 'string match'); los que empiezan con '!'
# excluyen en lugar de incluir.
#
# --- Por que los patrones por defecto son estos ---
#
# Se incluye 'tide_*' ademas de '_tide_*'. Casi toda la configuracion de tide
# (colores, iconos, separadores, padding) vive en variables SIN guion bajo
# inicial; con solo '_tide_*' se capturaba nada mas el orden de los segmentos.
#
# Se excluye '_tide_prompt_*' porque ahi tide cachea el prompt YA RENDERIZADO,
# en variables con nombre _tide_prompt_<numero>. Ese texto trae el hostname, la
# hora y el estado de git de la maquina donde se genero, y tide lo regenera
# solo. Versionarlo seria copiar "jaime@archlinux 10:10:51 AM" a las demas
# maquinas. Ojo con el guion bajo del principio: la configuracion publica de
# tide si se llama tide_prompt_* (sin guion) y esa se conserva.
#
# La salida va ordenada a proposito: asi el diff contra el archivo del repo es
# estable y no cambia por el orden en que fish devuelva los nombres.
#
# El encabezado es fijo a proposito. El playbook compara este volcado contra el
# archivo del repo tal cual; si el encabezado mencionara los patrones usados,
# generar el archivo a mano con argumentos distintos dejaria la tarea marcada
# como 'changed' en cada corrida, para siempre.

set -l incluir
set -l excluir
for p in $argv
    if string match -q -- '!*' $p
        set -a excluir (string sub -s 2 -- $p)
    else
        set -a incluir $p
    end
end
test (count $incluir) -eq 0; and set incluir 'tide_*' '_tide_*'
test (count $excluir) -eq 0; and set excluir '_tide_prompt_*'

set -l nombres
for p in $incluir
    set -a nombres (set --names --universal | string match -- $p)
end
for p in $excluir
    test (count $nombres) -eq 0; and break
    set nombres (printf '%s\n' $nombres | string match -v -- $p)
end

echo "# Variables universales de fish. Generado con scripts/common/fish-dump-universals.fish"
echo "# Reaplicar con: fish <este-archivo>"

if test (count $nombres) -eq 0
    echo "# (esta maquina no tiene ninguna variable universal que coincida)"
    exit 0
end

for v in (printf '%s\n' $nombres | sort -u)
    # OJO: aqui hace falta la variable intermedia. No sirve escribir
    #   echo "set -U $v "(string escape -- $$v)
    # porque en fish pegar una cadena a una LISTA hace producto cartesiano: si
    # la variable tiene 4 elementos, eso produce 4 argumentos
    #   'set -U _tide_left_items vi_mode'
    #   'set -U _tide_left_items os'  ...
    # y echo los imprime todos seguidos en la misma linea, dejando el archivo
    # corrupto. Dentro de comillas, "$valores" une la lista con espacios, que es
    # justo lo que espera 'set -U'.
    set -l valores (string escape -- $$v)
    echo "set -U $v $valores"
end
