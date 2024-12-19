#!/bin/bash

# Funktion zur Ladeanimation
loading_animation() {
    local pid=$1
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
    echo "   "
}

# Funktion zur Erstellung eines S3-Buckets
create_bucket() {
    local bucket_name=$1
    echo "Versuche, den Bucket $bucket_name zu erstellen..."
    aws s3api create-bucket --bucket "$bucket_name" 2>&1 &
    local cmd_pid=$!
    loading_animation $cmd_pid

    if wait $cmd_pid; then
        echo "Bucket $bucket_name wurde erfolgreich erstellt."
        return 0
    else
        echo "Fehler: Der Bucket-Name $bucket_name konnte nicht erstellt werden."
        return 1
    fi
}

# Funktion zur Erstellung einer Test-Lambda-Funktion
create_lambda_function() {
    echo "Erstelle die Lambda-Funktion 'TestLambdaFunction'..."

    # Erstelle Python-Code für die Lambda-Funktion
    cat <<EOF > lambda_function.py
import json

def lambda_handler(event, context):
    return {
        'statusCode': 200,
        'body': json.dumps('Hallo von der Test-Lambda-Funktion!')
    }
EOF

    # ZIP-Datei erstellen
    zip lambda_function.zip lambda_function.py > /dev/null

    # Lambda-Funktion erstellen
    aws lambda create-function \
        --function-name TestLambdaFunction \
        --runtime python3.9 \
        --role arn:aws:iam::966014813882:role/LabRole \
        --handler lambda_function.lambda_handler \
        --zip-file fileb://lambda_function.zip 2>&1 &
    
    local cmd_pid=$!
    loading_animation $cmd_pid

    if wait $cmd_pid; then
        echo "Lambda-Funktion wurde erfolgreich erstellt."
        return 0
    else
        echo "Fehler: Lambda-Funktion konnte nicht erstellt werden."
        return 1
    fi
}

# Funktion zum Testen der Lambda-Funktion
invoke_lambda_function() {
    echo "Teste die Lambda-Funktion 'TestLambdaFunction'..."
    aws lambda invoke \
        --function-name TestLambdaFunction \
        --payload '{}' \
        response.json > /dev/null
    
    if [ $? -eq 0 ]; then
        echo "Lambda-Antwort:"
        cat response.json
        echo ""
        rm response.json
        return 0
    else
        echo "Fehler: Lambda-Funktion konnte nicht ausgeführt werden."
        return 1
    fi
}

# Hauptprogramm
while true; do
    # Schritt 1: Bucket-Namen abfragen
    read -p "Bitte geben Sie einen eindeutigen Bucket-Namen ein: " BUCKET_NAME
    if create_bucket "$BUCKET_NAME"; then
        break
    else
        echo "Bitte wählen Sie einen anderen Bucket-Namen."
    fi
done

# Schritt 2: Lambda-Funktion erstellen
if create_lambda_function; then
    echo "Lambda-Funktion erfolgreich bereitgestellt!"
else
    echo "Lambda-Funktion konnte nicht bereitgestellt werden."
    exit 1
fi

# Schritt 3: Lambda-Funktion ausführen
invoke_lambda_function
