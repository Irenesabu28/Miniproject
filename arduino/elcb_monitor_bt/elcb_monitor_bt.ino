#include <WiFi.h>
#include <Firebase_ESP_Client.h>
#include "BluetoothSerial.h"
#include "time.h"

// 🆔 Bluetooth Name (Shows up in Phone Settings)
#define BLUETOOTH_NAME "ELCB_DEVICE"

// 📡 IR Sensor Pin
#define IR_SENSOR_PIN 5

// 🔥 Project Credentials (matches flutter android config)
#define API_KEY "AIzaSyAspo3Jm7F3YSAmeFyTUmqby5CiYXfMTos"
#define DATABASE_URL "https://miniproject-fc41e-default-rtdb.firebaseio.com"

// 🛠️ Global Objects
BluetoothSerial SerialBT;
FirebaseData fbdo;
FirebaseAuth auth;
FirebaseConfig config;

// 📝 State Variables
String ssid = "";
String password = "";
String deviceId = "";
bool wifiConfigured = false;
bool firebaseReady = false;
int previousState = HIGH;

// 🕒 Time Setup
const char* ntpServer = "pool.ntp.org";
const long  gmtOffset_sec = 19800; // IST (UTC +5:30)
const int   daylightOffset_sec = 0;

void setup() {
  Serial.begin(115200);
  pinMode(IR_SENSOR_PIN, INPUT_PULLUP);

  // Generate unique Device ID from Mac address
  deviceId = String((uint32_t)ESP.getEfuseMac(), HEX);
  // removed toUpperCase() to match your database screenshot
  
  Serial.println("\n==============================");
  Serial.println("📱 CIRCU-GUARD INITIALIZED");
  Serial.println("🆔 DEVICE ID: " + deviceId);
  Serial.println("==============================\n");

  // Start Bluetooth Serial
  SerialBT.begin(BLUETOOTH_NAME);
  Serial.println("🔵 Bluetooth Ready: " + String(BLUETOOTH_NAME));
  SerialBT.println("DEVICE_ID:" + deviceId); // Echo ID over BT
  Serial.println("💡 Use the App to send WiFi credentials (SSID,PASS)");
}

void loop() {
  // 1. Handle Bluetooth Configuration
  handleBluetooth();
  
  // 2. Handle WiFi Connection
  if (WiFi.status() == WL_CONNECTED) {
    if (!wifiConfigured) {
      Serial.println("\n✅ WiFi Connected!");
      wifiConfigured = true;
      configTime(gmtOffset_sec, daylightOffset_sec, ntpServer);
      initFirebase();
    }
    
    // 3. Monitor Sensor (ONLY after WiFi has been configured once)
    // We allow checking even if firebaseReady is pending so Serial/BT can report it.
    if (wifiConfigured) {
      checkSensor();
    }

    // 4. Periodic Connection Check (Serial Ping)
    static unsigned long lastPing = 0;
    if (millis() - lastPing > 60000) {
      Serial.println("📡 System Status: Device Online (" + deviceId + ")");
      lastPing = millis();
    }
  } else {
    // Attempt background reconnect if we were once configured and not currently connecting
    if (wifiConfigured && (WiFi.status() != WL_IDLE_STATUS)) {
      static unsigned long lastAttempt = 0;
      if (millis() - lastAttempt > 30000) { // 30s interval for stability
        Serial.println("🔄 Reconnecting WiFi...");
        WiFi.begin(ssid.c_str(), password.c_str());
        lastAttempt = millis();
      }
    }
  }

  delay(200);
}

// 🔵 Handle Incoming Bluetooth Data
void handleBluetooth() {
  if (SerialBT.available()) {
    String data = SerialBT.readString();
    data.trim();

    // Expecting format: "SSID,PASSWORD"
    int splitIndex = data.indexOf(',');
    if (splitIndex > 0) {
      ssid = data.substring(0, splitIndex);
      password = data.substring(splitIndex + 1);
      
      Serial.println("📡 Received WiFi via BT: " + ssid);
      WiFi.begin(ssid.c_str(), password.c_str());
    }
  }
}

// 🔥 Initialize Firebase Connection
void initFirebase() {
  config.api_key = API_KEY;
  config.database_url = DATABASE_URL;

  if (Firebase.signUp(&config, &auth, "", "")) {
    Serial.println("🔥 Firebase Authenticated");
    firebaseReady = true;
  } else {
    Serial.printf("❌ Firebase SignUp Error: %s\n", config.signer.signupError.message.c_str());
    firebaseReady = false; 
    // We will still try to begin config below
  }

  Firebase.begin(&config, &auth);
  Firebase.reconnectWiFi(true);
  
  // Send initial state immediately
  sendStatus(digitalRead(IR_SENSOR_PIN) == LOW ? "TRIPPED" : "STABLE");
}

// 📡 Monitor Sensor State
void checkSensor() {
  int currentState = digitalRead(IR_SENSOR_PIN);

  if (currentState != previousState) {
    String status = (currentState == LOW) ? "TRIPPED" : "STABLE";
    Serial.println("\n⚠️ STATUS CHANGED: " + status);
    
    sendStatus(status);
    
    // Log trip event with timestamp
    if (status == "TRIPPED") {
      logToDatabase("TRIPPED");
    }
    
    previousState = currentState;
  }
}

// 📤 Update Realtime Database Status
void sendStatus(String status) {
  if (WiFi.status() != WL_CONNECTED) {
    SerialBT.println("STATUS:" + status); // Send back via Bluetooth if WiFi is down
    return;
  }

  String path = "devices/" + deviceId + "/status";
  if (Firebase.RTDB.setString(&fbdo, path, status)) {
    Serial.println("📤 RTDB → " + status);
  } else {
    Serial.printf("❌ RTDB Update Failed: %s\n", fbdo.errorReason().c_str());
  }
}

// 📝 Push Logs to Database
void logToDatabase(String status) {
  if (WiFi.status() != WL_CONNECTED) return;

  struct tm timeinfo;
  if (!getLocalTime(&timeinfo)) {
    Serial.println("❌ Failed to get NTP time");
    return;
  }

  char dateBuff[12];
  char timeBuff[10];
  strftime(dateBuff, 12, "%Y-%m-%d", &timeinfo);
  strftime(timeBuff, 10, "%H:%M:%S", &timeinfo);

  FirebaseJson json;
  json.set("status", status);
  json.set("date", dateBuff);
  json.set("time", timeBuff);

  String path = "devices/" + deviceId + "/logs";
  if (Firebase.RTDB.pushJSON(&fbdo, path, &json)) {
    Serial.println("📝 Trip Log Saved Successfully");
  } else {
    Serial.println("❌ Logging Failed: " + fbdo.errorReason());
  }
}
