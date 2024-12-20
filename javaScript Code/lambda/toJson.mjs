// Version vom 20.12.2024
// Autor: Jaris Streule 
// Zweck: Dieses Skript enthaelt den neben-Code fuer eine AWS-Lambda-Funktion um CSV-Dateien von einem AWS-S3-Bucket zu JSON-Dateien in einem anderen AWS-S3-Bucket zu konvertieren.
// Abhaengigkeiten: index-Skript (haupt-Skript fuer den eigentlichen Handler)
import { S3 } from '@aws-sdk/client-s3';
import fs from 'fs'; // NodeJS File-System fuer das editieren von files
import path from 'path';
import { pipeline as streamPipeline } from 'stream'; // Modul um Dateien ueber Streams herunter- und hoch zu laden
import util from 'util';

const delimiterZeichen = ";"; // Zeichen welches benutzt wird um Daten in der CSV-Datei voneinander zu trennen

const s3 = new S3();
const pipeline = util.promisify(streamPipeline);
// Funktion fuer das umwandeln und speichern von CSV- bzw. JSON-Dateien
export const toJson = async (sourceBucket, sourceKey) => {
    const destinationBucket = process.env.OUTPUT_BUCKET_NAME;  // Umgebungsvariable mit dem Output-Bucket Name, welche im Client-Skript definiert wurde
    const destinationKey = sourceKey.slice(0, -4) + '.JSON'; // Dateipfad bzw. Name der neu hochgeladenen Datei mit .JSON anstelle von .CSV als Endung
    try {
        // get die Datei aus dem Input-Bucket
        const fileData = await s3.getObject({
            Bucket: sourceBucket,
            Key: sourceKey,
        });

        // Datei aus dem Input-Bucket im Temporaeren-Ordner der Lambda-Funktion ablegen um sie zu bearbeiten
        const tempFilePath = path.join('/tmp', path.basename(sourceKey)); // neuer Datei-Pfad
        await pipeline(fileData.Body, fs.createWriteStream(tempFilePath)); // via Stream die Datei herunterladen

        const newJsonFilePath = path.join('/tmp', 'data.json'); // neuer Datei-Pfad fuer die JSON-Datei im Temporaeren-Ordner der Lambda-Funktion
        // CSV-Datei zu JSON konvertieren 
        const csvToJson = (csvFilePath, jsonFilePath) => {
            return new Promise((resolve, reject) => {
                // die CSV-Datei auslesen mit Callback-Funktion wobei 'data' jetzt die CSV-Daten sind 
                fs.readFile(csvFilePath, "utf-8", (err, data) => {
                    if (err) {
                        reject("Error reading CSV file:", err);
                        return;
                    }

                    // CSV-Data nach jedem Zeilenumbruch seperieren und alle leeren Zeilen raus filtern
                    const rows = data.split("\n").filter(row => row.trim() !== "");

                    // der erste Eintrag im 'rows'-Array bzw. die erste Zeile der CSV-Data sind die Ueberschriften. Ueberschriften werden in einem neuen Array gespeichert wobei sie wieder seperiert werden.
                    const headers = rows[0].split(delimiterZeichen );

                    // verbleibende Zeilen werden zu Objekten
                    const result = rows.slice(1).map((row) => {
                        const values = row.split(delimiterZeichen );
                        let obj = {};
			// jeder Ueberschrift werden die richtigen Werte zugeordnet
                        headers.forEach((header, index) => {
                            obj[header.trim()] = values[index] ? values[index].trim() : "";
                        });

                        return obj;
                    });

                    // Resultat wird in eine JSON-Datei geschrieben
                    fs.writeFile(jsonFilePath, JSON.stringify(result, null, 2), "utf-8", (err) => {
                        if (err) {
                            reject("Error writing JSON file:", err);
                            return;
                        }
                        resolve(); // Promise wird am Schluss aufgeloest
                    });
                });
            });
        };

        // csvToJson-Funktion aufrufen mit entsprechenden Parameter (Pfad der heruntergeladenen-Datei und Pfad der neuen JSON-Datei in der die Daten nacher sein sollen)
        await csvToJson(tempFilePath, newJsonFilePath);

        // fertige JSON-Datei wird in den Output-Bucket hochgeladen via Stream
        console.log("Files in /tmp:", fs.readdirSync('/tmp'));
        await s3.putObject({
            Bucket: destinationBucket,
            Key: destinationKey,
            Body: fs.createReadStream(newJsonFilePath),
        });

        console.log(`File successfully processed and uploaded to ${destinationBucket}/${destinationKey}`);
        return {
            statusCode: 200,
            body: JSON.stringify('Success!'),
        };
    } catch (error) {
        console.error('Error processing file:', error);
        return {
            statusCode: 500,
            body: JSON.stringify('Error processing file.'),
        };
    }
};
