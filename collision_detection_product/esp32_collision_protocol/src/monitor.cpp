#include <iostream>
#include "monitor.h"

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
#define LED 2 // LED pin on esp32
// Constant strings to send to flutter @sign when appropriate.
#define approximate std::string("PROXIMITY")
#define nothing std::string("NO_PROXIMITY")

void collision_monitor(Monitor cSystem) {
    // Start the serial communication for the sensors
    Serial.begin(115200);
    //  Proximity sensor
    pinMode(LED, OUTPUT); // LED on esp32.
    // digitalWrite(2, HIGH);
    pinMode(cSystem.proxPin, INPUT); // Set the proxPin as Input
    
    // Ultrasonic Sensor
    pinMode(cSystem.trigPin, OUTPUT); // Sets the trigPin as an Output
    pinMode(cSystem.echoPin, INPUT); // Sets the echoPin as an Input 

    // Collision sensor
    pinMode(cSystem.collPin,INPUT);// set collPin as input

    // Initialize the shared data with flutter @sign from esp32 to 
    // "NO_PROXIMITY", as ideally, nothing should be when starting
    cSystem.client->put_ak(*cSystem.putkey, nothing);

    while (true)
    {
        // Check if the Flutter application restarted, thus appp sent string "reset"
        if (reset(cSystem)) {return;}

        // Check if a collision occured
        if(detect_collision(cSystem)) {return;}

        // If the proximity sensor detects something, then determine the distance
        // from esp32 to unidentified object (UO)
        if(presence(cSystem)){
            // Calculate and send the distances to @sign in flutter
            cal_distance(cSystem);
            // If collision occured inside cal_distance(), then check here again
            // without delay!
            if (digitalRead(cSystem.collPin == LOW)) {return;}
            // Check if reset was called earlier in cal_distace:
            if (reset(cSystem)) {return;}
        }
    }
}

// Function checks whether Flutter app called for a reset:
bool reset(Monitor system) {
    if (system.client->get_ak(*system.getkey) == "reset"){
        // Re-initialize the data sent to Flutter app to be "NO_PROXIMITY" 
        system.client->put_ak(*system.putkey, nothing);
        return true;
    }
    else {return false;}
}

// Function checks whether a Collision is detected:
bool detect_collision(Monitor system)
{
    int colState = 0; // set digital variable val for collision sensor
    colState=digitalRead(system.collPin);// read input value from collPin

    if(colState!=HIGH)// Collision sensor detects a signal when LOW
    {
        digitalWrite(LED, LOW); // Light up LED on esp32
        cout << "COLLISION OCCURED! CALL AN AMBULANCE!" << endl;
        const auto value = std::string("COLLISION");
        // Write to Flutter application that collision occured by sending string
        // "COLLISION"
        system.client->put_ak(*system.putkey, value);

        // Flutter app will send string "disabled" in response, but that will
        // take a moment, thus call delay() before exiting method
        // collision_monitor(), so that the new status of monitoring is
        // checked, not the previous ("enabled" or "diabled").
        delay(7000);
        // Re-initialize the data sent to Flutter app to be "NO_PROXIMITY" 
        system.client->put_ak(*system.putkey, nothing);
        return true;
    } else {
        return false;
    }
}

// Function checks if something is within proximity of the proximity sensor:
bool presence(Monitor system) {
    int proxState = 0; // set digital variable val for proximity sensor
    proxState = digitalRead(system.proxPin); // Read the pin of proximity sensor

    // If the proximity sensor detects something, then determine the distance
    // from esp32 to unidentified object (UO)
    if (proxState == LOW) {
        cout << "Something is within Proximity. Record the distances from UO!" << endl;
        // Signal to Flutter app that something is within proximity - send string "PROXIMITY"
        system.client->put_ak(*system.putkey, approximate);
        return true;
    } else {
        cout << "Nothing is within proximity " << endl;
        system.client->put_ak(*system.putkey, nothing);
        return false;
    }
}

// Function calculates distances from Unidentified Object to esp32 and sends
// them to Flutter. Immediately halts if collision were detected.
void cal_distance(Monitor system) {
    long duration; // time a signal returns after emission.
    float distanceCM; // calculated distance in cm, converted from duration
    float distanceInch; // calculated distince in inches, converted from duration
    // distince in meters is calculated as follows:
    // distance = duration * 340 m/s * 0.5.

    // Stop recording distances once nothing is no longer in proximity
    while (digitalRead(system.proxPin) != HIGH)
    {
        // Check if the Flutter application restarted
        if (reset(system)) {return;}

        // Clears the trigPin
        digitalWrite(system.trigPin, LOW);
        delayMicroseconds(2);
        // Sets the trigPin on HIGH state for 10 micor seconds
        digitalWrite(system.trigPin, HIGH);
        delayMicroseconds(10);
        digitalWrite(system.trigPin, LOW);

        // reads the echoPin, returns the sound wave travel time in microseconds
        duration = pulseIn(system.echoPin, HIGH);

        // Calculate the distance in centimeters
        distanceCM = duration * SOUND_SPEED/2;
        // Convert distance to inches
        distanceInch = distanceCM * CM_TO_INCH;

        // Prints the distance in the Serial Monitor
        Serial.print("Distance (cm): ");
        Serial.println(distanceCM);
        Serial.print("Distance (inch): ");
        Serial.println(distanceInch);

        // Put the distance in centimeters to the atServer with the put atkey
        const auto distance = std::to_string(distanceCM);
        system.client->put_ak(*system.putkey, distance);

        // Suspecting that AtSign gets overloaded with new updates to its value, hence
        // delaying it may releive it.
        delay(5000);

        // Check if a collision occured
        if(detect_collision(system)) {return;}
    }
    // Signal to Flutter app that distances are no longer being read, as nothing is within
    // proximity:
    system.client->put_ak(*system.putkey, nothing);
} 