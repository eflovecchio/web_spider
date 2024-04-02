#!/bin/bash

if [ "$#" -ne 1 ]; then
    echo "Uso: $0 <nombre_del_archivo>"
    exit 1
fi

archivo="$1"  # Ruta al archivo que contiene la lista de URLs

# Verificar si gospider está instalado
if ! command -v gospider &> /dev/null; then
    echo "Error: gospider no está instalado. Por favor, instala gospider antes de ejecutar este script."
    exit 1
fi

# Bucle para ejecutar gospider para cada URL en el archivo
while IFS= read -r url || [[ -n "$url" ]]; do
    # Extraer la dirección IP y el puerto de la URL
    ip_port=$(echo "$url" | awk -F[/:] '{print $4 "_" $5}')

    # Reemplazar caracteres especiales en el nombre del archivo
    nombre_archivo=$(echo "$ip_port" | sed 's/[^a-zA-Z0-9]/_/g')  # Convertir caracteres especiales en guiones bajos

    # Eliminar "/" después de la IP o del puerto
    nombre_archivo=$(echo "$nombre_archivo" | sed 's@/_@_@')

    # Ejecutar gospider y guardar solo las URLs en el archivo personalizado
    gospider -s "$url" -c 10 -t 20 --depth 4 | grep -oE "http[^]]+" | grep "$url" | sort -u > "${nombre_archivo}_spider.txt"

    # Concatenar todas las URLs en un archivo "spider_todo.txt"
    cat "${nombre_archivo}_spider.txt" >> "spider_todo.txt"

    # Realizar un grep para buscar el carácter "?" en el archivo y guardar en un archivo de parámetros si se encontraron resultados
    if grep -q "?" "${nombre_archivo}_spider.txt"; then
        grep "?" "${nombre_archivo}_spider.txt" > "${nombre_archivo}_parametros.txt"
        
        # Guardar todos los resultados en un archivo "parametros_url.txt"
        cat "${nombre_archivo}_parametros.txt" >> "parametros_url.txt"
        
        # Eliminar el archivo individual de parámetros si está vacío
        if [ ! -s "${nombre_archivo}_parametros.txt" ]; then
            rm -f "${nombre_archivo}_parametros.txt"
        fi
    fi

done < "$archivo"

# Eliminar la carpeta "txt" si está vacía
if [ -d "txt" ]; then
    rm -rf "txt"
fi

# Ordenar y eliminar duplicados en parametros_url.txt
sort -u -o "parametros_url.txt" "parametros_url.txt"

# Ordenar y eliminar duplicados en spider_todo.txt
sort -u -o "spider_todo.txt" "spider_todo.txt"
