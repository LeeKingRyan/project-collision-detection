import 'package:at_client_mobile/at_client_mobile.dart';
import 'package:flutter/material.dart';
import 'transfer_functions.dart';

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

// * Once the onboarding process is completed you will be taken to this screen
class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  // In snackbar, HomeScrene extends StatefulWidget, what's the difference
  // between this from StatelessWidget
  // @override
  // State<HomeScreen> createState() => _HomeScreenState();


  @override
  Widget build(BuildContext context) {
    // * Getting the AtClientManager instance to use below
    AtClientManager atClientManager = AtClientManager.getInstance();

    String? currentAtsign;
    late AtClient atClient;
    final myController = TextEditingController();

    // There is some notification code here, but that could be ignored.

    atClient = atClientManager.atClient; // get the current atsign associated
    // with the atClientManager
    currentAtsign = atClient.getCurrentAtSign(); // THis is the chosen @sign
    // from the onboarding

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pressure Sensor'),
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
              activateMonitor(context, myController.text);
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => RandomNumberScreen(
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

class RandomNumberScreen extends StatefulWidget {
  final String text; // This screen waits for a string valuu, expected on
  // its constructor
  RandomNumberScreen({required this.text});
  @override
  _RandomNumberScreenState createState() => _RandomNumberScreenState();
}

class _RandomNumberScreenState extends State<RandomNumberScreen> {
  double _randomNumber = 0;
  bool pressure = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // random number only changes after function finishes.
    dataAnalysis(context, widget.text); // text is @6isolated69
  }

  void dataAnalysis(context, String device) async {
    while (true) {
      String data = await getAtsignData(context, device);
      // Collision Detected: Disable the esp32 from its next iteration of monitoring
      if (data == "0") {
        putAtsignData(context, device, "disable");
        printMessage(context, 'No Pressure has been sensed');

        setState(() {
          _randomNumber = 0;
        });
        break;
      }
      // Proximity Sensor detects something: Read the distances in Centimeters
      // until nothing is no long in proximity or a collision occurs!
      else if (data != "0") {
        // Can call a separate function here and have dataAnalysis finish

        printMessage(context, '');
        while (true) {
          await Future.delayed(const Duration(seconds: 10));
          data = await getAtsignData(context, device);
          // convert string data to int
          // randomNumber = data
          if (data == "0") {
            // random Number = 0

            setState(() {
              _randomNumber = 0;
            });

            break;
          }

          setState(() {
            _randomNumber = double.parse(data);
          });

          printMessage(context,
              'Pressure in psi from Unidentified Object UO: $data');
        }
        printMessage(context, 'No pressure is detected anymore');
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pressure sensed'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Pressure:',
              style: TextStyle(fontSize: 30),
            ),
            Text(
              '${_randomNumber}psi',
              style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
            ),
            _randomNumber == 0.0 && pressure == false
                ? Text(
                    'No pressure is sensed',
                    style: TextStyle(
                        fontSize: 30,
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.bold),
                  )
                : SizedBox.shrink(),
            _randomNumber == 0.0 && pressure == true
                // Create an animation here where the balls will bounce off
                // each other. Additionally, this bounce animation may depend
                // on the retrieved value of the esp32 connected to the pressure
                // sensor Unmit.
                ? Text(
                    'Pressure has been sensed',
                    style: TextStyle(
                        fontSize: 30,
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.bold),
                  )
                : SizedBox.shrink(),
            SizedBox(height: 40),
            TweenAnimationBuilder(
              tween: Tween<double>(begin: 0, end: _randomNumber.toDouble()),
              duration: Duration(seconds: 1),
              builder: (BuildContext context, double distance, Widget? child) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.circle,
                        color: pressure == true ? Colors.purple : Colors.blue,
                        size: 100),
                    SizedBox(width: distance * 4),
                    distance == 0.0
                        ? Container()
                        : Icon(Icons.circle, color: Colors.red, size: 100),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}