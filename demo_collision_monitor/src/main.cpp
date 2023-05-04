#include <Arduino.h>
#include <WiFiClientSecure.h>
#include <SPIFFS.h>
#include "at_client.h"

#include "constants.h"

void setup()
{
    // put your setup code here, to run once:

    // change this to the atSign you own and have the keys to
    const auto *esp32 = new AtSign("@xenogeneic80the");
    const auto *flutter = new AtSign("@2bluescorpio");
    
    // reads the keys on the ESP32
    const auto keys = keys_reader::read_keys(*esp32); 
    
    // creates the AtClient object (allows us to run operations)
    auto *at_client = new AtClient(*esp32, keys);  
    
    // pkam authenticate into our atServer
    at_client->pkam_authenticate(SSID, PASSWORD); 

    // key to send data from esp32 to flutter
    //auto *shared_with_flutter = new AtKey("demo", esp32, flutter);

    //shared_with_flutter->namespace_str = "socrates9";

    //at_client->put_ak(*shared_with_flutter, "init");
}

void loop() {
  // put your main code here, to run repeatedly:
}