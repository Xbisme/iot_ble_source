import 'package:flutter/material.dart';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, required this.title}) : super(key: key);
  final String title;
  final FlutterBluePlus flutterBluePlus = FlutterBluePlus.instance;
  final List<BluetoothDevice> deviceList = <BluetoothDevice>[];
  final Map<Guid, List<int>> values = <Guid, List<int>>{};
  final Map<Guid, List<String>> stringValues = <Guid, List<String>>{};

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final _writeController = TextEditingController();
  BluetoothDevice? myDevice;
  List<BluetoothService> myServices = [];

  addDevice(final BluetoothDevice device) {
    if (!widget.deviceList.contains(device)) {
      setState(() {
        if (device.name != '') {
          widget.deviceList.add(device);
        }
      });
    }
  }

  @override
  void initState() {
    super.initState();
    widget.flutterBluePlus.connectedDevices
        .asStream()
        .listen((List<BluetoothDevice> devices) {
      for (BluetoothDevice device in devices) {
        addDevice(device);
      }
    });
    widget.flutterBluePlus.scanResults.listen((List<ScanResult> results) {
      for (ScanResult result in results) {
        if (result.device.name != '') {
          addDevice(result.device);
        }
      }
    });
    widget.flutterBluePlus.startScan();
  }

  ListView _buildListViewOfDevices() {
    List<Widget> containers = <Widget>[];
    for (BluetoothDevice device in widget.deviceList) {
      containers.add(
        SizedBox(
          height: 50,
          child: Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  children: <Widget>[
                    Text(device.name),
                    Text(device.id.toString()),
                  ],
                ),
              ),
              TextButton(
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all<Color>(
                      Colors.blue), // Màu của nút
                  foregroundColor: MaterialStateProperty.all<Color>(
                      Colors.yellow), // Màu của chữ
                ),
                child: const Text(
                  'Connect',
                ),
                onPressed: () async {
                  print("ABC");
                  widget.flutterBluePlus.stopScan();
                  try {
                    await device.connect();
                    print("1");
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const SecondRoute()));
                  } on PlatformException catch (e) {
                    print("2");

                    if (e.code != 'already_connected') {
                      rethrow;
                    }
                  } finally {
                    print("3");

                    myServices = await device.discoverServices();
                  }

                  setState(() {
                    myDevice = device;
                  });
                },
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(8),
      children: <Widget>[
        ...containers,
      ],
    );
  }

  List<ButtonTheme> _buildReadWriteNotifyButton(
      BluetoothCharacteristic characteristic) {
    List<ButtonTheme> buttons = <ButtonTheme>[];
    if (characteristic.properties.notify) {
      buttons.add(
        ButtonTheme(
          minWidth: 10,
          height: 20,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ElevatedButton(
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all<Color>(
                    Colors.blue), // Màu của nút
                foregroundColor: MaterialStateProperty.all<Color>(
                    Colors.yellow), // Màu của chữ
              ),
              child: const Text('Connected'),
              onPressed: () async {
                characteristic.value.listen((value) {
                  setState(() {
                    widget.values[characteristic.uuid] = value;
                    List<String> stringValue = [];
                    widget.values[characteristic.uuid]?.forEach((element) {
                      stringValue.add(String.fromCharCode(element));
                      widget.stringValues[characteristic.uuid] = stringValue;
                    });
                  });
                });
                await characteristic.setNotifyValue(true);
              },
            ),
          ),
        ),
      );
    }

    return buttons;
  }

  ListView _buildConnectDeviceView() {
    List<Widget> containers = <Widget>[];

    for (BluetoothService service in myServices) {
      Guid UUIDSer = Guid("0000ffe0-0000-1000-8000-00805f9b34fb");
      if (service.uuid == UUIDSer) {
        Guid UUID = Guid("0000ffe1-0000-1000-8000-00805f9b34fb");
        List<Widget> characteristicsWidget = <Widget>[];

        for (BluetoothCharacteristic characteristic
            in service.characteristics) {
          if (characteristic.uuid == UUID) {
            characteristicsWidget.add(
              Align(
                alignment: Alignment.centerLeft,
                child: Column(
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Text(characteristic.uuid.toString(),
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Row(
                      children: <Widget>[
                        ..._buildReadWriteNotifyButton(characteristic),
                      ],
                    ),
                    Row(
                      children: <Widget>[
                        Text(
                            'Value: ${widget.stringValues[characteristic.uuid]?.join()}'),
                      ],
                    ),
                    const Divider(),
                  ],
                ),
              ),
            );
          }
        }
        containers.add(
          ExpansionTile(
              title: Text(service.uuid.toString()),
              children: characteristicsWidget),
        );
      }
    }

    return ListView(
      padding: const EdgeInsets.all(8),
      children: <Widget>[
        ...containers,
      ],
    );
  }

  ListView _buildView() {
    if (myDevice != null) {
      return _buildConnectDeviceView();
    }
    return _buildListViewOfDevices();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
        ),
        body: _buildView(),
      );
}

class SecondRoute extends StatelessWidget {
  const SecondRoute({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Second Route'),
      ),
      // body: Center(
      //   child: ElevatedButton(
      //     onPressed: () {
      //       Navigator.pop(context);
      //     },
      //     child: const Text('Go back!'),
      //   ),
      // ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        const Text(
                          "Temperature",
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        Image.asset(
                          "asset/images/temperature.png",
                          width: 150,
                          fit: BoxFit.fill,
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        const Text("30.0")
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        const Text(
                          "Humidity",
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        Image.asset(
                          "asset/images/humidity.png",
                          width: 150,
                          fit: BoxFit.fill,
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        const Text("45.0%")
                      ],
                    ),
                  )
                ],
              ),
              const SizedBox(
                height: 20,
              ),
              Container(
                width: MediaQuery.of(context).size.width,
                decoration: BoxDecoration(
                    color: const Color(0xffff0000),
                    borderRadius: BorderRadius.circular(15)),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 15),
                  child: Text(
                    "Connected",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: Colors.white),
                  ),
                ),
              ),
              Row(
                children: [
                  const Text("Organization ID: ",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                  Expanded(
                      child: Padding(
                    padding: const EdgeInsets.only(bottom: 30),
                    child: TextFormField(
                      decoration: const InputDecoration(
                          contentPadding: EdgeInsets.only(top: 20)),
                    ),
                  ))
                ],
              ),
              Row(
                children: [
                  const Text("Device ID: ",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                  Expanded(
                      child: Padding(
                    padding: const EdgeInsets.only(bottom: 30),
                    child: TextFormField(
                      decoration: const InputDecoration(
                          contentPadding: EdgeInsets.only(top: 20)),
                    ),
                  ))
                ],
              ),
              Row(
                children: [
                  const Text("Authen Token: ",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                  Expanded(
                      child: Padding(
                    padding: const EdgeInsets.only(bottom: 30),
                    child: TextFormField(
                      decoration: const InputDecoration(
                          contentPadding: EdgeInsets.only(top: 20)),
                    ),
                  ))
                ],
              ),
              const Text("Hide Auth Token",
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xff2f2fff))),
              const SizedBox(
                height: 20,
              ),
              Container(
                width: MediaQuery.of(context).size.width,
                decoration: BoxDecoration(
                    color: const Color(0xff0000ff),
                    borderRadius: BorderRadius.circular(15)),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 15),
                  child: Text(
                    "Connected",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}