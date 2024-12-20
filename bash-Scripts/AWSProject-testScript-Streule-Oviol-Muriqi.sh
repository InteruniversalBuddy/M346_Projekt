#!/bin/bash

# Version vom 20.12.2024
# Autor: Jaris Streule
# Zweck: Dieses Skript kann zum testen des M346-Projekts "Konvertierung von CSV zu JSON" von Jaris Streule / Alexander Oviol Martinez / Arion Muriqi verwendet werden. Es wird eine csv-Datei erstellt, hochgeladen und die entsprechende json Datei gesucht und heruntergeladen

# Variablen
CSV_FILE="test_file.csv" # name der csv-Datei welche zum testen erstellt wird
JSON_FILE="$(basename "$CSV_FILE" .csv).JSON" # name der json-Datei welche gedownloaded wird (zusammengebaut aus dem Namen der csv-Datei und .JSON)

MAX_RETRIES=5 # anzahl an Versuchen beim suchen der json-Datei
RETRY_INTERVAL=2 # anzahl an Sekunden delay nach jedem such-Versuch

INPUT_BUCKET="" # speichern von User-Input
OUTPUT_BUCKET="" # speichern von User-Input

# CSV-Datei erstellen
create_csv_file()
{
	echo -e "\nerstelle '$CSV_FILE'..."

	echo "ID;Nachname;Vorname;Strasse;PLZ;Ort;Tel" > $CSV_FILE
	echo "1;Scheidegger;Urs;Grüttbachstrasse 2;4542;Luterbach;032 682 51 37" >> $CSV_FILE
	echo "2;Buhrfeind;Evi;Grüttbachstrasse 2;4542;Luterbach;032 682 51 27" >> $CSV_FILE
	echo "3;Rüdisühli;Barbara;Rathausgasse;5000;Aarau;062 822 11 35" >> $CSV_FILE
	echo "4;Abbühl;Doris;Stockmattstr.;5000;Aarau;062 824 41 36" >> $CSV_FILE
	# Checken ob es einen Fehler gegeben hat
	if [ $? -eq 0 ]; then
		echo "$CSV_FILE erstellt"
		return 0
	else
		echo -e "\nFehler: '$CSV_FILE' konnte nicht erstellt werden"
		exit 1
	fi
}

# Hochladen der CSV-Datei in den Input-Bucket
upload_csv_file()
{
	echo -e "\nlade '$CSV_FILE' zu $INPUT_BUCKET hoch..."
	aws s3 cp $CSV_FILE s3://$INPUT_BUCKET/ >/dev/null
    	# Checken ob es einen Fehler seitens AWS gegeben hat
	if [ $? -eq 0 ]; then
		echo "'$CSV_FILE' erfolgreich zu '$INPUT_BUCKET' hochgeladen."
		return 0
	else
		echo -e "\nFehler: Datei konnte nicht in den Input-Bucket '$INPUT_BUCKET' hochgeladen werden."
		exit 1
	fi
}

# Warten auf Verarbeitung der CSV-Datei durch die Lambda-Funktion und Download der JSON-Datei
download_json_file()
{
	echo -e "\nsuche '$JSON_FILE' in '$OUTPUT_BUCKET'..."
	FILE_FOUND=false # boolean ob die Datei gefunden wurde
	RETRY_COUNT=0 # counter für die while Schleife
	while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
		# versuchen die json-Datei zu finden
	  	aws s3 ls s3://$OUTPUT_BUCKET/$JSON_FILE > /dev/null
		# falls die json-Datei noch nicht erstellt wurde, wird gewartet und erneut gesucht
		if [ $? -eq 0 ]; then
			FILE_FOUND=true
			echo "'$JSON_FILE' wurde gefunden"
			break
  		else
			echo "Suche läuft... Warte $RETRY_INTERVAL Sekunden."
		  	sleep $RETRY_INTERVAL
		  	RETRY_COUNT=$((RETRY_COUNT + 1))
  		fi
		done
	# wird die json-Datei nach der definierten Zeit nicht gefunden
	if [ "$FILE_FOUND" = false ]; then
	  	echo -e "\nFehler: '$JSON_FILE' wurde in '$OUTPUT_BUCKET' nicht gefunden."
	  	exit 1
	fi

	echo -e "\nLade $JSON_FILE herunter..."
	# herunterladen der JSON-Datei aus dem Output-Bucket
	aws s3 cp s3://$OUTPUT_BUCKET/$JSON_FILE ./ >/dev/null
	# Checken ob es einen Fehler seitens AWS gegeben hat
	if [ $? -eq 0 ]; then
		echo "'$JSON_FILE' erfolgreich heruntergeladen"
		exit 0
	else
	  	echo -e "\nFehler: '$JSON_FILE' konnte nicht von '$OUTPUT_BUCKET' heruntergeladen werden."
	  	exit 1
	fi
}

# Hauptprogramm
echo "Starte das Skript zum Testen der CSV-Konvertierungs Infrastruktur..."

# auswaehlen der Buckets
echo -e "\n"
read -p "Geben Sie den Namen des zu testenden Input-Buckets ein: " INPUT_BUCKET
echo -e "\n"
read -p "Geben Sie den Namen des zu testenden Output-Buckets ein: " OUTPUT_BUCKET

# erstellung der csv-Datei
create_csv_file

# upload der csv-Datei
upload_csv_file

# download der json-Datei 
download_json_file
