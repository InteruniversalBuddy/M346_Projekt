#!/bin/bash

# Version vom 20.12.2024
# Autor: Alexander Oviol Martinez / Jaris Streule 
# Zweck: Dieses Skript erstellt zusammen mit der richtigen Zip-Datei eine AWS Bucket- und Lambda-Infrastruktur um CSV-Dateien zu JSON-Dateien zu konvertieren.

# Variablen
LAMBDA_ZIP_FILE="awsProjectLambdaCode.zip"  # Name der ZIP-Datei mit dem JavaScript-Code fuer die Lambda-Funktion

INPUT_BUCKET="" # speichern von User-Input
OUTPUT_BUCKET="" # speichern von User-Input
LAMBDA_FUNCTION_NAME="" # speichern von User-Input
ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text) 
LABROLE="arn:aws:iam::$ACCOUNT_ID:role/LabRole" # Die ARN der LabRole aus 'ACCOUNT_ID' und anderen Parametern

# checken ob die LabRole fuer den User existiert (wird benoetigt)
check_lab_role() {
    echo -e "\nÜberprüfen, ob LabRole existiert..."
    if aws iam get-role --role-name LabRole >/dev/null; then
        echo "LabRole existiert."
        return 0
    else
        echo -e "\nFehler: LabRole wurde nicht gefunden - bitte Credentials überprüfen"
        exit 1
    fi
}

# wiederverwendbare Funktion um S3 Buckets zu erstellen
create_bucket() {
    local bucket_name=$1 # Parameter fuer den Bucket-Namen
    echo "Erstelle S3 Bucket: '$bucket_name'..."
    aws s3api create-bucket --bucket "$bucket_name" >/dev/null
    # Checken ob es einen Fehler seitens AWS gegeben hat
    if [ $? -eq 0 ]; then
        echo "Bucket '$bucket_name' erfolgreich erstellt."
        return 0
    else
        echo -e "\nFehler: beim Erstellen des Buckets '$bucket_name' gab es ein Problem."
        exit 1
    fi
}

# Lambda-Funktion erstellen
create_lambda_function() {
    echo "Erstelle die Lambda-Funktion '$LAMBDA_FUNCTION_NAME'..."
    # checken ob die ZIP-Datei mit dem Code fuer die Lambda-Funktion existiert
    if [ ! -f "$LAMBDA_ZIP_FILE" ]; then
        echo -e "\nFehler: Die Datei '$LAMBDA_ZIP_FILE' wurde nicht gefunden!"
        exit 1
    fi

    aws lambda create-function \
        --function-name $LAMBDA_FUNCTION_NAME \
        --runtime nodejs18.x \
        --role $LABROLE \
        --handler index.handler \
        --environment "Variables={INPUT_BUCKET_NAME= $INPUT_BUCKET,OUTPUT_BUCKET_NAME= $OUTPUT_BUCKET}" \
        --zip-file fileb://$LAMBDA_ZIP_FILE \
         >/dev/null
    # Checken ob es einen Fehler seitens AWS gegeben hat
    if [ $? -eq 0 ]; then
        echo "Lambda-Funktion '$LAMBDA_FUNCTION_NAME' erfolgreich erstellt."
        return 0
    else
        echo -e "\nFehler: bei der Erstellung der Lambda-Funktion gab es ein Problem."
        exit 1
    fi
}

# Trigger auf den Input-Bucket hinzufuegen fuer die Lambda-Funktion
add_s3_trigger() {
    local bucket_name=$1 # Parameter fuer den Bucket-Namen
    echo -e "\nFüge S3-Trigger für Bucket '$bucket_name' zur Lambda-Funktion hinzu..."
    
    # Dynamisch die Lambda-ARN zusammensetzen aus der ACCOUNT_ID und dem Namen der Lambda-Funktion
    LAMBDA_ARN="arn:aws:lambda:$(aws configure get region):$ACCOUNT_ID:function:$LAMBDA_FUNCTION_NAME"
    # der Lambda-Funktion Berechtigungen hinzufuegen fuer Zugriff auf Input-Bucket  
    aws lambda add-permission \
        --function-name $LAMBDA_FUNCTION_NAME \
        --action lambda:InvokeFunction \
        --principal s3.amazonaws.com \
        --source-arn arn:aws:s3:::$bucket_name \
        --statement-id S3TriggerPermission \
        >/dev/null
    # Checken ob es einen Fehler seitens AWS gegeben hat
    if [ $? -eq 0 ]; then
        echo "Berechtigungen erfolgreich hinzugefügt."
    else
        echo -e "\nFehler: beim hinzufügen der Berechtigungen gab es ein Problem."
        exit 1
    fi
    # der Lambda-Funktion den Trigger hinzufuegen
    aws s3api put-bucket-notification-configuration \
        --bucket $bucket_name \
        --notification-configuration '{
            "LambdaFunctionConfigurations": [
                {
                    "LambdaFunctionArn": "'$LAMBDA_ARN'",
                    "Events": ["s3:ObjectCreated:*"]
                }
            ]
        }' \
        >/dev/null
    # Checken ob es einen Fehler seitens AWS gegeben hat
    if [ $? -eq 0 ]; then
        echo "S3-Trigger für Bucket '$bucket_name' erfolgreich hinzugefügt."
        return 0
    else
        echo -e "\nFehler: beim hinzufügen des S3-Triggers gab es ein Problem."
        exit 1
    fi
}

# Hauptprogramm
echo "Starte das Skript zur Erstellung von Buckets und Lambda-Funktion für CSV-Konvertierung..."

# LabRole checken
check_lab_role

# Erstellen der Buckets
echo -e "\n"
read -p "Geben Sie den Namen des neuen Input-Buckets ein: " INPUT_BUCKET
create_bucket "$INPUT_BUCKET"

echo -e "\n"
read -p "Geben Sie den Namen des neuen Output-Buckets ein: " OUTPUT_BUCKET
create_bucket "$OUTPUT_BUCKET"

# Lambda-Funktion erstellen
echo -e "\n"
read -p "Geben Sie den Namen der neuen Lambda-Funktion ein: " LAMBDA_FUNCTION_NAME
if create_lambda_function; then
    # Trigger nur fuer den Input-Bucket hinzufuegen
    add_s3_trigger "$INPUT_BUCKET"
    echo -e "\nDie Lambda-Funktion und Buckets wurden erfolgreich erstellt und miteinander verknüpft!"
    exit 0
fi
