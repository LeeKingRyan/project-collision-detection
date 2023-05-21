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


void collision_monitor(Monitor cSystem) {
    // Start the serial communication for the Ultra sound sensor
    Serial.begin(115200);
    //  Proximity sensor
    pinMode(2, OUTPUT); // LED for proximity sensor
    pinMode(cSystem.proxPin, INPUT);
    int proxState = 0;// set digital variable val for proximity sensor

    // Ultrasonic Sensor
    pinMode(cSystem.trigPin, OUTPUT); // Sets the trigPin as an Output
    pinMode(cSystem.echoPin, INPUT); // Sets the echoPin as an Input

    // Collision sensor
    pinMode(cSystem.collPin,INPUT);// set collision sensor as input
    int colState = 0; // set digital variable val for collision sensor

    // Pressure sensor
    pinMode(cSystem.pressPin, INPUT);


    long duration;
    float distanceCM = 0;
    float distanceInch;

    const auto approximate = std::string("PROXIMITY");
    const auto nothing = std::string("NO_PROXIMITY");
    cout << "Nothing is within proximity " << endl;
  
    cSystem.client->put_ak(*cSystem.putkey, nothing);


    while (true)
    {
        // Check if the Flutter application restarted
        if (cSystem.client->get_ak(*cSystem.getkey) == "reset"){return;}

        // Collision Sensor
        colState=digitalRead(cSystem.collPin);// read value on pin 3 and assign it to val
        if(colState!=HIGH)// when collision sensor detects a signal, LED turns on.
        {
            digitalWrite(2,LOW);
            cout << "COLLISION OCCURED! CALL AN AMBULANCE!" << endl;
            const auto value = std::string("COLLISION");
            // Write to Flutter application that collision occured.
            cSystem.client->put_ak(*cSystem.putkey, value);
            // When the Flutter app restarts, there will be a delay from
            // the Flutter app's side, so the esp32 code has time to
            // start again, so the latest put value is no COLLISION, but
            // "NO_PROXIMITY"
            
            // delay(5000); // better not to delay when need to record pressure right away
            // in emergencies
            break;
        }

        proxState = digitalRead(cSystem.proxPin);
        // if it is, the proxState is HIGH:
        // If the proximity sensor detects something, that is when we
        // call for the ultra sonic sensor to calculate the distance
        // of the object
        if (proxState == LOW) {
            cout << "Something is within Proximity. Record the distances!" << endl;
            cSystem.client->put_ak(*cSystem.putkey, approximate);
        }

        while (proxState != HIGH)
        {
            // Check if the Flutter application restarted
            if (cSystem.client->get_ak(*cSystem.getkey) == "reset"){return;}

            // Clears the trigPin
            digitalWrite(cSystem.trigPin, LOW);
            delayMicroseconds(2);
            // Sets the trigPin on HIGH state for 10 micor seconds
            digitalWrite(cSystem.trigPin, HIGH);
            delayMicroseconds(10);
            digitalWrite(cSystem.trigPin, LOW);

            // reads the echoPin, returns the sound wave travel time in microseconds
            duration = pulseIn(cSystem.echoPin, HIGH);

            // Calculate the distance
            distanceCM = duration * SOUND_SPEED/2;
            // Convert to inches
            distanceInch = distanceCM * CM_TO_INCH;

            // Prints the distance in the Serial Monitor
            Serial.print("Distance (cm): ");
            Serial.println(distanceCM);
            Serial.print("Distance (inch): ");
            Serial.println(distanceInch);

            // Put the distance in inches to the atServer with the atkey
            // The value must be a constant sting value.
            // We create a new constant ever loop
            const auto distance = std::to_string(distanceCM);
            cSystem.client->put_ak(*cSystem.putkey, distance);

            colState=digitalRead(cSystem.collPin);// read value on pin 3 and assign it to val

            if(colState!=HIGH)// when collision sensor detects a signal, LED turns on.
            {
                digitalWrite(2,LOW);
                cout << "COlLISION OCCURED! CALL AN AMBULANCE!" << endl;
                break;
            }

            digitalWrite(2, HIGH);
            proxState = digitalRead(cSystem.proxPin);

            // Send the data in centimetrs to the app
            //at_client->put_ak(*at_key, to_string(distanceCM));

            // delay(1000); don't need delay since encryption and decryption is already
            // slowing down the program's run time

            // Tell the app that nothing has been detected:
            // The Java app will continue having the same
            // latest value of nothing having been within proximity. 
            if (proxState == HIGH)
            {
                cout << "Nothing is within proximity " << endl;
                cSystem.client->put_ak(*cSystem.putkey, nothing);
            }

        } // Inner Most While loop: Something in proximity, thus read distance from UO.
        // or if there's a collision
        digitalWrite(2, LOW);
    } // Outer Most While Loop, checks if there is a collision


    // Part 2: Pressure Sensor

    // Exiting the while loop, means that collision has occured, thus the appliance
    // of pressure needs to be recorded.
    int max_pressure = -1000;
    int pressure = analogRead(cSystem.pressPin);
    int i =  0;
    // Check if the unidentified object that esp32 collided with is still
    // within proximity. The respinding string will be concatenated to the
    // max_pressure value. This will be parsed in the flutter app. 
    std::string aftermath;

    if (proxState == LOW) {
        aftermath = "stuck";
        // Only the highest pressure value will be returned to the Flutter AtSign
        // Sample the first 10 seconds only, so until i = 50.
        // Crash is instantaneous
        while (pressure > 0 && i < 25)
        {
            // Check if the Flutter application restarted
            if (cSystem.client->get_ak(*cSystem.getkey) == "reset"){return;}
            delay(500);
            pressure = analogRead(cSystem.pressPin);
            if (max_pressure < analogRead(cSystem.pressPin)) {
                max_pressure = pressure;
            }
            i++;
        }
        cout << "MAXIMUM PRESSURE IS: \n";
        cout << max_pressure << endl;
        std::string presstr = std::to_string(max_pressure);
        std::string result = aftermath + " " + presstr;
        cout << result << endl;
        cSystem.client->put_ak(*cSystem.putkey, result);
    }
    else {
        aftermath = "bounce";
        // Only the highest pressure value will be returned to the Flutter AtSign
        // Sample the first 10 seconds only, so until i = 50.
        // Crash is instantaneous
        while (pressure > 0 && i < 25)
        {
            // Check if the Flutter application restarted
            if (cSystem.client->get_ak(*cSystem.getkey) == "reset"){return;}
            delay(500);
            pressure = analogRead(cSystem.pressPin);
            if (max_pressure < analogRead(cSystem.pressPin)) {
                max_pressure = pressure;
            }
            i++;
        }
        cout << "MAXIMUM PRESSURE IS: \n";
        cout << max_pressure << endl;
        std::string presstr = std::to_string(max_pressure);
        std::string result = aftermath + " " + presstr;
        cout << result << endl;
        cSystem.client->put_ak(*cSystem.putkey, result);
    }

    // Don't need to check for reset, because reset will call activateMonitor()
    // which will send "active" string, and the code has finshed, and since the
    // FLutter application is delayed a couple seconds after restarting, then
    // the latest put string will still be "NO_PROXIMITY". 
}