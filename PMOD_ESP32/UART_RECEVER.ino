#include <WiFi.h>
#include <WebServer.h>
#include <HardwareSerial.h>

// WiFi Credentials
const char* ssid = "test";
const char* password = "12345678";

// UART Configuration for FPGA
const int uartRxPin = 16;
const int uartTxPin = -1; // Not used
const long baudRate = 115200;

// Global Objects
HardwareSerial uartSerial(2);
WebServer server(80);
volatile int fpgaValue = -1;

void handleRoot() {
  String html = "<!DOCTYPE html><html><head><title>FPGA Sensor Data</title>";
  html += "<meta http-equiv='refresh' content='0.25'>";
  html += "<style>";
  html += "body{font-family:Arial,sans-serif;text-align:center;margin-top:50px;font-size:1.5em;background-color:#282c34;color:white;}";
  html += "h1{color:#61dafb;}";
  // CSS for the status light
  html += ".light-indicator{width:100px;height:100px;border-radius:50%;margin:20px auto;border:3px solid #555;}";
  html += ".on{background-color:red;box-shadow:0 0 25px red;}"; // Style for RED light ON
  html += ".off{background-color:#333;}"; // Style for light OFF
  html += "</style>";
  
  html += "</head><body><h1>Live Value from FPGA</h1>";
  html += "<p style='font-size:4em;font-weight:bold;color:#61dafb;'>";
  
  if (fpgaValue < 0) {
    html += "Waiting for data...";
  } else {
    html += String(fpgaValue / 2) + " cm";
  }
  
  html += "</p>";

  // Conditional logic for the light indicator
  html += "<h2>Proximity Alert</h2>";
  if (fpgaValue >= 0 && (fpgaValue / 2) < 10) {
    // If distance < 10 cm, add the 'on' class to the div
    html += "<div class='light-indicator on'></div>";
  } else {
    // Otherwise, add the 'off' class
    html += "<div class='light-indicator off'></div>";
  }
  
  html += "</body></html>";
  server.send(200, "text/html", html);
}

void setup() {
  Serial.begin(115200);
  uartSerial.begin(baudRate, SERIAL_8N1, uartRxPin, uartTxPin);

  WiFi.begin(ssid, password);
  Serial.print("Connecting to WiFi...");
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  Serial.println("\nWiFi Connected!");
  Serial.print("IP Address: ");
  Serial.println(WiFi.localIP());

  server.on("/", handleRoot);
  server.begin();
  Serial.println("HTTP server started.");
}

void loop() {
  if (uartSerial.available() > 0) {
    fpgaValue = uartSerial.read();
    Serial.print("Received from FPGA: ");
    Serial.println(fpgaValue / 2);
  }
  server.handleClient();
}
