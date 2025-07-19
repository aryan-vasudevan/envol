# Clean Community iOS App

An iOS application that leverages AI to encourage community cleanup by detecting trash in images and verifying cleanup efforts.

## Features

### Current Implementation (Step 1)
- **Camera Integration**: Full camera functionality with permission handling
- **Image Capture Workflow**: Two-step process (before/after photos)
- **Modern UI**: Clean, intuitive interface with progress indicators
- **Image Preview**: Real-time preview of captured images
- **Simulated AI Processing**: Placeholder for AI integration

### Planned Features
- **Roboflow Integration**: Trash detection using computer vision models
- **Gemini 2.5 VLM**: Image comparison to verify cleanup completion
- **Points System**: Reward users for successful cleanups
- **Community Features**: Leaderboards and social sharing

## App Workflow

1. **Before Photo**: User takes a photo of an area with trash
2. **Cleanup**: User physically cleans the area
3. **After Photo**: User takes a photo of the cleaned area
4. **AI Processing**: App analyzes both images to verify cleanup
5. **Rewards**: User receives points for successful cleanup

## How to Run the App

### Prerequisites
- **Xcode 15.0 or later** (download from Mac App Store)
- **Physical iOS device** (iPhone/iPad) - Camera functionality won't work in simulator
- **Apple Developer Account** (free account works for testing)

### Step-by-Step Instructions

1. **Open the Project**
   ```bash
   # Navigate to your project directory
   cd /Users/aryanv/dev/envol
   
   # Open the Xcode project
   open envol.xcodeproj
   ```

2. **Configure Your Development Team**
   - In Xcode, click on the project name "envol" in the navigator
   - Select the "envol" target
   - Go to the "Signing & Capabilities" tab
   - Check "Automatically manage signing"
   - Select your Apple ID/Developer Team from the dropdown

3. **Connect Your Device**
   - Connect your iPhone/iPad to your Mac via USB
   - Make sure your device is unlocked
   - In Xcode, select your device from the device dropdown (top-left)

4. **Build and Run**
   - Press **⌘+R** or click the **Play** button (▶️)
   - Xcode will build the project and install it on your device
   - You may need to trust the developer on your device:
     - Go to **Settings > General > VPN & Device Management**
     - Find your Apple ID and tap "Trust"

5. **Grant Camera Permissions**
   When you first open the app, it will ask for camera permissions. Tap **"Allow"** to enable camera functionality.

## Project Structure

```
envol/
├── envolApp.swift              # App entry point
├── ContentView.swift           # Main interface
├── CameraManager.swift         # Camera permissions and setup
├── CameraView.swift            # Camera functionality
├── ImageProcessor.swift        # AI processing interface
└── Assets.xcassets/            # App assets
```

## Technical Architecture

### Core Components
- **ContentView**: Main app interface with workflow management
- **CameraManager**: Camera permissions and session management
- **CameraView**: Camera functionality using AVFoundation
- **ImageProcessorView**: AI processing interface (placeholder)

### Technologies Used
- **SwiftUI**: Modern declarative UI framework
- **AVFoundation**: Camera and media handling
- **UIKit**: Camera view controller integration

## Development Status

### ✅ Completed (Step 1)
- Basic iOS app structure
- Camera integration and permissions
- Two-step photo capture workflow
- Modern, responsive UI
- Image preview functionality
- Simulated processing flow

### 🔄 Next Steps
- Integrate Roboflow API for trash detection
- Implement Gemini 2.5 VLM for image comparison
- Add points system and user profiles
- Implement data persistence
- Add community features

## Troubleshooting

### Common Issues

1. **"Project is damaged" error**
   - Make sure you're opening `envol.xcodeproj` (not the other project files)
   - Try cleaning the build folder (Product > Clean Build Folder)

2. **Camera not working**
   - Ensure you're running on a physical device (not simulator)
   - Check that camera permissions are granted
   - Verify your device has a camera

3. **Build errors**
   - Make sure you have Xcode 15.0 or later
   - Check that your development team is properly configured
   - Try cleaning and rebuilding the project

## Contributing

This is the first step of a larger project. Future contributions will focus on:
- AI model integration
- Backend services
- Community features
- Performance optimization

## License

This project is for educational and community improvement purposes. 