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


class Monitor {
    public:
        // the AtClient object
        AtClient *client;
        // Communicating AtKeys
        AtKey *getkey; // key esp32 uses to get the value sent from Flutter app
        AtKey *putkey; // key esp32 uses to put value to Flutter app AtSign
        // Sensors:

        // Collision Sensor:
        int collPin; // PIN for collision sensor

        // Proximity Sensor:
        int proxPin; // PIN for proximity sensor

        // UltraSonic Sensor:
        int trigPin;
        int echoPin;

        // Pressure Sensor
        int pressPin;
        Monitor(int coll, int prox, int trig, int echo, int press) {
            collPin = coll;
            proxPin = prox;
            trigPin = trig;
            echoPin = echo;
            pressPin = press;
        }
};

// This function encapsulates the entire monitoring process
// at the esp32 where if a collision is detected, the a
// respective string is sent to the esp32 application.
// Additionally, if an unidentified object (UO) is caught within proximity,
// then distances will be recorded, and all appropriate strings will be
// sent to Flutter. Lastly, the pressure sensor will return its most highest
// value upon a collision even, as well as whether the UO is still within proximity. 
void collision_monitor(Monitor cSystem);


#endif