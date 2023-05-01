// The following function sends a simple string "activate" to a designated
// @sign. In this case, we want to send the string to an esp32 device to
// activate use of its sensors.
import 'package:at_client_mobile/at_client_mobile.dart';
import 'package:collision_detection/main.dart';

import 'package:at_client_mobile/at_client_mobile.dart';
import 'package:flutter/material.dart';
import 'transfer_functions.dart';

void activateMonitor(context, String device) async {
  // const String on = "activate";
  // Get the AtClientManager instance
  var atClientManager = AtClientManager.getInstance();

  Future<AtClientPreference> futurePreference = loadAtClientPreference();

  var preference = await futurePreference;

  // Get the current atSign that is sending data from this Flutter app
  String? currentAtsign;
  late AtClient atClient;
  atClient = atClientManager.atClient;
  atClientManager.atClient.setPreferences(preference);
  currentAtsign = atClient.getCurrentAtSign();

  // We specify not to send values through keys publicly, and we ignore
  // considering namespace
  var metaData = Metadata()
    ..isPublic = false
    ..isEncrypted = true
    ..namespaceAware = true
    ..ttl = 100000;
  // Create the key shared between the current atsign (Flutter app) and
  // the @sign to recieve from current @sign (esp32)
  var key = AtKey()
    ..key = "test" // special key shared between the @atsigns communicating
    ..sharedBy = currentAtsign // chosen @sign to send data
    ..sharedWith = device // The @sign that will recieve data sent to it
    ..metadata = metaData;

  String value = "active";

  // Send the data to the designated esp32 in the paramter device
  await atClient.putText(key, value);
  printMessage(context, 'Successfully actived the esp32 at $device');
}

// Put any string data into a key value.
void putAtsignData(context, String device, String value) async {
  // const String on = "activate";
  // Get the AtClientManager instance
  var atClientManager = AtClientManager.getInstance();

  Future<AtClientPreference> futurePreference = loadAtClientPreference();

  var preference = await futurePreference;

  // Get the current atSign that is sending data from this Flutter app
  String? currentAtsign;
  late AtClient atClient;
  atClient = atClientManager.atClient;
  atClientManager.atClient.setPreferences(preference);
  currentAtsign = atClient.getCurrentAtSign();

  // We specify not to send values through keys publicly, and we ignore
  // considering namespace
  var metaData = Metadata()
    ..isPublic = false
    ..isEncrypted = true
    ..namespaceAware = true
    ..ttl = 100000;
  // Create the key shared between the current atsign (Flutter app) and
  // the @sign to recieve from current @sign (esp32)
  var key = AtKey()
    ..key = "test" // special key shared between the @atsigns communicating
    ..sharedBy = currentAtsign // chosen @sign to send data
    ..sharedWith = device // The @sign that will recieve data sent to it
    ..metadata = metaData;

  // Send the data to the designated esp32 in the paramter device
  await atClient.put(key, value);
}

// This function gets the value sent to the current @sign (the Flutter app)
Future<String> getAtsignData(context, String sharedByAtsign) async {
  /// Get the AtClientManager instance
  var atClientManager = AtClientManager.getInstance();

  Future<AtClientPreference> futurePreference = loadAtClientPreference();

  var preference = await futurePreference;

  // This is the atSign getting the data?
  // This getting of currentAtsiggn should always be the atSign chosen
  // at onBoard!
  String? currentAtsign;
  late AtClient atClient;
  atClient = atClientManager.atClient;
  atClientManager.atClient.setPreferences(preference);
  currentAtsign = atClient.getCurrentAtSign();

  var metaData = Metadata()
    ..isPublic = false
    ..isEncrypted = true
    ..namespaceAware = false;

  // Create the key again
  var key = AtKey()
    ..key = "test"
    ..sharedBy = sharedByAtsign
    ..sharedWith = currentAtsign
    ..metadata = metaData;

  // The magic line that picks up the data
  var dataKey = await atClient.get(key);
  var data = dataKey.value.toString();
  return data;
}

// This function decides whether to signal the esp32 to stop monitoring
// if get a string "COLLISION", and then proceed to record the pressure of
// another @sign of a different esp32. Or if a "PROXIMITY" string is read, then
// the following distances in centimeters of the object in proximity from
// the esp32's ultrasonic sensor's are recorded.
void dataAnalysis(context, String device) async {
  while (true) {
    String data = await getAtsignData(context, device);
    // Collision Detected: Disable the esp32 from its next iteration of monitoring
    if (data == "COLLISION") {
      putAtsignData(context, device, "disable");
      printMessage(context, 'Collision has occured at device location');
      break;
    }
    // Proximity Sensor detects something: Read the distances in Centimeters
    // until nothing is no long in proximity or a collision occurs!
    else if (data == "PROXIMITY") {
      printMessage(context, 'Something is within proximity');
      while (true) {
        await Future.delayed(const Duration(seconds: 10));
        data = await getAtsignData(context, device);
        if (data == "NO_PROXIMITY") {
          break;
        }
        printMessage(context, 'Distance in inches from UFO: $data');
      }
      printMessage(context, 'Nothing is within proximity anymore');
    }
  }
}

// The following function prints a message
void printMessage(context, String message) {
  final snackBar = SnackBar(
    content: Text(message),
    action: SnackBarAction(
      label: 'Undo',
      onPressed: () {
        // Some code to undo the change.
      },
    ),
  );

  ScaffoldMessenger.of(context).showSnackBar(snackBar);
}
