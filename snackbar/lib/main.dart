import 'dart:async';
import 'dart:math';

import 'package:at_onboarding_flutter/at_onboarding_flutter.dart';
import 'package:flutter/material.dart';
import 'package:at_client_mobile/at_client_mobile.dart';

import 'package:at_utils/at_logger.dart' show AtSignLogger;
import 'package:path_provider/path_provider.dart'
    show getApplicationSupportDirectory;
import 'package:at_app_flutter/at_app_flutter.dart' show AtEnv;

//String snack = '';
Future<void> main() async {
  await AtEnv.load();
  runApp(const MyApp());
}

Future<AtClientPreference> loadAtClientPreference() async {
  var dir = await getApplicationSupportDirectory();
  return AtClientPreference()
        ..rootDomain = AtEnv.rootDomain
        ..namespace = AtEnv.appNamespace
        ..hiveStoragePath = dir.path
        ..commitLogPath = dir.path
        ..isLocalStoreRequired = true
      // TODO set the rest of your AtClientPreference here
      ;
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // * load the AtClientPreference in the background
  Future<AtClientPreference> futurePreference = loadAtClientPreference();
  AtClientPreference? atClientPreference;

  final AtSignLogger _logger = AtSignLogger(AtEnv.appNamespace);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // * The onboarding screen (first screen)
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Snackbar'),
        ),
        body: Builder(
          builder: (context) => Center(
            child: ElevatedButton(
              onPressed: () async {
                AtOnboardingResult onboardingResult =
                    await AtOnboarding.onboard(
                  context: context,
                  config: AtOnboardingConfig(
                    atClientPreference: await futurePreference,
                    rootEnvironment: AtEnv.rootEnvironment,
                    domain: AtEnv.rootDomain,
                    appAPIKey: AtEnv.appApiKey,
                  ),
                );
                switch (onboardingResult.status) {
                  case AtOnboardingResultStatus.success:
                    Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const HomeScreen()));
                    break;
                  case AtOnboardingResultStatus.error:
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        backgroundColor: Colors.red,
                        content: Text('An error has occurred'),
                      ),
                    );
                    break;
                  case AtOnboardingResultStatus.cancel:
                    break;
                }
              },
              child: const Text('Onboard an @sign'),
            ),
          ),
        ),
      ),
    );
  }
}

//* The next screen after onboarding (second screen)
class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    /// Get the AtClientManager instance
    ///
    var atClientManager = AtClientManager.getInstance();

    String? currentAtsign;
    late AtClient atClient;
    final myController = TextEditingController();

    var notificationService = atClientManager.atClient.notificationService;
    //var notificationService = atClientManager.notificationService;
    notificationService
        .subscribe(regex: AtEnv.appNamespace)
        .listen((notification) {
      getAtsignData(context, notification.key);
    });

    atClient = atClientManager
        .atClient; // Get the current atSign associated with the atClientManager
    currentAtsign = atClient.getCurrentAtSign(); // This will always be the
    // chosen @sign from the onboarding
    return Scaffold(
      appBar: AppBar(
        title: const Text('Snackbar'),
      ),
      body: Center(
        child: Column(
          children: [
            const Text(
                'Successfully onboarded and navigated to FirstAppScreen'),

            /// Use the AtClientManager instance to get the current atsign
            /// current Atsign has already been initialized by the statments
            /// atClient = atClientManager.atClient;
            /// and currentAtsign = atClient.getCurrentAtSign();
            Text('Current @sign: $currentAtsign'),
            const Spacer(flex: 1),
            const Text('Which @sign would you like to send a snack to ?'),
            TextField(
              controller: myController,
              textAlign: TextAlign.center,
            ),
            ElevatedButton(
              onPressed: () {
                sendAtsignData(context, myController.text);
                getAtsignData(context,
                    '@impossible6891:test.fourballcorporate9.@6isolated69');
                //getAtsignData(
                //    context, '@impossible6891:test.whatisThis.@6isolated69');

                // Namespace is always fourballcorporate
                //getAtsignData(context,
                //    '@impossible6891:test.fourballcorporate9.@6isolated69');
              },
              child: const Text('Send a snack'),
            ),
            const Spacer(flex: 1),
            //ElevatedButton(
            //  onPressed: () {
            //    // value we get should be "Collision", sent by @6isolated69
            // "Collison" is the snack and @6isolated69 is the sentbyAtsign
            //   getAtsignData(
            //       context, '@impossible6891:test.6isolated69.@6isolated69');
            // },
            // child: Text('Get the value sent by @6isolated69'),
            //),
          ],
        ),
      ),
    );
  }
}

