import 'dart:async';
import 'dart:math';

import 'package:at_onboarding_flutter/at_onboarding_flutter.dart';
import 'package:flutter/material.dart';
import 'package:at_client_mobile/at_client_mobile.dart';

import 'package:at_utils/at_logger.dart' show AtSignLogger;
import 'package:path_provider/path_provider.dart'
    show getApplicationSupportDirectory;
import 'package:at_app_flutter/at_app_flutter.dart' show AtEnv;

final AtSignLogger _logger = AtSignLogger(AtEnv.appNamespace);

Future<void> main() async {
  // * AtEnv is an abtraction of the flutter_dotenv package used to
  // * load the environment variables set by at_app
  try {
    await AtEnv.load();
  } catch (e) {
    _logger.finer('Environment failed to load from .env: ', e);
  }
  // await AtEnv.load
  runApp(const MyApp());
}

Future<AtClientPreference> loadAtClientPreference() async {
  var dir = await getApplicationSupportDirectory();

  return AtClientPreference()
    ..rootDomain = AtEnv
        .rootDomain // Domain of the root server. Defaults to root.atsign.org
    ..namespace = AtEnv.appNamespace // Just the name space of the app
    ..hiveStoragePath = dir.path // local drive path of the hivestorage
    ..commitLogPath = dir.path // Local device path of commit log
    ..isLocalStoreRequired = true; // Specify whether local store is required
  // TODO
  // * By default, this configuration is suitable for most applications
  // * In advanced cases you may need to modify [AtClientPreference]
  // * Read more here: https://pub.dev/documentation/at_client/latest/at_client/AtClientPreference-class.html
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

  // Not entirely sure what AtSign Logger does, so will have to ask Jeremy.
  final AtSignLogger _logger = AtSignLogger(AtEnv.appNamespace);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // * The onboarding screen (first screen)
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Collision_App'),
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

// Create a new screen once the Onboard is successful.
class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    // Get the AtClientManager instance. THe first instance of
    // calling the AtClientManager
    var atClientManager = AtClientManager.getInstance();
    String? currentAtSign;
    late AtClient atClient;

    // have a controller for text editing. This will help for manually
    // inputing the name of the
    final myController = TextEditingController();

    /// Most likely do not need this part of the code for notifications
    var notificationService = atClientManager.atClient.notificationService;
    notificationService
        .subscribe(regex: AtEnv.appNamespace)
        .listen((notification) {
      getAtsignData(context, notification.key);
    });

    atClient = atClientManager.atClient;
    currentAtSign = atClient.getCurrentAtSign();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Collision_Protocol'),
      ),
      body: Center(
        child: Column(
          children: [
            const Text(
                'Successfully onboarded and navigated to FirstAppScreen'),

            // Earlier we got the current atsign
            Text('Current @sign: $currentAtSign'),
            const Spacer(flex: 1),
            const Text('Whch @sign would you like to retrieve data from?'),
            TextField(
              controller: myController,
              textAlign: TextAlign.center,
            ),
            ElevatedButton(
              onPressed: () {
                //sendAtSignData(context, myController.text);
                getAtsignData(context,
                    '@impossible6891:test.fourballcorporate9.@6isolated69');
              },
              child: const Text('Detect a collision'),
            ),
            const Spacer(flex: 1),
          ],
        ),
      ),
    );
  }
}

// Other Functions

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

  // The magic line that picks up the snack
  var snackKey = await atClient.get(key);
  // Yes that is all you need to do!
  var snack = snackKey.value.toString();

  popSnackBar(context, 'Yay! A $snack ! From $sharedByAtsign');
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
