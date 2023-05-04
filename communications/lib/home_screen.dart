import 'package:at_client_mobile/at_client_mobile.dart';
import 'package:flutter/material.dart';

// * Once the onboarding process is completed you will be taken to this screen
class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // * Getting the AtClientManager instance to use below
    final AtClientManager atClientManager = AtClientManager.getInstance();

    final AtClient atClient = atClientManager.atClient;
    const String esp32 = "@xenogeneic80the";
    final String flutter = atClient.getCurrentAtSign()!; // @xenogeneic80the

    // Shared by the FLutter AtSign
    final AtKey sharedWithESP32 = AtKey()
      ..sharedWith = esp32
      ..key = 'demo'
      ..namespace = 'socrates9'
      ..sharedBy = flutter;

    // Build the other key so the app can get it

    return Scaffold(
      appBar: AppBar(
        title: const Text('What\'s my current @sign?'),
      ),
      body: Center(
        child: Column(children: [
          const Text('Successfully onboarded and navigated to FirstAppScreen'),

          ElevatedButton(
            onPressed: () async {
              bool success = await atClient.put(sharedWithESP32, 'init');
              print('Write success? $success');
            },
            child: Text('Do Thing'),
          ),

          // * Use the AtClientManager instance to get the AtClient
          // * Then use the AtClient to get the current @sign
          Text('Current @sign: ${atClientManager.atClient.getCurrentAtSign()}')
        ]),
      ),
    );
  }
}
