import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'dart:async';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Bluetooth Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.purple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Bluetooth Demo'),
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
  final flutterReactiveBle = FlutterReactiveBle();
  var _bleStatus = BleStatus.unknown;
  var _currentError = const GenericFailure<ScanFailure>(
      code: ScanFailure.unknown, message: "nothing yet");
  final List<DiscoveredDevice> _bleDevicesNearby = [];
  late StreamSubscription<DiscoveredDevice> _scanningSubscription;
  late StreamSubscription<BleStatus> _statusSubscription;
  final _scanDuration = const Duration(seconds: 5);

  bool isScanning = false;

  void _scanForDevices() {
    // clear the list of devices
    _bleDevicesNearby.clear();
    setState(() {
      isScanning = true;
    });
    // check the status of the ble module.
    _statusSubscription = flutterReactiveBle.statusStream.listen((status) {
      setState(() {
        _bleStatus = status;
      });
    });
    // switch case pretty much just for comments right now.
    switch (_bleStatus) {
      case BleStatus.unknown:
        break;
      case BleStatus.unsupported:
        // should notify the user that ble is unsupported
        break;
      case BleStatus.unauthorized:
        // Should ask for permissions if this happens.
        break;
      case BleStatus.poweredOff:
        // Should notify the user that they need to turn on bluetooth.
        break;
      case BleStatus.locationServicesDisabled:
        break;
      case BleStatus.ready:
      // should have no issues scanning here.
    }
    _scanningSubscription = flutterReactiveBle.scanForDevices(
      withServices: [],
      requireLocationServicesEnabled: false,
      scanMode: ScanMode.lowLatency,
    ).listen((DiscoveredDevice device) {
      setState(() {
        _bleDevicesNearby.add(device);
      });
    }, onError: (error) {
      setState(() {
        _currentError = error;
      });
    });

    Future.delayed(_scanDuration, () {
      setState(() {
        isScanning = false;
        _statusSubscription.cancel();
        _scanningSubscription.cancel();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Center(
          // Center is a layout widget. It takes a single child and positions it
          // in the middle of the parent.
          child: ListView(
            children: <Widget>[
              Text('BLE Status: $_bleStatus'),
              Text('Error: $_currentError'),
              const Text(
                'Peripherals Nearby',
              ),
              for (DiscoveredDevice peripheral in _bleDevicesNearby)
                Text(peripheral.name),
              Text(isScanning
                  ? 'scanning for devices...'
                  : _bleDevicesNearby.isEmpty
                      ? 'no devices found'
                      : ''),
            ],
          ),
        ),
      ),
      floatingActionButton: Row(
        mainAxisSize: MainAxisSize.min,
        // mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: _scanForDevices,
            tooltip: 'Refresh',
            child: const Icon(Icons.refresh),
          ),
        ],
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
