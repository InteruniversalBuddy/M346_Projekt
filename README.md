# - Einleitung -
## Ziele
---
1. Mittels zwei [AWS](https://awsacademy.instructure.com/) S3-Buckets (In & Out) und einer [AWS](https://awsacademy.instructure.com/) Lamda-Funktion, die CSV-Datei(en) automatisch zu einer JSON-Datei konvertiert und speichert.
2. Dies soll durch Ausführung eines Scripts, welches auf einem Linux-Client im [AWS](https://awsacademy.instructure.com/) Learner-Lab in Betrieb genommen werden kann, geschehen.
3.  Alle benötigte Dateien und die Dokumentation wird in einem Git-Repository abgelegt.
4. Die Dokumentation wird in einer Markdown Datei geschrieben und zeigt den Aufbau des services & die Inbetriebnahme + Verwendung.
5. Der Service wird getestet und die Testfälle werden alle Dokumentiert (via Screenshots).
## Gruppenaufteilung
---
### Jaris Streule
#### Hauptaufgabe
- Erstellung der Funktionalität.
#### Aufgaben Checkliste
- [ ] Erstellt die erste Version des JavaScript-Code für die Konvertierung von CSV zu JSON.
- [ ] Erstellt die zweite Version des JavaScript-Code mit Lamda-Funktion.
### Alexander Oviol Martinez
#### Hauptaufgabe
- Scripts für die Infrastruktur erstellen.
#### Aufgaben Checkliste
- [ ] Lernt wie man automatisch Buckets erstellen kann, welche für die Lamda Funktion verwendet werden.
### Arion Muriqi
#### Hauptaufgabe
- Dokumentation des ganzen Projektes.
#### Aufgaben Checkliste
- [x] Erstellt das GitHub-Repository auf seinem privaten GitHub-Account.
- [x] Fügt Alexander Oviol Martinez & Jaris Streule als Kollaboratoren im GitHub Projekt hinzu.
- [x] Erstellt eine README.md Datei, für die Dokumentation.
- [ ] Dokumentation: Einleitung

# - Erstellung des Projekts -
## Convert JSON to CSV (JavaScript)
Zuerst wird der Pfad definiert, in welchem sich die Input (CSV) & Output (JSON) Datei befindet.
```js
const fs = require("fs");

const csvPath = "../../csvFiles/testCSV1.csv";
```

Danach wird eine Funktion erstellt um CSV zu JSON konvertieren.
```js
function csvToJson(csvFilePath, jsonFilePath) {
```

Zuerst wird geschaut ob die gegebene CSV Datei, ausgelesen werden kann.
```js
if (err) {
    console.error("Error reading CSV file:", err);
    return;
}
```

Als nächstes werden die Regeln für den Header und die Trennung der Werte definiert.
```js
const rows = data.split("\n");

const headers = rows[0].split(";");

const result = rows.slice(1).map((row) => {
    const values = row.split(";");
    let obj = {};
```

Zum Schluss werden die Daten ausgelesen und von der Funktion zurückgegeben.

```js
			return obj;
        });

        fs.writeFile(jsonFilePath, JSON.stringify(result, null, 2), "utf-8", (err) => {
            if (err) {
                console.error("Error writing JSON file:", err);
                return;
            }
        });
    });
}
```

Dann wird die CSV Datei gelesen und die Funktion mit den richtigen Parametern ausgeführt.

```js
const csvData = fs.readFileSync(csvPath, "utf8");
csvToJson(csvPath, "../../csvFiles/testJSON.JSON");
```

# - Testen -
