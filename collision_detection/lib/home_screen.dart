import 'package:at_client_mobile/at_client_mobile.dart';
import 'package:flutter/material.dart';
import 'transfer_functions.dart';

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
              // Send a signal to an esp32 to activate it's code to monitor for
              // any collisions
              // void activateMonitor(context, String device): send a string
              // 'active' to specified esp32 (device) from the myController
              activateMonitor(context, myController.text);
              dataAnalysis(context, myController.text);
            },
            child: const Text('Activate esp32 device'),
          ),
          const Spacer(flex: 1),
        ]),
      ),
    );
  }
}
