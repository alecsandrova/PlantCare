// Imports necessary libraries for Dart and Flutter functionalities
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';



// Constants for Bluetooth UUID and target device MAC address
// These need to be changed for your own bluetooth module
const String bluetoothCharacteristicUUID =
    '00001101-0000-1000-8000-00805F9B34FB';
const String targetDeviceMacAddress = '00:22:12:01:8D:E7';

void main() {
  runApp(MyApp());
}


// The main app widget that sets up the theme and home page
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(fontFamily: 'Roboto'),
      home: MyHomePage(),
    );
  }
}

// The home page widget, a stateful widget for dynamic content
class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

// State class for the home page, managing UI and logic
class _MyHomePageState extends State<MyHomePage> {
  // Lists of options for soil types, plant types, and growth stages
  List<String> soilTypes = [
    "Sol bine drenat pentru plante suculente sau cactuși",
    "Amestec de pământ de grădină, nisip și material de drenaj",
    "Amestec de sol pentru plante cu flori sau plante de apartament"
  ];
  List<String> plantTypes = [
    "Dragonier (Dracaena marginata)",
    "Muscata (Pelargonium)",
    "Planta dinozaur (Zamioculcas zamiifolia)",
    "Floarea flamingo (Anthurium mix)",
    "Crizantema (Chrysanthemum Zembla alb)"
  ];
  List<String> growthStages = [
    "Perioada de creștere activă (primăvara și vara)",
    "Perioada de repaus (toamna și iarna):"
  ];

  // Variables for user selections and Bluetooth connectivity
  String? selectedSoil;
  String? selectedPlant;
  String? selectedGrowthStage;

  int scanAttempts = 0;
  final int maxScanAttempts = 10; // number of attempts the app will make to connect to the bluetooth device
  final int scanTimeoutSeconds = 10; //number of seconds a scan will take
  String lastLogMessage = ''; // log messages used to give more details to the user

  BluetoothDevice? targetDevice;
  FlutterBluetoothSerial bluetoothSerial = FlutterBluetoothSerial.instance;
  BluetoothConnection? connection;
  List<BluetoothDevice> devices = [];

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

// Initialization logic for requesting Bluetooth permissions and setup
  @override
  void initState() {
    super.initState();
    requestBluetoothConnectPermission().then((_) {
      initBluetooth();
    });
  }

  // Function that calculates the number of water pumps required for a given plant,
  // based on its soil type, plant type, and growth stage.
  int calculateWater(String? selectedSoil, String? selectedPlant,
      String? selectedGrowthStage) {
    // A map that holds the base water requirements for various combinations of plant types
    // and their growth stages. Each combination has an associated water requirement value.
    Map<String, int> baseWaterRequirements = {
      "Dragonier (Dracaena marginata)Active": 300,
      "Dragonier (Dracaena marginata)Dormant": 175,
      "Muscata (Pelargonium)Active": 250,
      "Muscata (Pelargonium)Dormant": 175,
      "Planta dinozaur (Zamioculcas zamiifolia)Active": 250,
      "Planta dinozaur (Zamioculcas zamiifolia)Dormant": 175,
      "Floarea flamingo (Anthurium mix)Active": 250,
      "Floarea flamingo (Anthurium mix)Dormant": 175,
      "Crizantema (Chrysanthemum Zembla alb)Active": 250,
      "Crizantema (Chrysanthemum Zembla alb)Dormant": 175
    };

    // A map that defines adjustment factors for different soil types. These factors
    // are used to modify the base water requirements based on the soil characteristics.
    Map<String, double> soilAdjustmentFactors = {
      "Sol bine drenat pentru plante suculente sau cactuși": 1.0,
      "Amestec de pământ de grădină, nisip și material de drenaj": 1.1,
      "Amestec de sol pentru plante cu flori sau plante de apartament": 0.9
    };

    // Defining a helper function 'getKey' to generate a key for accessing the water requirement data.
    // This key is based on the plant type and its growth stage
    String getKey(String? plant, String? growthStage) {
      // The growth stage is determined here. If the stage includes the word "activă",
      // it is considered 'Active'; otherwise, it is 'Dormant'.
      String stage = growthStage!.contains("activă") ? "Active" : "Dormant";
      return "$plant$stage";
    }

    // Generating the key using the selected plant and growth stage.
    String key = getKey(selectedPlant, selectedGrowthStage);

    // Getting the base water requirement for the generated key.
    // If the key does not exist in the map, it defaults to 0.
    int baseWaterRequirement = baseWaterRequirements[key] ?? 0;

    // Getting the soil adjustment factor based on the selected soil type.
    // If the selected soil type does not exist in the map, it defaults to 1.0.
    double soilFactor = soilAdjustmentFactors[selectedSoil] ?? 1.0;

    // Calculating the adjusted water requirement by multiplying the base requirement
    // by the soil factor. The result is then rounded to the nearest integer.
    int adjustedWaterRequirement = (baseWaterRequirement * soilFactor).round();

    // Calculating the number of pumps required to pump the necessary water requirement.
    // Assumes that one pump delivers 25ml of water. The result is rounded up
    int numberOfPumps = (adjustedWaterRequirement / 25).ceil();

    // Returning the calculated number of pumps.
    return numberOfPumps;
  }

