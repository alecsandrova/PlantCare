# PlantCare Mobile App

## Overview
PlantCare is a mobile application designed to work in conjunction with an Arduino-based smart plant care system. This app enables users to monitor and control the care of their plants through an intuitive and user-friendly interface.

## Features
- **Bluetooth Connectivity**: Connects seamlessly with your Arduino device using Bluetooth.
- **Soil Type Selection**: Choose the appropriate soil type for your plant.
- **Plant Type Selection**: Select from a variety of common houseplants.
- **Growth Stage Identification**: Indicate the current growth stage of your plant.
- **Watering Control**: Send commands to your Arduino to water plants with a predefined amount.

## Requirements
- Flutter environment setup.
- `flutter_blue` package.
- Arduino setup with Bluetooth capability.

## Installation
1. Clone the repository.
2. Run `flutter pub get` to install dependencies.
3. Build and run the app on your device or emulator.

## Usage
1. Open the app and connect to your Arduino device via Bluetooth.
2. Select the soil type, plant type, and growth stage from the dropdown menus.
3. Use the 'Submit' button to send watering commands to your Arduino.

