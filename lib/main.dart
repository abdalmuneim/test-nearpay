import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:nearpay_flutter_sdk/errors/purchase_error/purchase_error.dart';
import 'package:nearpay_flutter_sdk/nearpay.dart';
import 'package:uuid/uuid.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late Nearpay nearpay;
  final tokenKey = "emad.it@albir.org.sa";
  final AuthenticationType authType = AuthenticationType.email;
  final timeout = 60;

  @override
  void initState() {
    super.initState();
    initSDK();
  }

  initSDK() async {
    nearpay = Nearpay(
      authType: authType,
      authValue: tokenKey,
      env: Environments.sandbox,
      locale: Locale.localeDefault,
    );
    await nearpay
        .initialize()
        .then((value) => data["init"] = "done")
        .catchError((onError) async => data["onErrorinit"] = await onError);
    await nearpay
        .setup()
        .then((value) => data["setup"] = "done")
        .catchError((onError) async => data["onErrorSetup"] = await onError);
    setState(() {
      data;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
        leading: IconButton(
            onPressed: () => logout(), icon: const Icon(Icons.logout)),
        actions: [
          IconButton(
              onPressed: () => getUser(), icon: const Icon(Icons.person)),
          IconButton(
              onPressed: () => initSDK(),
              icon: const Icon(Icons.install_mobile_outlined))
        ],
      ),
      body: StreamBuilder<Map>(
          stream: Stream.periodic(
            const Duration(seconds: 2),
            (computationCount) => data,
          ),
          builder: (context, AsyncSnapshot<Map> snapshot) {
            if (!snapshot.hasData) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }
            return Padding(
              padding: const EdgeInsets.all(8.0),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Text(
                      "response: ${snapshot.data}",
                    ),
                    Text(
                      ' ',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ],
                ),
              ),
            );
          }),
      floatingActionButton: FloatingActionButton(
        onPressed: () async => purchase(),
        tooltip: 'pay',
        child: const Icon(Icons.payments_rounded),
      ),
    );
  }

  getUser() async {
    await nearpay.getUserSession(
      onSessionFree: () => print("session free"),
      onSessionBusy: (message) => print("session busy: $message"),
      onSessionInfo: (info) => print("info: ${jsonEncode(info.toJson())}"),
      onSessionFailed: (error) => print("session error $error"),
    );
  }

  logout() async {
    await nearpay.logout().then((value) {
      log("logout: $value");
    });
  }

  Map data = {};
  purchase() async {
    await nearpay
        .purchase(
      amount: 0001, // [Required] ammount you want to set .
      transactionId: const Uuid()
          .v4(), // [Optional] specefy the transaction uuid for later referance
      customerReferenceNumber:
          'abcabc', // [Optional] any number you want to add as a refrence Any string as a reference number
      enableReceiptUi: true, // [Optional] show the reciept in ui
      enableReversalUi:
          true, // [Optional] it will allow you to enable or disable the reverse button
      enableUiDismiss: true, // [Optional] the ui is dimissible
      finishTimeout: 60, // [Optional] finish timeout in seconds
    )
        .then((response) {
      print(response.toJson());
      data["response"] = response.toJson();
    }).catchError((error) async {
      data["error"] = await error.toJson();
      if (error is PurchaseAuthenticationFailed) {
        print("error PurchaseAuthenticationFailed:");
        // when the authentication failed .
      } else if (error is PurchaseGeneralFailure) {
        print(
            // Handle general failure
            "error PurchaseGeneralFailure: ${jsonEncode(error.toJson())}");
      } else if (error is PurchaseInvalidStatus) {
        // Handle invalid status
        print("error PurchaseInvalidStatus: ${jsonEncode(error.toJson())}");
      } else if (error is PurchaseDeclined) {
        // when the payment declined.
        print("error PurchaseDeclined: ${jsonEncode(error.toJson())}");
      } else if (error is PurchaseRejected) {
        // Handle purchase rejected
        print("error PurchaseRejected: ${jsonEncode(error.toJson())}");
      }
    });
    setState(() {
      data;
    });
  }
}
