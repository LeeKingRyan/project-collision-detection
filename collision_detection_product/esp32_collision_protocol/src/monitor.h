#ifndef MONITOR_H
#define MONITOR_H

#include <Arduino.h>
#include <WiFiClientSecure.h>
#include <SPIFFS.h>
#include "at_client.h"
#include <string>
#include "constants.h"
using namespace std;

// define sound speed in cm/uS
#define SOUND_SPEED 0.034 
#define CM_TO_INCH 0.393701

// Class that holds the get and put AtKeys for esp32, and the
// pins that the collision, proximity, and ultrasonic sensors
// connect to on the esp32.
class Monitor {
    public:
        // the AtClient object
        AtClient *client;
        // Communicating AtKeys
        AtKey *getkey; // key esp32 uses to get the value sent from Flutter app
        AtKey *putkey; // key esp32 uses to put value to Flutter app AtSign
        
        // Sensors:

        // Collision Sensor:
        int collPin; // signal PIN for collision sensor

        // Proximity Sensor:
        int proxPin; // signal PIN for proximity sensor

        // UltraSonic Sensor:
        int trigPin; // PIN to activate trigger sensor to transmit 40KHZ square waves, 
                     // and automatically detect where there is a signal to return 
        int echoPin; // PIN to recievie a distance, converted from the duration of emission
                     // to recption of ultrasonic, in meters.

        // Pressure Sensor
        int pressPin;

        // Constructor for Monitor Class: initializes pins the sensors connect to on the esp32
        Monitor(int coll, int prox, int trig, int echo, int press) {
            collPin = coll;
            proxPin = prox;
            trigPin = trig;
            echoPin = echo;
            pressPin = press;
        }
};

// This function encapsulates the entire monitoring process
// at the esp32 where if a collision is detected, then a
// respective string is sent to the @sign in the flutter application.
// Additionally, if an unidentified object (UO) is caught within proximity,
// then distances will be recorded, and all appropriate distance (cm) strings will be
// sent to Flutter.
void collision_monitor(Monitor cSystem);

// Function checks whether Flutter app called for a reset:
bool reset(Monitor system);

// Function checks whether a Collision is detected:
bool detect_collision(Monitor system);

// Function checks if something is within proximity of the proximity sensor,
// and sends appropriate strings, either "PROXIMITY" or "NO_PROXIMITY", appropriately
bool presence(Monitor system);

// Function calculates distances from Unidentified Object to esp32 and sends
// them to Flutter. Immediately halts if collision were detected.
void cal_distance(Monitor system);


#endif