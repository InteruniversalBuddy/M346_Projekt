// For testing localy:
// Make sure you have nodejs installed (tested on v20.11.1.)
// Exectute "node convertCsvToJson.js" in the terminal
const fs = require("fs");

const csvPath = "../../csvFiles/testCSV1.csv";

const csvToJson = (csvFilePath, jsonFilePath) => {
    return new Promise((resolve, reject) => {
        // Read the CSV file
        fs.readFile(csvFilePath, "utf-8", (err, data) => {
            if (err) {
                reject("Error reading CSV file:", err);
                return;
            }

            // Split the CSV data by rows
            const rows = data.split("\n");

            // Get the header (first row)
            const headers = rows[0].split(";");

            // Process the remaining rows and convert them into objects
            const result = rows.slice(1).map((row) => {
                const values = row.split(";");
                let obj = {};

                headers.forEach((header, index) => {
                    obj[header.trim()] = values[index] ? values[index].trim() : "";
                });

                return obj;
            });

            // Write the result into a JSON file
            fs.writeFile(jsonFilePath, JSON.stringify(result, null, 2), "utf-8", (err) => {
                if (err) {
                    reject("Error writing JSON file:", err);
                    return;
                }
                resolve(); // Resolve the promise when done
            });
        });
    });
};

const csvData = fs.readFileSync(csvPath, "utf8");
csvToJson(csvPath, "../../csvFiles/testJSON.JSON");
