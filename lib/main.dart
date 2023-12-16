  import 'dart:ffi';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
  import 'dart:convert';

  import 'package:flutter/services.dart';
  import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import 'firebase_options.dart';

  void main()  {
    // await Firebase.initializeApp(
    //   options: DefaultFirebaseOptions.currentPlatform,
    // );
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

    @override
    State<MyHomePage> createState() => _MyHomePageState();
  }

  class _MyHomePageState extends State<MyHomePage> {
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

                    } on PlatformException catch (e) {
                      print("2");

                      if (e.code != 'already_connected') {
                        rethrow;
                      }
                    } finally {
                      print("3");

                      myServices = await device.discoverServices();
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => SecondRoute(
                                flutterBluePlus: widget.flutterBluePlus,
                                deviceList: widget.deviceList,
                                myServices: myServices,
                              )));
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

    ListView _buildView() {
      // if (myDevice != null) {
      //   return _buildConnectDeviceView();
      // }
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

  class SecondRoute extends StatefulWidget {
    final FlutterBluePlus flutterBluePlus;
    final List<BluetoothDevice> deviceList;
    final Map<Guid, List<int>> values;
    final Map<Guid, List<String>> stringValues;
    String temperature;
    String humidity;
    List<BluetoothService> myServices = [];

    SecondRoute({
      required this.flutterBluePlus,
      required this.deviceList,
      required this.myServices,
    })
        : values = <Guid, List<int>>{},
          stringValues = <Guid, List<String>>{},
          temperature = '',
          humidity = '';

  @override
  State<SecondRoute> createState() => _SecondRouteState();
}

class _SecondRouteState extends State<SecondRoute> {

     // List<ButtonTheme> _buildReadWriteNotifyButton(
    void getValue(BluetoothCharacteristic characteristic) async {

      characteristic.value.listen((value) {
        setState(() {
          String allValue = "";
          List<String> stringValue = [];
          widget.values[characteristic.uuid] = value;
          widget.values[characteristic.uuid]?.forEach((element) {
            stringValue.add(String.fromCharCode(element));
            widget.stringValues[characteristic.uuid] = stringValue;
          });
          stringValue.map((String currentValue) {
            allValue += currentValue;
          }).toList();
          List<String> parks = allValue.split(";");
          widget.temperature = parks[0].toString();
          widget.humidity = parks[1].toString();
          });
      });
          await characteristic.setNotifyValue(true);

  }

      @override
      Widget build(BuildContext context) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Second Route'),
          ),
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
                             Text(widget.temperature)
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
                             Text(widget.humidity)
                          ],
                        ),
                      )
                    ],
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  Container(
                    width: MediaQuery
                        .of(context)
                        .size
                        .width,
                  child: ButtonTheme(

                    child:  Padding(
                      padding: EdgeInsets.symmetric(vertical: 15),
                      child: ElevatedButton(
                        style: ButtonStyle(
                          backgroundColor: MaterialStateProperty.all<Color>(Colors.red),
                          foregroundColor: MaterialStateProperty.all<Color>(Colors.white),
                        ),
                        child: const Text('Connected'),
                        onPressed: () {
                          for (BluetoothService service in widget.myServices) {
                          Guid UUIDSer = Guid("0000ffe0-0000-1000-8000-00805f9b34fb");
                          if (service.uuid == UUIDSer) {
                            Guid UUID = Guid("0000ffe1-0000-1000-8000-00805f9b34fb");
                            for (BluetoothCharacteristic characteristic
                            in service.characteristics) {
                              if (characteristic.uuid == UUID) {
                                print("Found UUID");
                                if (characteristic.properties.notify) {
                                  print("truehihi");
                                  getValue(characteristic);
                                }
                              }
                            }
                          }
                          }
                        },
                      ),
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
                    width: MediaQuery
                        .of(context)
                        .size
                        .width,
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