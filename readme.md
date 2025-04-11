# Process Reporter

Process Reporter is a macOS application built with AppKit/Cocoa that monitors and reports real-time system activity. It tracks the foreground application and media playback information, providing a seamless way to share your current activity.

## Features

- **Real-time Application Monitoring**
  - Tracks the currently active application
  - Reports application name and state changes
  - Configurable update frequency

- **Media Playback Tracking**
  - Monitors system-wide media playback
  - Captures track information from supported media players

- **User Preferences**
  - Customizable reporting settings
  - Configurable update intervals

## Project Structure

```
ProcessReporter/
├── Core/
│   ├── Reporter/        # Reporting functionality
│   ├── Database/        # Data persistence
│   ├── NowPlaying/      # Media playback monitoring
│   └── ApplicationMonitor.swift
├── Components/          # UI components
├── Models/             # Data models
├── Preferences/        # User preferences
├── Windows/            # Application windows
└── Extensions/         # Swift extensions
```

## Integration

- **Shiro Integration**
  - Real-time activity reporting to Shiro servers
  - WebSocket-based notifications
  - Customizable API endpoints

- **Slack Integration** (Coming Soon)
  - Automatic profile updates
  - Customizable status messages
  - Emoji support

## Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/ProcessReporter.git
   ```

2. Open the project in Xcode:
   ```bash
   cd ProcessReporter
   open ProcessReporter.xcodeproj
   ```

3. Build and run the project

## Configuration

1. Launch the application
2. Navigate to Preferences
3. Configure your API endpoints and settings

## Dependencies

- Xcode 15+
- macOS 15+

## Development Status

🚧 This project is currently under active development. Features and APIs may change.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
