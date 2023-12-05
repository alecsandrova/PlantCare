import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:google_fonts/google_fonts.dart';


const String bluetoothCharacteristicUUID = '0000ffe1-0000-1000-8000-00805f9b34fb';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme:ThemeData(fontFamily: 'Roboto'),
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

  TextEditingController plantController = TextEditingController();
  bool showPlantSuggestions = false;

  FlutterBlue flutterBlue = FlutterBlue.instance;
  BluetoothDevice? targetDevice;
  BluetoothCharacteristic? characteristic;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    initBluetooth();
  }

  Future<void> initBluetooth() async {
    await flutterBlue.isOn;
    flutterBlue.scanResults.listen((List<ScanResult> results) {
      for (ScanResult result in results) {
        if (result.device.name == 'YourArduinoBluetoothName') {
          setState(() {
            targetDevice = result.device;
          });
          return;
        }
      }
    });

    targetDevice?.connect();
    targetDevice?.state.listen((BluetoothDeviceState state) {
      if (state == BluetoothDeviceState.connected) {
        discoverServices();
      }
    });
  }

  Future<void> discoverServices() async {
    List<BluetoothService> services = await targetDevice!.discoverServices();
    services.forEach((service) {
      service.characteristics.forEach((char) {
        print('Characteristic UUID: ${char.uuid}');
        if (char.uuid.toString() == bluetoothCharacteristicUUID) {
          setState(() {
            characteristic = char;
          });

          // Listen for incoming data
          characteristic!.setNotifyValue(true);
          characteristic!.value.listen((List<int> value) {
            String receivedMessage = String.fromCharCodes(value);
            // Handle the received message as needed
            print('Received message: $receivedMessage');

            if (receivedMessage.toLowerCase() == 'plant needs water') {
              // Show in-app notification for "plant needs water" (SnackBar)
              _showSnackBar('Your plant needs water!');
            } else if (receivedMessage.toLowerCase() == 'no water') {
              // Show in-app notification for "no water" (SnackBar)
              _showSnackBar('No water!');
            }
          });
        }
      });
    });
  }

  // Helper method to show SnackBar
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
                          icon: Icon(Icons.arrow_drop_down, color: Colors.blue),
                          style: TextStyle(color: Colors.blue, fontSize: 16),
                          dropdownColor: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 20),

              // Plant Dropdown with Search Bar
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                      "Select Plant",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      )
                  ),
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

              // Growth Stage Dropdown
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                      "Select Growth Stage",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      )
                  ),
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

              // Submit Button
              ElevatedButton(
                onPressed: () {
                  // Handle submission here
                  if (characteristic != null) {
                    // Send "100" (representing 100ml) to Arduino
                    characteristic!.write(utf8.encode('100'));
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
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  elevation: 5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
