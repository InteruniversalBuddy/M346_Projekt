// Version vom 20.12.2024
// Autor: Jaris Streule
// Zweck: Dieses Skript enthaelt den neben-Code welcher im haupt-Projekt verwendet wird um csv-Dateien zu JSON-Dateien zu konvertieren.

// Für lokale Tests:
// Stellen Sie sicher, dass Node.js installiert ist (getestet mit v20.11.1.)
// Führen Sie "node convertCsvToJson.js" im Terminal aus
const fs = require("fs");

const csvPath = "../../csvFiles/testCSV1.csv";

const csvToJson = (csvFilePath, jsonFilePath) => {
    return new Promise((resolve, reject) => {
        // die CSV-Datei auslesen mit Callback-Funktion wobei 'data' jetzt die CSV-Daten sind
        fs.readFile(csvFilePath, "utf-8", (err, data) => {
            if (err) {
                reject("Error reading CSV file:", err);
                return;
            }

            // CSV-Data nach jedem Zeilenumbruch seperieren und alle leeren Zeilen raus filtern
            const rows = data.split("\n").filter((row) => row.trim() !== "");

            // der erste Eintrag im 'rows'-Array bzw. die erste Zeile der CSV-Data sind die Ueberschriften. Ueberschriften werden in einem neuen Array gespeichert wobei sie wieder seperiert werden.
            const headers = rows[0].split(delimiterZeichen);

            // verbleibende Zeilen werden zu Objekten
            const result = rows.slice(1).map((row) => {
                const values = row.split(delimiterZeichen);
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

const csvData = fs.readFileSync(csvPath, "utf8");
csvToJson(csvPath, "../../csvFiles/testJSON.JSON");
