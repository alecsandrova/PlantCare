import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  // Dummy data for the dropdowns
  List<String> soilTypes = ["Sol bine drenat pentru plante suculente sau cactuși", "Amestec de pământ de grădină, nisip și material de drenaj", "Amestec de sol pentru plante cu flori sau plante de apartament"];
  List<String> plantTypes = ["Dragonier (Dracaena marginata)", "Muscata (Pelargonium)", "Planta dinozaur (Zamioculcas zamiifolia) ", "Floarea flamingo (Anthurium mix)", "Crizantema (Chrysanthemum Zembla alb)"];
  List<String> growthStages = ["Perioada de creștere activă (primăvara și vara)", "Perioada de repaus (toamna și iarna):"];

  String? selectedSoil;
  String? selectedPlant;
  String? selectedGrowthStage;

  TextEditingController plantController = TextEditingController();
  bool showPlantSuggestions = false;

  @override
  void dispose() {
    plantController.dispose();
    super.dispose();
  }

  List<String> filterPlantOptions(String query) {
    if (query.isEmpty) {
      return [];
    }
    return plantTypes.where((plant) => plant.toLowerCase().contains(query.toLowerCase())).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'PlantCare',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // Soil Dropdown
              // Soil Dropdown
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    "Select Soil",
                    style: TextStyle(fontSize: 18),
                  ),
                  Card(
                    elevation: 5,
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Container(  // Wrap DropdownButton with Container
                        alignment: Alignment.centerRight,  // Align the icon to the right
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
                                alignment: Alignment.centerLeft,  // Align the text to the right
                                constraints: BoxConstraints(maxWidth: 300),  // Set the maximum width
                                child: Text(
                                  soil,
                                  style: TextStyle(color: Colors.black),
                                ),
                              ),
                            );
                          }).toList(),
                          icon: Icon(Icons.arrow_drop_down), // Customize the arrow icon
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
                  Text("Select Plant", style: TextStyle(fontSize: 18)),
                  Card(
                    elevation: 5,
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
                              alignment: Alignment.centerLeft,  // Align the text to the right
                              constraints: BoxConstraints(maxWidth: 300),  // Set the maximum width
                              child: Text(
                                plant,
                                style: TextStyle(color: Colors.black),
                              ),
                            ),
                          );
                        }).toList(),
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
                  Text("Select Growth Stage", style: TextStyle(fontSize: 18)),
                  Card(
                    elevation: 5,
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
                              alignment: Alignment.centerLeft,  // Align the text to the right
                              constraints: BoxConstraints(maxWidth: 300),  // Set the maximum width
                              child: Text(
                                stage,
                                style: TextStyle(color: Colors.black),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 20),

              // Display selected items
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
                },
                child: Text('Submit'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
