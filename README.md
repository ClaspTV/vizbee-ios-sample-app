# vizbee-ios-demo-app-spm

This README provides instructions on how to set up and run the vizbee-ios-demo-app-spm.

## Getting Started

Follow these steps to get the app running on your local machine.

### Prerequisites

- Xcode 12.0 or later
- iOS 12.0 or later
- Swift Package Manager
- CocoaPods (if applicable) 

For how to install Vizbeekit using CocoaPods refer to [VizbeeKit Setup Docs](https://console.vizbee.tv/app/vzb2000001/develop/guides/ios-continuity)

### Installation

1. Clone the repository:
   ```
   git clone https://github.com/ClaspTV/vizbee-ios-demo-app-spm.git
   ```

2. Navigate to the project directory:
   ```
   cd vizbee-ios-demo-app-spm
   ```

3. Open the Xcode project:
   ```
   open VizbeeDemo.xcodeproj
   ```

4. If using CocoaPods, install dependencies:
   ```
   pod install
   ```
   Then open the workspace instead of the project file:
   ```
   open VizbeeDemo.xcworkspace
   ```

5. In Xcode, go to the Signing & Capabilities tab and select your team for code signing.

### Configuration

1. Open the `AppDelegate.swift` file.

2. Replace the Demo Vizbee App ID with your actual App ID:
   ```swift
   VizbeeManager.shared.initialize(appId: "vzb2000001")
   ```
   
### Running the App

1. Select your target device or simulator in Xcode.

2. Click the Run button or press `Cmd + R` to build and run the app.

### Note on Vizbee SDK Integration
This demo app already includes the Vizbee SDK integration. For developers looking to integrate the Vizbee SDK into their own projects, please note:

- There are template files located at [/template/iOSSDKCodeSetupInstructions.md](./template/iOSSDKCodeSetupInstructions.md) in this repository.
- This files contains instructions and templates for integrating the VizbeeKit SDK into other iOS applications.
- It is not directly related to running this demo app but serves as a reference for other integration projects.

## Troubleshooting

If you encounter any issues:

1. Ensure all prerequisites are installed and up to date.
2. Clean the build folder in Xcode (Shift + Cmd + K) and rebuild.
3. If using CocoaPods, try deleting the Pods folder and running `pod install` again.

## Support

For any questions or support, please contact support@vizbee.tv or visit our documentation at https://console.vizbee.tv/app/vzb2000001/develop/guides/ios-continuity

