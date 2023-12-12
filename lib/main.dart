import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

const String bluetoothCharacteristicUUID =
    '00001101-0000-1000-8000-00805F9B34FB';
const String targetDeviceMacAddress = '00:22:12:01:8D:E7';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(fontFamily: 'Roboto'),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<String> soilTypes = [
    "Sol bine drenat pentru plante suculente sau cactuși",
    "Amestec de pământ de grădină, nisip și material de drenaj",
    "Amestec de sol pentru plante cu flori sau plante de apartament"
  ];
  List<String> plantTypes = [
    "Dragonier (Dracaena marginata)",
    "Muscata (Pelargonium)",
    "Planta dinozaur (Zamioculcas zamiifolia) ",
    "Floarea flamingo (Anthurium mix)",
    "Crizantema (Chrysanthemum Zembla alb)"
  ];
  List<String> growthStages = [
    "Perioada de creștere activă (primăvara și vara)",
    "Perioada de repaus (toamna și iarna):"
  ];

  String? selectedSoil;
  String? selectedPlant;
  String? selectedGrowthStage;


  int scanAttempts = 0;
  final int maxScanAttempts = 10;
  final int scanTimeoutSeconds = 10;
  String lastLogMessage = '';

  BluetoothDevice? targetDevice;
  FlutterBluetoothSerial bluetoothSerial = FlutterBluetoothSerial.instance;
  BluetoothConnection? connection;
  List<BluetoothDevice> devices = [];

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    requestBluetoothConnectPermission().then((_) {
      initBluetooth();
    });
  }


  void sendData(String data) {
    if (connection != null && connection!.isConnected) {
      connection!.output.add(utf8.encode(data));
      // It's a good practice to wait for data to be sent before closing the connection
      connection!.output.allSent.then((_) {
        addLogMessage('Data sent' + utf8.encode(data).toString() );
      });
    } else {
      addLogMessage('No connected device');
    }
  }


  void retryScan() {
    print('Retrying scan...');
    addLogMessage('Retrying scan...');
    setState(() {
      scanAttempts = 0;
      targetDevice = null;
      lastLogMessage = '';
    });
    discoverDevices();
  }

  void addLogMessage(String message) {
    setState(() {
      lastLogMessage = message;
    });
  }

  Future<void> requestBluetoothPermission() async {
    var status = await Permission.bluetoothScan.status;
    if (!status.isGranted) {
      await Permission.bluetoothScan.request();
    }
  }


  Future<void> requestBluetoothConnectPermission() async {
    var status = await Permission.bluetoothConnect.status;
    if (!status.isGranted) {
      await Permission.bluetoothConnect.request();
    }
  }


  Future<void> initBluetooth() async {
    var isBluetoothEnabled = await bluetoothSerial.isEnabled;
    if (!isBluetoothEnabled!) {
      await bluetoothSerial.requestEnable();
      addLogMessage('Bluetooth enabled');
      print('Bluetooth enabled');
    }
    discoverDevices();
  }

  void discoverDevices() async {
    print('Discovering devices...');
    addLogMessage('Discovering devices...');
    // Get the list of paired devices
    devices = await bluetoothSerial.getBondedDevices();
    setState(() {});

    // Connect to the target device by its MAC address
    for (BluetoothDevice device in devices) {
      print('Discovered device: '+  device.address);
      addLogMessage('Discovered device:: '+  device.address);
      if (device.address == targetDeviceMacAddress) {
        print('Found device '+  device.address );
        addLogMessage('Found device ' +  device.address);
        connectToDevice(device);
        break;
      }
    }
  }

  void connectToDevice(BluetoothDevice device) async {
    try {
      connection = await BluetoothConnection.toAddress(device.address);
      setState(() {});
      addLogMessage('Connected to the device');
      print('Connected to the device');

      connection!.input!.listen((Uint8List data) {
        String receivedMessage = String.fromCharCodes(data);
        if(receivedMessage == "Plant needs water!")
          addLogMessage("Plant needs water!");
        else {
          print('Received message: $receivedMessage');
          addLogMessage('Received message: $receivedMessage');
        }

      }).onDone(() {
        // Handle connection being closed
        print('Disconnected by remote request');
        addLogMessage('Disconnected by remote request');
      });
    } catch (exception) {
      print('Cannot connect, exception occurred');
      addLogMessage('Cannot connect, exception occurred');
    }
  }

  @override
  void dispose() {
    connection?.dispose();
    super.dispose();
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text(
          'PlantCare',
          style: GoogleFonts.roboto(
            textStyle: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Center(
            child: Center(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  // Soil Dropdown
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        "Select Soil",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      Card(
                        elevation: 5,
                        color: Colors.white,
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Container(
                            alignment: Alignment.centerRight,
                            child: DropdownButton<String>(
                              value: selectedSoil,
                              onChanged: (String? newValue) {
                                setState(() {
                                  selectedSoil = newValue;
                                });
                              },
                              items: soilTypes.map((String soil) {
                                return DropdownMenuItem<String>(
                                  value: soil,
                                  child: Container(
                                    alignment: Alignment.centerLeft,
                                    constraints: BoxConstraints(maxWidth: 300),
                                    child: Text(
                                      soil,
                                      style: TextStyle(color: Colors.blue),
                                    ),
                                  ),
                                );
                              }).toList(),
                              icon: Icon(Icons.arrow_drop_down,
                                  color: Colors.blue),
                              style:
                                  TextStyle(color: Colors.blue, fontSize: 16),
                              dropdownColor: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 20),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text("Select Plant",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          )),
                      Card(
                        elevation: 5,
                        color: Colors.white,
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: DropdownButton<String>(
                            value: selectedPlant,
                            onChanged: (String? newValue) {
                              setState(() {
                                selectedPlant = newValue;
                              });
                            },
                            items: plantTypes.map((String plant) {
                              return DropdownMenuItem<String>(
                                value: plant,
                                child: Container(
                                  alignment: Alignment.centerLeft,
                                  constraints: BoxConstraints(maxWidth: 300),
                                  child: Text(
                                    plant,
                                    style: TextStyle(color: Colors.blue),
                                  ),
                                ),
                              );
                            }).toList(),
                            style: TextStyle(color: Colors.blue, fontSize: 16),
                            dropdownColor: Colors.white,
                            iconEnabledColor: Colors.blue,
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 20),

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text("Select Growth Stage",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          )),
                      Card(
                        elevation: 5,
                        color: Colors.white,
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: DropdownButton<String>(
                            value: selectedGrowthStage,
                            onChanged: (String? newValue) {
                              setState(() {
                                selectedGrowthStage = newValue;
                              });
                            },
                            items: growthStages.map((String stage) {
                              return DropdownMenuItem<String>(
                                value: stage,
                                child: Container(
                                  alignment: Alignment.centerLeft,
                                  constraints: BoxConstraints(maxWidth: 300),
                                  child: Text(
                                    stage,
                                    style: TextStyle(color: Colors.blue),
                                  ),
                                ),
                              );
                            }).toList(),
                            style: TextStyle(color: Colors.blue, fontSize: 16),
                            dropdownColor: Colors.white,
                            iconEnabledColor: Colors.blue,
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 20),

                  Text(
                    'Selected Soil: ${selectedSoil ?? "Select a Soil"}',
                    style: TextStyle(fontSize: 18),
                  ),
                  Text(
                    'Selected Plant: ${selectedPlant ?? "Select a Plant"}',
                    style: TextStyle(fontSize: 18),
                  ),
                  Text(
                    'Selected Growth Stage: ${selectedGrowthStage ?? "Select a Growth Stage"}',
                    style: TextStyle(fontSize: 18),
                  ),

                  SizedBox(height: 20),

                  ElevatedButton(
                    onPressed: () {
                      sendData('100'); // Sending '100' as an example
                    },
                    child: Text(
                      'Submit',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      primary: Colors.blue,
                      onPrimary: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding:
                          EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      elevation: 5,
                    ),
                  ),
                  SizedBox(height: 20),

                  Text("Last Log Message:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),

                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      lastLogMessage,
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                  Text("Target device: 00:22:12:01:8d:e7"),
                  ElevatedButton(
                    onPressed: retryScan,
                    child: Text('Retry Scan'),
                    style: ElevatedButton.styleFrom(
                      primary: Colors.blue,
                      onPrimary: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