void getAtsignData(context, String notificationKey) async {
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

  //Split the notification to get the key and the sharedByAtsign
  // Notification looks like this :-
  // @ai6bh:snackbar.colin@colin
  var notificationList = notificationKey.split(':');
  // Split the notification into two elements, the first element being the
  // atSign that sent data

  // Below we get the @sign from the slit part, let's say for example
  // snackbar.colin@colin. notificationList[1].split('@').last gets
  // colin, so adding the @ gets the sharedByAtsign @colin

  // This should be the @sign that sends data.
  String sharedByAtsign = '@' + notificationList[1].split('@').last;

  // Gets the key Atsign
  String keyAtsign = notificationList[1];
  keyAtsign = keyAtsign.replaceAll(
      '.${preference.namespace.toString()}$sharedByAtsign', '');

  // Keystore @6isolated69 doesn't exists
  sharedByAtsign = "@6isolated69";
  keyAtsign = "test";

  //RemoteSecondary? dev = atClient.getRemoteSecondary();

  //AtClient dev = AtClient.withRemoteSecondary("root.atsign.org:64", java);

  var metaData = Metadata()
    ..isPublic = false
    ..isEncrypted = true
    ..namespaceAware = false;

  // Create the key again
  var key = AtKey()
    ..key = keyAtsign
    ..sharedBy = sharedByAtsign
    ..sharedWith = currentAtsign
    ..metadata = metaData;

  // Need to remote secondary with 6isolated69
  // similar to below
  // AtClient atClient = AtClient.withRemoteSecondary("root.atsign.org:64", java);
  //  SharedKey sharedKey = new KeyBuilders.SharedKeyBuilder(esp32, java).key("test").build();
  // String data = atClient.get(sharedKey).get();

  /*
  Error has occured:
  AtClientException (Exception: Internal server exception :
  Request to remote secondary @6isolated69 at null:null received error response
  'AT0015-Exception: @impossible6891:test.fourballcorporate9@6isolated69 does
  not exist in keystore')
  */

  // The magic line that picks up the snack
  var snackKey = await atClient.get(key);
  // Yes that is all you need to do!
  var snack = snackKey.value.toString();

  popSnackBar(context, 'Yay! A $snack ! From $sharedByAtsign');
}

// sendSnackTo is the atsign we are sending data too that is already cerified
// onBoard
void sendAtsignData(context, String sendSnackTo) async {
  /// Get the AtClientManager instance
  var atClientManager = AtClientManager.getInstance();

  Future<AtClientPreference> futurePreference = loadAtClientPreference();

  var preference = await futurePreference;

// Just an array of strings to assoicate with the given atSign
// held by the variable string sendSnackTo
  var snacks = [
    ' Milky Way',
    ' Dime Bar',
    ' Crunchy Bar',
    ' Mars Bar',
    ' Snickers Bar',
    ' Zagnut Bar',
    'n Almond Joy Bar',
    ' 3 Musketeers Bar',
    ' Clark Bar',
    ' Caramello Bar',
    ' Twix Bar',
    ' KitKat Bar',
  ];

  String snack = snacks[Random().nextInt(snacks.length)];
  // Get the currentAtsign that is sending data
  String? currentAtsign;
  late AtClient atClient;
  atClient = atClientManager.atClient;
  atClientManager.atClient.setPreferences(preference);
  currentAtsign = atClient.getCurrentAtSign();
  // Simply just getting the current atsing from the atCLientManager in which
  // this will be the main java atsign to send data to an esp32 or to retrieve
  // data from an esp32

  // Not sending values through keys publically
  var metaData = Metadata()
    ..isPublic = false
    ..isEncrypted = true
    ..namespaceAware = true
    ..ttl = 100000;

  // Creating the key
  var key = AtKey()
    ..key =
        'snackbar' // special key that is to be shared between the @atsigns communicating
    ..sharedBy =
        currentAtsign // This is the java app, or the chosen @sign to send data from
    ..sharedWith =
        sendSnackTo // This is the @sign that will recieve the sent data
    ..metadata = metaData;

  // notification string should be
  // sendSnackTo.snakbar.currentAtsign

  // The magic line to send the snack
  // This is how we will send snak data
  // or just data in general
  await atClient.put(key, snack);
  // We can call get here instead
  atClientManager.atClient.syncService;
  //atClientManager.syncService.sync;

  // Comment out this line
  // snack is just some string
  popSnackBar(context, 'You just sent. A$snack, to $sendSnackTo. Also, the ');
  // This is just a message sender, popSnackBar
}

void popSnackBar(context, String snackmessage) {
  final snackBar = SnackBar(
    content: Text(snackmessage),
    action: SnackBarAction(
      label: 'Undo',
      onPressed: () {
        // Some code to undo the change.
      },
    ),
  );

  ScaffoldMessenger.of(context).showSnackBar(snackBar);
}
