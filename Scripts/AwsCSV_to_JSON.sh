#!/bin/bash

# Variablen
LAMBDA_FUNCTION_NAME="CSVtoJSONConverter"
BUCKET_IN=""
BUCKET_OUT=""
DELIMITER=";"

# Ladeanimation
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

# Erstellung der S3 Buckets
create_bucket() {
    local bucket_name=$1
    echo "Erstelle S3 Bucket: $bucket_name..."
    aws s3api create-bucket --bucket "$bucket_name" --region us-east-1 >/dev/null 2>&1 &
    local cmd_pid=$!
    loading_animation $cmd_pid
    if wait $cmd_pid; then
        echo "Bucket $bucket_name erfolgreich erstellt."
        return 0
    else
        echo "Fehler beim Erstellen des Buckets $bucket_name."
        return 1
    fi
}

# Erstellung der Lambda-Funktion zur Konvertierung
create_lambda_function() {
    echo "Erstelle die Lambda-Funktion $LAMBDA_FUNCTION_NAME..."
    cat <<EOF > lambda_function.py
import boto3
import csv
import json
import os

def lambda_handler(event, context):
    s3 = boto3.client('s3')
    bucket_in = os.environ['BUCKET_IN']
    bucket_out = os.environ['BUCKET_OUT']
    delimiter = os.environ['DELIMITER']

    # Datei auslesen
    for record in event['Records']:
        key = record['s3']['object']['key']
        response = s3.get_object(Bucket=bucket_in, Key=key)
        lines = response['Body'].read().decode('utf-8').splitlines()
        
        reader = csv.DictReader(lines, delimiter=delimiter)
        data = [row for row in reader]
        
        json_file = key.replace('.csv', '.json')
        s3.put_object(Body=json.dumps(data), Bucket=bucket_out, Key=json_file)
    
    return {'statusCode': 200, 'body': 'Datei erfolgreich konvertiert!'}
EOF

    zip lambda_function.zip lambda_function.py > /dev/null

    aws lambda create-function \
        --function-name $LAMBDA_FUNCTION_NAME \
        --runtime python3.9 \
        --role arn:aws:iam::966014813882:role/LabRole \
        --handler lambda_function.lambda_handler \
        --zip-file fileb://lambda_function.zip \
        --environment "Variables={BUCKET_IN=$BUCKET_IN,BUCKET_OUT=$BUCKET_OUT,DELIMITER=$DELIMITER}" 2>&1 &

    local cmd_pid=$!
    loading_animation $cmd_pid
    if wait $cmd_pid; then
        echo "Lambda-Funktion erfolgreich erstellt."
        return 0
    else
        echo "Fehler bei der Erstellung der Lambda-Funktion."
        return 1
    fi
}

# Hochladen von Test-CSV-Datei
upload_test_csv() {
    echo "Lade Test-CSV-Datei hoch..."
    cat <<EOF > test_data.csv
ID;Name;Alter
1;Max;30
2;Anna;25
EOF
    aws s3 cp test_data.csv s3://$BUCKET_IN/test_data.csv > /dev/null &
    loading_animation $!
    echo "Testdatei erfolgreich hochgeladen."
}

# Test der Lambda-Funktion
invoke_lambda_function() {
    echo "Lambda-Funktion wird getestet..."
    aws lambda invoke --function-name $LAMBDA_FUNCTION_NAME --payload '{}' response.json > /dev/null &
    loading_animation $!
    echo "Antwort:"
    cat response.json
    echo ""
}

# Hauptprogramm
read -p "Geben Sie den Namen des Input-Buckets ein: " BUCKET_IN
read -p "Geben Sie den Namen des Output-Buckets ein: " BUCKET_OUT
read -p "Geben Sie den Delimiter für die CSV-Datei ein (z.B. ;): " DELIMITER

# Buckets erstellen
create_bucket "$BUCKET_IN" && create_bucket "$BUCKET_OUT"

# Lambda-Funktion erstellen
if create_lambda_function; then
    upload_test_csv
    invoke_lambda_function
else
    echo "Fehler: Lambda-Funktion konnte nicht bereitgestellt werden."
fi
