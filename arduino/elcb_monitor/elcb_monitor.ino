#include <WiFi.h>
#include <Firebase_ESP_Client.h>
#include "time.h"

// WiFi Credentials
#define WIFI_SSID "YOUR_WIFI_SSID"
#define WIFI_PASSWORD "YOUR_WIFI_PASSWORD"

// Firebase Project Credentials
#define API_KEY "AIzaSyAspo3Jm7F3YSAmeFyTUmqby5CiYXfMTos"
#define DATABASE_URL "https://miniproject-fc41e-default-rtdb.firebaseio.com/"

// IR Sensor Pin
#define IR_SENSOR 4

FirebaseData fbdo;
FirebaseAuth auth;
FirebaseConfig config;

int prevState = HIGH;

// YOUR USER UID: 6hTgK8xYpQw12AbCdEf345
String uid = "6hTgK8xYpQw12AbCdEf345";

void setup() {
  Serial.begin(115200);
  pinMode(IR_SENSOR, INPUT);

  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  while (WiFi.status() != WL_CONNECTED) {
    delay(1000);
    Serial.println("Connecting...");
  }

  Serial.println("Connected to WiFi");

  config.api_key = API_KEY;
  config.database_url = DATABASE_URL;

  Firebase.begin(&config, &auth);
  Firebase.reconnectWiFi(true);

  // Time sync (for logs)
  // Set offset to your local timezone (e.g., IST +5:30 = 19800 seconds)
  configTime(19800, 0, "pool.ntp.org");
}

void loop() {
  int currentState = digitalRead(IR_SENSOR);

  // 🔴 FIRST TRIP DETECTION
  if (prevState == HIGH && currentState == LOW) {
    Serial.println("TRIPPED (ONCE)");

    Firebase.RTDB.setString(&fbdo, "users/" + uid + "/ELCB_SYSTEM/status", "TRIPPED");

    // Get time and update logs in JSON format for the Flutter app
    struct tm timeinfo;
    if (getLocalTime(&timeinfo)) {
      char dateBuff[12];
      char timeBuff[10];
      strftime(dateBuff, 12, "%Y-%m-%d", &timeinfo);
      strftime(timeBuff, 10, "%H:%M:%S", &timeinfo);

      FirebaseJson logJson;
      logJson.set("status", "TRIPPED");
      logJson.set("date", dateBuff);
      logJson.set("time", timeBuff);

      Firebase.RTDB.pushJSON(&fbdo, "users/" + uid + "/logs", &logJson);
    }
  }

  // 🔁 CONTINUOUS UPDATE
  if (currentState == LOW) {
    Serial.println("STILL TRIPPED");

    Firebase.RTDB.setString(&fbdo, "users/" + uid + "/ELCB_SYSTEM/status", "TRIPPED");

    delay(2000);
  }

  // 🟢 BACK TO NORMAL
  if (prevState == LOW && currentState == HIGH) {
    Serial.println("NORMAL");

    Firebase.RTDB.setString(&fbdo, "users/" + uid + "/ELCB_SYSTEM/status", "NORMAL");
  }

  prevState = currentState;

  delay(200);
}