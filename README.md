# فلوسي | My Money

**فلوسك تحت سيطرتك** - Your Money Under Control

A completely free, open-source personal money organization application built with Flutter.

## Features

### Core Functionality
- **Monthly Income Tracking**: Enter and track your monthly income
- **Recurring Expenses**: Manage fixed monthly bills (rent, utilities, subscriptions, installments)
- **Variable Expenses**: Track daily spending
- **Budget Dashboard**: See remaining money at a glance
- **Savings Goals**: Set and track savings targets
- **Monthly Reports**: View spending summaries and trends
- **Statistics & Charts**: Visualize your financial habits

### Technical Features
- **Offline-First**: Works without internet connection
- **Local Database**: SQLite for secure local storage
- **Dark/Light Mode**: Full theme support
- **Bilingual**: Arabic (RTL) and English (LTR) support
- **Privacy-First**: No data collection, no tracking
- **Free Forever**: No paid features, no subscriptions

### Monetization
The app is completely free with ethical, non-intrusive advertising only.

## Getting Started

### Prerequisites
- Flutter SDK 3.24.0 or higher
- Dart 3.5.0 or higher
- Android Studio / Xcode for mobile development

### Installation

1. Clone the repository:
```bash
git clone <repository-url>
cd flousi_app
```

2. Install dependencies:
```bash
flutter pub get
```

3. Run the app:
```bash
flutter run
```

## Project Structure

```
lib/
├── core/
│   ├── theme/          # App theming
│   └── localization/   # i18n support
├── data/
│   └── local/          # SQLite database
├── domain/
│   └── models/         # Business models
├── features/
│   ├── auth/           # Authentication
│   ├── onboarding/     # First-time setup
│   ├── dashboard/      # Main dashboard
│   ├── expenses/       # Expense management
│   ├── budget/         # Budget planning
│   └── settings/       # App settings
├── services/           # Shared services
└── main.dart           # App entry point
```

## Architecture

The app follows Clean Architecture principles:
- **Presentation Layer**: Flutter UI components
- **Domain Layer**: Business logic and models
- **Data Layer**: Database and repositories

## Technology Stack

- **Frontend**: Flutter + Dart
- **State Management**: Provider
- **Local Database**: SQLite (sqflite)
- **Preferences**: SharedPreferences
- **Charts**: fl_chart
- **Localization**: Flutter intl

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## Support

For issues and feature requests, please open an issue on GitHub.

---

**فلوسي | My Money** - Built with ❤️ for financial freedom
