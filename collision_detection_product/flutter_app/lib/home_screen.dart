import 'package:at_client_mobile/at_client_mobile.dart';
import 'package:flutter/material.dart';
import 'transfer_functions.dart';

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

// * Once the onboarding process is completed you will be taken to this screen
// * to submit another atsign via text field input, and this would be the
// * atsign used on the esp32.
class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  // @override
  // State<HomeScreen> createState() => _HomeScreenState();

  @override
  Widget build(BuildContext context) {
    // * Getting the AtClientManager instance to use below
    AtClientManager atClientManager = AtClientManager.getInstance();

    String? currentAtsign;
    late AtClient atClient;

    // Controller for text field
    final myController = TextEditingController();

    atClient = atClientManager.atClient; // get the current atsign associated
    // with the atClientManager
    currentAtsign = atClient.getCurrentAtSign(); // THis is the chosen @sign
    // from the onboarding

    return Scaffold(
      appBar: AppBar(
        title: const Text('Collision Monitor'),
      ),
      body: Center(
        child: Column(children: [
          const Text('Successfully onboarded and navigated to FirstAppScreen'),

          // * Use the AtClientManager instance to get the AtClient
          // * current Atsign has already been initialized by the statements
          // * atCLient = atClientManager.atClient;
          // * and currentAtsign = atClient.getCurrentAtSign();
          // * Then use the AtClient to get the current @sign
          Text('Current @sign: ${atClientManager.atClient.getCurrentAtSign()}'),
          const Spacer(flex: 1),
          const Text('Which @sign would you like to monitor?'),
          TextField(
            controller: myController,
            textAlign: TextAlign.center,
          ),
          ElevatedButton(
            onPressed: () {
              // Activate the monitoring system in the esp32 C++ code
              // by sending string "enabled" to esp32 @sign
              activateMonitor(context, myController.text);
              // Navigate to the next screen where there's a simple UI
              // interface that utlizes the data sent by the esp32
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => CollisionBallsScreen(
                          text: myController.text,
                        )),
              );
            },
            child: Text('Start'),
          ),
          const Spacer(flex: 1),
        ]),
      ),
    );
  }
}

class CollisionBallsScreen extends StatefulWidget {
  final String text; // This screen waits for a string value, expected on
  // its constructor
  CollisionBallsScreen({required this.text});
  @override
  _CollisionBallsScreenState createState() => _CollisionBallsScreenState();
}

class _CollisionBallsScreenState extends State<CollisionBallsScreen> {
  double _distanceCM = 0; // distance from UO recieved from esp32 in cm
  bool collision = false; // has collision occured: true or false

  @override
  void initState() {
    super.initState();
    // Monitor the data sent from esp32 and respond accordingly.
    dataAnalysis(context, widget.text); // text is @6isolated69
  }

  // This function decides whether to signal the esp32 to stop monitoring
  // if get a string "COLLISION", and then proceed to record the pressure of
  // another @sign of a different esp32. Or if a "PROXIMITY" string is read, then
  // the following distances in centimeters of the object in proximity from
  // the esp32's ultrasonic sensor's are recorded.

  void dataAnalysis(context, String device) async {
    while (true) {
      // get the data from the esp32 @sign
      String data = await getAtsignData(context, device);
      // Collision Detected: Disable the esp32 from its next iteration of monitoring
      if (data == "COLLISION") {
        putAtsignData(context, device, "disabled");
        printMessage(context, 'Collision has occured at device location');

        setState(() {
          _distanceCM = 0;
          collision = true;
        });
        return; // Collison occured, so exit data analysis
      }
      // Proximity Sensor detects something: Read the distances in Centimeters
      // until nothing is no longer in proximity or a collision occurs!
      else if (data == "PROXIMITY") {
        printMessage(context, 'Something is within proximity');

        while (true) {
          await Future.delayed(const Duration(seconds: 10));
          data = await getAtsignData(context, device);
          // convert string data to int
          if (data == "NO_PROXIMITY") {
            setState(() {
              _distanceCM = 0;
            });

            break; // No more distances to be read
          } else if (data == "COLLISION") {
            setState(() {
              _distanceCM = 0;
              collision = true;
            });
            putAtsignData(context, device, "disable");
            printMessage(context, 'Collision has occured at device location');
            return;
          }
          // Want to only record distances, and due to slow down of encryption
          // from esp32, flutter app may accidently read none distance
          // strings like "PROXIMITY" as distance, as it decrypts at a faster
          // rate.
          if (data != "PROXIMITY") {
            setState(() {
              _distanceCM = double.parse(data);
            });
          }
        }
        printMessage(context, 'Nothing is within proximity anymore');
      } // else if "PROXIMITY" condition
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Calculated Distance'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Distance:',
              style: TextStyle(fontSize: 30),
            ),
            Text(
              '${_distanceCM}cm',
              style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
            ),
            // Check if distance is 0.0 and collision hasn't occured, thus
            // nothing is within proximity.
            _distanceCM == 0.0 && collision == false
                ? Text(
                    'Nothing in Proximity',
                    style: TextStyle(
                        fontSize: 30,
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.bold),
                  )
                : SizedBox.shrink(),
            // Check if distance is 0.0 and collision has occured, and if so,
            // the balls will cojoin into a puple ball.
            _distanceCM == 0.0 && collision == true
                ? Text(
                    'Collision Occured at Object site',
                    style: TextStyle(
                        fontSize: 30,
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.bold),
                  )
                : SizedBox.shrink(),
            SizedBox(height: 40),
            TweenAnimationBuilder(
              // Set distance between balls
              tween: Tween<double>(begin: 0, end: _distanceCM.toDouble()),
              duration: Duration(seconds: 1),
              builder: (BuildContext context, double distance, Widget? child) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.circle,
                        color: collision == true ? Colors.purple : Colors.blue,
                        size: 100),
                    SizedBox(width: distance * 2),
                    distance == 0.0
                        ? Container()
                        : Icon(Icons.circle, color: Colors.red, size: 100),
                  ],
                );
              },
            ),
            Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: ElevatedButton(
                  onPressed: () {
                    printMessage(
                        context, "restarting monitor, please wait 30 seconds.");
                    putAtsignData(context, widget.text, "reset");
                    // Await 30 seconds, before calling activateMonitor again,
                    // so that the esp32 has time to send the string
                    // "NO_PROXIMITY" after restarting

                    // Reset the collision status to false.
                    setState(() {
                      collision = false;
                    });
                    Timer(Duration(seconds: 30), () {
                      activateMonitor(context, widget.text);
                      // Navigate to CollisionBallScreen again
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => CollisionBallsScreen(
                                  text: widget.text,
                                )),
                      );
                    });
                  },
                  child: Text('Restart'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
