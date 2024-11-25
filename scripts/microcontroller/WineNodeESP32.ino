#include <WiFi.h>
#include <HTTPClient.h>
#include <ArduinoJson.h>
#include <EEPROM.h>
#include <SHA256.h>
#include <time.h>

// Configuración básica
const char* ssid = "WineBlockchain";
const char* password = "wine_secure_network";
const char* ntpServer = "pool.ntp.org";
const long  gmtOffset_sec = 0;
const int   daylightOffset_sec = 3600;

// Configuración del nodo
String nodeId;
const int MEMORY_SIZE = 4096;  // 4KB para almacenar eventos
const int MAX_EVENTS = 50;     // Número máximo de eventos en memoria

// Estructura para eventos
struct Event {
    char bottleId[32];
    char eventType[16];
    char hash[65];    // SHA256 hash en formato string (64 chars + null terminator)
    uint32_t timestamp;
    uint16_t prevEventIndex;
};

// Variables globales
Event events[MAX_EVENTS];
int currentEventIndex = 0;
int totalEvents = 0;

// Clase para manejar la cadena de eventos
class EventChain {
private:
    SHA256 sha256;
    
    String calculateHash(const Event& event) {
        sha256.reset();
        sha256.update(event.bottleId, strlen(event.bottleId));
        sha256.update(event.eventType, strlen(event.eventType));
        sha256.update((uint8_t*)&event.timestamp, sizeof(event.timestamp));
        if (event.prevEventIndex >= 0) {
            sha256.update(events[event.prevEventIndex].hash, 64);
        }
        uint8_t result[32];
        sha256.finalize(result, 32);
        
        // Convertir hash a string hexadecimal
        char hashString[65];
        for (int i = 0; i < 32; i++) {
            sprintf(hashString + (i * 2), "%02x", result[i]);
        }
        return String(hashString);
    }

public:
    bool addEvent(const char* bottleId, const char* eventType) {
        if (totalEvents >= MAX_EVENTS) {
            // Rotación circular de eventos
            currentEventIndex = (currentEventIndex + 1) % MAX_EVENTS;
        } else {
            totalEvents++;
        }

        Event& newEvent = events[currentEventIndex];
        strncpy(newEvent.bottleId, bottleId, 31);
        strncpy(newEvent.eventType, eventType, 15);
        newEvent.timestamp = getTime();
        newEvent.prevEventIndex = (currentEventIndex - 1 + MAX_EVENTS) % MAX_EVENTS;

        String hash = calculateHash(newEvent);
        strncpy(newEvent.hash, hash.c_str(), 64);
        
        return true;
    }

    bool verifyChain() {
        for (int i = 1; i < totalEvents; i++) {
            int idx = (currentEventIndex - i + MAX_EVENTS) % MAX_EVENTS;
            Event& event = events[idx];
            String calculatedHash = calculateHash(event);
            if (String(event.hash) != calculatedHash) {
                return false;
            }
        }
        return true;
    }
};

EventChain chain;

// Funciones de utilidad
uint32_t getTime() {
    time_t now;
    time(&now);
    return (uint32_t)now;
}

void setupWiFi() {
    WiFi.begin(ssid, password);
    while (WiFi.status() != WL_CONNECTED) {
        delay(500);
        Serial.print(".");
    }
    Serial.println("\nConnected to WiFi");
    
    // Configurar NTP
    configTime(gmtOffset_sec, daylightOffset_sec, ntpServer);
}

void generateNodeId() {
    uint8_t mac[6];
    WiFi.macAddress(mac);
    char nodeIdBuffer[13];
    sprintf(nodeIdBuffer, "%02X%02X%02X%02X%02X%02X", mac[0], mac[1], mac[2], mac[3], mac[4], mac[5]);
    nodeId = String(nodeIdBuffer);
}

// Funciones de comunicación con la blockchain
bool reportEventToBlockchain(const Event& event) {
    if (WiFi.status() != WL_CONNECTED) {
        return false;
    }

    HTTPClient http;
    http.begin("http://blockchain-node:8888/v1/chain/push_transaction");
    http.addHeader("Content-Type", "application/json");

    StaticJsonDocument<512> doc;
    doc["node_id"] = nodeId;
    doc["bottle_id"] = event.bottleId;
    doc["event_type"] = event.eventType;
    doc["timestamp"] = event.timestamp;
    doc["hash"] = event.hash;

    String jsonString;
    serializeJson(doc, jsonString);

    int httpResponseCode = http.POST(jsonString);
    http.end();

    return httpResponseCode == 200;
}

void synchronizeWithPeers() {
    // Implementar sincronización P2P con otros nodos microcontroladores
    // Esto se hará en una fase posterior
}

// Setup y loop principal
void setup() {
    Serial.begin(115200);
    
    // Inicializar EEPROM
    EEPROM.begin(MEMORY_SIZE);
    
    // Configurar WiFi y generar ID del nodo
    setupWiFi();
    generateNodeId();
    
    Serial.println("Node ID: " + nodeId);
}

void loop() {
    // Procesar comandos seriales para testing
    if (Serial.available()) {
        String command = Serial.readStringUntil('\n');
        if (command.startsWith("ADD ")) {
            // Formato: ADD bottleId eventType
            int spaceIndex = command.indexOf(' ', 4);
            if (spaceIndex > 0) {
                String bottleId = command.substring(4, spaceIndex);
                String eventType = command.substring(spaceIndex + 1);
                
                if (chain.addEvent(bottleId.c_str(), eventType.c_str())) {
                    Serial.println("Event added successfully");
                    
                    // Reportar a la blockchain principal
                    if (reportEventToBlockchain(events[currentEventIndex])) {
                        Serial.println("Event reported to blockchain");
                    } else {
                        Serial.println("Failed to report event");
                    }
                } else {
                    Serial.println("Failed to add event");
                }
            }
        } else if (command == "VERIFY") {
            if (chain.verifyChain()) {
                Serial.println("Chain verification successful");
            } else {
                Serial.println("Chain verification failed");
            }
        }
    }

    // Sincronización periódica
    static unsigned long lastSync = 0;
    if (millis() - lastSync > 300000) { // Cada 5 minutos
        synchronizeWithPeers();
        lastSync = millis();
    }

    delay(100);
}