  void sendData(String data) {
    if (connection != null && connection!.isConnected) {
      connection!.output.add(utf8.encode(data));
      //wait for data to be sent before closing the connection
      connection!.output.allSent.then((_) {
        addLogMessage('Data sent' + data);
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
    // Request necessary Bluetooth permissions at runtime
    await requestBluetoothPermissions();

    var isBluetoothEnabled = await bluetoothSerial.isEnabled;
    if (!isBluetoothEnabled!) {
      await bluetoothSerial.requestEnable();
      addLogMessage('Bluetooth enabled');
      print('Bluetooth enabled');
    }
    discoverDevices();
  }

  Future<void> requestBluetoothPermissions() async {
    var scanPermission = await Permission.bluetoothScan.status;
    if (!scanPermission.isGranted) {
      await Permission.bluetoothScan.request();
    }

    var connectPermission = await Permission.bluetoothConnect.status;
    if (!connectPermission.isGranted) {
      await Permission.bluetoothConnect.request();
    }
  }

  void discoverDevices() async {
    print('Discovering devices...');
    addLogMessage('Discovering devices...');
    // Get the list of paired devices
    devices = await bluetoothSerial.getBondedDevices();
    setState(() {});

    // Connect to the target device by its MAC address
    for (BluetoothDevice device in devices) {
      print('Discovered device: ' + device.address);
      addLogMessage('Discovered device:: ' + device.address);
      if (device.address == targetDeviceMacAddress) {
        print('Found device ' + device.address);
        addLogMessage('Found device ' + device.address);
        connectToDevice(device);
        break;
      }
    }
  }

  void connectToDevice(BluetoothDevice device) async {
    try {
      connection = await BluetoothConnection.toAddress(device.address);
      // setState() is called here to trigger a rebuild of the widget
      setState(() {});
      addLogMessage('Connected to the device');
      print('Connected to the device');


      //This line sets up a listener for incoming data on the Bluetooth connection.
      // The '!' operator is known as the null assertion operator
      // It's a way of asserting that these objects will definitely be non-null
      connection!.input!.listen((Uint8List data) {
        String receivedMessage = String.fromCharCodes(data);
        if (receivedMessage == "Plant needs water!")//
          addLogMessage("Plant needs water!");
        else {
          print('Received message: $receivedMessage');
          addLogMessage('Received message: $receivedMessage');
        }
      }).onDone(() {//
        // Handle connection being closed
        print('Disconnected by remote request');
        addLogMessage('Disconnected by remote request');
      });
    } catch (exception) {
      print('Cannot connect, exception occurred: $exception');
      addLogMessage(
        'Cannot connect, exception occurred',
      );
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


  // UI build method for rendering the app's interface
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
      // UI components like dropdowns, buttons, and text widgets
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
                      // Check selections
                      if (selectedPlant != null &&
                          selectedSoil != null &&
                          selectedGrowthStage != null) {
                        // pumps gets the number of water pumps it will send based on se selections made
                        int pumps = calculateWater(
                            selectedSoil, selectedPlant, selectedGrowthStage);
                        String dataToSend = pumps.toString();
                        // data is sent to the bluetooth module
                        sendData(dataToSend);
                      } else {
                        // Handle the case where not all selections are made
                        addLogMessage(
                            'Please select soil, plant, and growth stage');
                      }
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

                  Text("Last Log Message:",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),

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
