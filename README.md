# Simpelbudget
![App Icon](assets/icon/app_icon.png)
Simpelbudget is a budget tracking Flutter application that helps you manage your expenses and incomes efficiently. It supports manual entry as well as receipt scanning with OCR and AI-powered detail extraction.

## Features

- Add, edit, and delete transactions (expenses and incomes)
- Scan receipt images using Google ML Kit text recognition
- Extract structured receipt details (items, subtotal, total, tax) via OpenAI Chat API
- View summary dashboard for your current billing period
- View detailed transaction list with filtering options
- Configure billing cycle cutoff day and currency in settings
- Persistent local storage using SQLite
- Internationalization support (English and Indonesian)
- Cross-platform support: Android, iOS, Web, macOS, Windows, Linux

## Prerequisites

- Flutter SDK (>= 3.7.2)
- Dart SDK
- OpenAI API key

## Setup

1. Clone the repository:

   ```bash
   git clone <repository-url>
   cd simpelbudget
   ```

2. Install dependencies:

   ```bash
   flutter pub get
   ```

3. Create a `.env` file in the project root with your OpenAI API key:

   ```
   OPENAI_API_KEY=your_openai_api_key_here
   ```

4. Ensure the `.env` file is included in the Flutter assets (configured in `pubspec.yaml`).

## Running the App

- To run on a connected device or simulator:

  ```bash
  flutter run
  ```

- To specify a platform:

  ```bash
  flutter run -d android
  flutter run -d ios
  flutter run -d chrome
  ```

## Building

- Build Android APK:

  ```bash
  flutter build apk --release
  ```

- Build iOS (requires a Mac):

  ```bash
  flutter build ios --release
  ```

- Build Web:

  ```bash
  flutter build web --release
  ```

- Build macOS:

  ```bash
  flutter build macos --release
  ```

- Build Windows:

  ```bash
  flutter build windows --release
  ```

- Build Linux:

  ```bash
  flutter build linux --release
  ```

## Testing

Run unit and widget tests:

```bash
flutter test
```

## Project Structure

```
.
├── android/            # Android platform code
├── ios/                # iOS platform code
├── web/                # Web build target
├── macos/              # macOS platform code
├── windows/            # Windows platform code
├── linux/              # Linux platform code
├── lib/                # Dart source code
│   ├── l10n/           # Localization resource files (ARB)
│   ├── main.dart       # App entry point and routing
│   ├── models/         # Data model classes
│   ├── pages/          # UI screen implementations
│   ├── services/       # Data access and business logic
│   └── widgets/        # Reusable widgets
├── test/               # Automated tests
├── .env                # Environment variables (OpenAI API key)
└── pubspec.yaml        # Project configuration and dependencies
```

## Contributing

Contributions are welcome! Feel free to open issues or submit pull requests for bug fixes and enhancements.

## Acknowledgements

- [Flutter](https://flutter.dev)
- [Google ML Kit Text Recognition](https://pub.dev/packages/google_mlkit_text_recognition)
- [OpenAI API](https://openai.com)
- [sqflite](https://pub.dev/packages/sqflite)

**Happy budgeting!**
