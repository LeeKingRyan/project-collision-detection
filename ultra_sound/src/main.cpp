#include <Arduino.h>
#include <WiFiClientSecure.h>
#include <SPIFFS.h>
#include "at_client.h"
#include <string>
#include "constants.h"
using namespace std;

const int trigPin = 5;
const int echoPin = 18;

// define sound speed in cm/uS
#define SOUND_SPEED 0.034 
#define CM_TO_INCH 0.393701

long duration;
float distanceCM = 0;
float distanceInch;

// collision sensor
int Led=2;// set pin for LED 
int Shock=34;// set pin for collision sensor
int val;// set digital variable val
////////////////////////////////////////////

// Proximity Sensor
const int sensorPin = 12; // the number of the sensor pin
int sensorState = 0; // variable for reading the sensor
///////////////////////////////////////////////////////


void setup() {
  // Start the serial communication for the Ultra sound sensor
  Serial.begin(115200);

  // Collision sensor
  //pinMode(Led,OUTPUT);// set pin LED as output
  pinMode(Shock,INPUT);// set collision sensor as input 

// change this to the atSign you own and have the keys to
    const auto *esp32 = new AtSign("@6isolated69");
    const auto *java = new AtSign("@impossible6891");
    
    // reads the keys on the ESP32
    const auto keys = keys_reader::read_keys(*esp32); 
    
    // creates the AtClient object (allows us to run operations)
    auto *at_client = new AtClient(*esp32, keys);  

    // pkam authenticate into our atServer
    at_client->pkam_authenticate(SSID, PASSWORD);

    auto *at_key = new AtKey("test", esp32, java);


    //at_key->namespace_str = "fourballcorporate9";
    // namespace_str is a const, there is no way to edit it

  //  Proximity sensor
  pinMode(Led, OUTPUT);
  pinMode(sensorPin, INPUT);

  pinMode(trigPin, OUTPUT); // Sets the trigPin as an Output
  pinMode(echoPin, INPUT); // Sets the echoPin as an Input

  // Collision sensor
  pinMode(Shock,INPUT);// set collision sensor as input

  const auto approximate = std::string("PROXIMITY");
  const auto nothing = std::string("NO_PROXIMITY");


  cout << "Nothing is within proximity" << endl;
  at_client->put_ak(*at_key, nothing);

  while (true)
  {
    // Collision Sensor
    val=digitalRead(Shock);// read value on pin 3 and assign it to val
    if(val!=HIGH)// when collision sensor detects a signal, LED turns on.
    {
      digitalWrite(Led,LOW);
      cout << "COLLISION OCCURED! CALL AN AMBULANCE!" << endl;
      const auto value = std::string("COLLISION");

      at_client->put_ak(*at_key, value);
      break;
    }

    sensorState = digitalRead(sensorPin);
    // if it is, the sensorState is HIGH:
    // If the proximity sensor detects something, that is when we
    // call for the ultra sonic sensor to calculate the distance
    // of the object

    if (sensorState == LOW) {
      cout << "Something is within Proximity. Record the distances!" << endl;
      at_client->put_ak(*at_key, approximate);
    }

    while (sensorState != HIGH)
    {
      // Clears the trigPin
      digitalWrite(trigPin, LOW);
      delayMicroseconds(2);
      // Sets the trigPin on HIGH state for 10 micor seconds
      digitalWrite(trigPin, HIGH);
      delayMicroseconds(10);
      digitalWrite(trigPin, LOW);

      // reads the echoPin, returns the sound wave travel time in microseconds
      duration = pulseIn(echoPin, HIGH);

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
      const auto distance = std::to_string(distanceInch);
      at_client->put_ak(*at_key, distance);

      val=digitalRead(Shock);// read value on pin 3 and assign it to val
      if(val!=HIGH)// when collision sensor detects a signal, LED turns on.
      {
        digitalWrite(Led,LOW);
        cout << "COlLISION OCCURED! CALL AN AMBULANCE!" << endl;
        break;
      }

      digitalWrite(Led, HIGH);
      sensorState = digitalRead(sensorPin);

      // Send the data in centimetrs to the app
      //at_client->put_ak(*at_key, to_string(distanceCM));

      delay(1000);

      // Tell the app that nothing has been detected:
      // The Java app will continue having the same
      // latest value of nothing having been within proximity. 
      if (sensorState == HIGH)
      {
        cout << "Nothing is within proximity" << endl;
        at_client->put_ak(*at_key, nothing);
      }

    }
    digitalWrite(Led, LOW);
  }
}

// Send the data of the distance in centimeters to the atsign java app

void loop() {
}