#!/bin/bash

# Funktion zur Ladeanimation
loading_animation() {
    local pid=$1 # Prozess-ID des laufenden Kommandos
    local delay=0.1
    local spinstr='|/-\'
    echo -n " "
    while [ -d /proc/$pid ]; do
        local temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    echo "   " # Löscht die Animation
}

# Funktion zur Erstellung eines Buckets mit Fehlerausgabe
create_bucket() {
    local bucket_name=$1
    echo "Versuche, den Bucket $bucket_name zu erstellen..."
    
    # Führt das AWS-Kommando aus und erfasst Fehlerausgabe
    aws s3api create-bucket --bucket "$bucket_name" 2>&1 &
    
    local cmd_pid=$! # Speichert die Prozess-ID des aws-Kommandos
    loading_animation $cmd_pid # Startet die Ladeanimation

    # Prüfen, ob das Kommando erfolgreich war
    if wait $cmd_pid; then
        echo "Bucket $bucket_name wurde erfolgreich erstellt."
        return 0
    else
        echo "Fehler: Der Bucket-Name $bucket_name konnte nicht erstellt werden."
        return 1
    fi
}

# Hauptprogramm: Bucket-Namen abfragen und erstellen
while true; do
    # Benutzer nach einem Bucket-Namen fragen
    read -p "Bitte geben Sie einen eindeutigen Bucket-Namen ein: " BUCKET_NAME

    # Bucket erstellen und prüfen, ob es funktioniert hat
    if create_bucket "$BUCKET_NAME"; then
        break # Bucket erfolgreich erstellt, Schleife verlassen
    else
        echo "Bitte wählen Sie einen anderen Bucket-Namen."
    fi
done
