#include <iostream>
#include <Arduino.h>
#include <WiFiClientSecure.h>
#include <SPIFFS.h>
#include "at_client.h"
#include <string>
#include "constants.h"

#include "monitor.h"
void setup() {

  // change this to the atSigns you created
  const auto *esp32 = new AtSign("@6isolated69");
  const auto *flutter = new AtSign("@impossible6891");
      
  // reads the keys on the ESP32
  const auto keys = keys_reader::read_keys(*esp32); 
      
  // creates the AtClient object (allows us to run operations)
  auto *at_client = new AtClient(*esp32, keys);

  // pkam authenticate into our atServer
  at_client->pkam_authenticate(SSID, PASSWORD);

  // At_Key for putting data to the @sign in the flutter app from esp32 @sign
  // Note: The string "test" can be changed to what user desires, but the
  // same respective AtKeys in Flutter must have the same string.
  auto *at_key = new AtKey("test", esp32, flutter);
  // At_Key for recieving data sent from flutter @sign to the esp32 @sign
  auto *at_key2 = new AtKey("test", flutter, esp32);
  at_key2->namespace_str = "socrates9";

  // Create a Monitor Class object and initialize the pins to which
  // the sensors (collision; proximity; and ultrasonic) are connected
  // to on the esp32.
  // Note: Monitor Class is further described in "monitor.h" file
  Monitor col_system(34, 12, 5, 18, 36);
  // Initialize the keys and at_client of the Monitor class object.
  col_system.putkey = at_key;
  col_system.getkey = at_key2;
  col_system.client = at_client;


  // 
  while (true)
  {
    // Check whether monitoring is currently enabled, or disabled.
    // Note: That flutter @sign must send data first, in order for the shared
    // key to be initialized, because as of 5/21/23, the esp32 cannot initialize
    // any key.
    cout << "Monitoring is currently ";
    cout << at_client->get_ak(*col_system.getkey);
    cout << "." << endl;

    // Check if the value sent from Flutter Application is "enabled", otherwise it's
    // "disabled" or "reset".
    if (at_client->get_ak(*at_key2) == "enabled")
    {
      cout << "Monitoring begins:" << endl;
      // Begin collision monitoring (collision_monitor() is further explained in "monitor.h")
      collision_monitor(col_system);
    }
  }

}

void loop() {
  // put your main code here, to run repeatedly:
}