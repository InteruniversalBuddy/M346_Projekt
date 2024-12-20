// Version vom 20.12.2024
// Autor: Jaris Streule 
// Zweck: Dieses Skript enthaelt den haupt-Code fuer eine AWS-Lambda-Funktion um CSV-Dateien von einem AWS-S3-Bucket zu JSON-Dateien in einem anderen AWS-S3-Bucket zu konvertieren.
// Abhaengigkeiten: toJson-Skript (neben-Skript fuer die eigentliche Konvertierung)
import { S3 } from '@aws-sdk/client-s3'; 
import { toJson } from './toJson.mjs';
// Variablen
const s3 = new S3();
let bucketNameFromClient;

bucketNameFromClient = process.env.INPUT_BUCKET_NAME; //Umgebungsvariable mit dem Input-Bucket Name, welche im Client-Skript definiert wurde
// Handler der Lambda-Funktion
export const handler = async (event) => {
    console.log('Received event:', JSON.stringify(event, null, 2));

    // Get Name des Buckets welcher den Trigger ausgeloest hat
    const bucket = event.Records[0].s3.bucket.name;

    // nochmals checken ob das wirklich der richtige Bucket ist
    if (bucket !== bucketNameFromClient) {
	console.log("trigger was triggered by wrong bucket");
        console.log("bucket name:", bucket);
        console.log("expected name:", bucketNameFromClient);
        return;
    }
    const key = decodeURIComponent(event.Records[0].s3.object.key.replace(/\+/g, ' ')); // Dateipfad bzw. Name der neu hochgeladenen Datei zusammensetzen
    const params = {
        Bucket: bucket,
        Key: key,
    };
    try {
        console.log("newUpload");
        const { ContentType } = await s3.getObject(params);
        console.log('CONTENT TYPE:', ContentType);
        await toJson(bucket, key); // toJson-Funktion aus toJson-Skript ausfuehren um Datei zu Konvertieren und in einem neuen Bucket zu speichern
        return ContentType;
    } catch (err) {
        console.log(err);
        const message = `Error getting object ${key} from bucket ${bucket}. Make sure they exist and your bucket is in the same region as this function.`;
        console.log(message);
        throw new Error(message);
    }
};
