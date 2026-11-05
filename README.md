💰 Kharcha – Personal Expense Tracker

Kharcha is a Flutter-based personal expense tracking application designed to help users manage their daily expenses, monitor monthly budgets and understand their spending habits.

🚀 Features

- Add, edit and delete expenses
- Undo deleted expenses
- Manage monthly budgets
- Organize expenses by categories
- Track payment methods
- Search, filter and sort expenses
- Monthly expense summaries and charts
- Attach receipt or item images
- Store expense data locally
- Export expense data in CSV format

🛠️ Tech Stack

- Frontend: Flutter
- Programming Language: Dart
- Storage: SharedPreferences
- Development Tools: VS Code / Android Studio
- Version Control: Git & GitHub

📂 Project Structure

Kharcha/
├── android/
├── ios/
├── lib/
│   └── main.dart
├── assets/
├── test/
├── pubspec.yaml
├── analysis_options.yaml
└── README.md

The project structure will be updated as the codebase is reorganized.

⚙️ Installation & Setup

1. Clone the repository:

git clone https://github.com/Nagasaipraveen/Kharcha-expense-tracker.git

2. Navigate to the project directory:

cd Kharcha-expense-tracker

3. Install dependencies:

flutter pub get

4. Run the application:

flutter run

👨‍💻 Development Team

Team Member| Responsibility
Nagasaipraveen| Project Lead & Core Development
Saakethnch| Analytics & Reports
Pavan| Data Management & Testing

Contributions and responsibilities will be updated based on actual completed work.

🎯 Project Objective

The main objective of Kharcha is to provide a simple and convenient way for users to track their spending, manage budgets and develop better financial habits.

📌 Future Enhancements

- Dark Mode
- Income Tracking
- Advanced Financial Reports
- Data Backup & Restore
- Improved Data Storage
- Automated Testing

📄 License

This project is currently developed as an academic and portfolio project.

## 📱 App Screenshots

### Dashboard
![Kharcha Dashboard](Screenshot%202026-11-05%20132806.png)

### Expense Management
![Expense Management](Screenshot%202026-11-05%20132841.png)

### Insights
![Kharcha Insights](Screenshot%202026-11-05%20132928.png)

Data Management & Testing – 248x1a0513-arch: Responsible for contributing to the data management functionality of the Kharcha Expense Tracker, including expense data organization, storage and retrieval improvements, data consistency, and application testing. The role focuses on improving data reliability, identifying issues, and ensuring a smooth and accurate expense-tracking experience.

Analytics & Reports – Saakethnch: Responsible for developing and improving the Analytics and Insights module of the Kharcha Expense Tracker. Focuses on generating monthly expense summaries, category-wise spending breakdowns, visual charts, and spending trends to help users understand their financial habits and make better budgeting decisions.

💰 Kharcha – Personal Expense Tracker

Kharcha is a Flutter-based personal expense tracker designed to help users manage their daily expenses, monitor monthly budgets, and understand their spending habits.

The application provides a simple and user-friendly interface to record transactions, organise expenses into categories, and track personal finances in one place.

1. Features

Area| Details
Add Expenses| Record daily expenses by entering the amount, category, date, payment method, and optional description.
Edit & Delete Expenses| Update existing expense records or delete transactions when needed.
Undo Delete| Restore recently deleted expenses using the undo option.
Dashboard| View monthly budget, total expenses, remaining balance, and a summary of spending.
Monthly Budget| Set and monitor a monthly spending budget to manage expenses effectively.
Expense Categories| Organise transactions into categories to understand where money is being spent.
Payment Methods| Track expenses based on different payment methods.
Search & Filters| Search, filter, and sort expenses to find specific transactions easily.
Spending Insights| View monthly expense summaries and charts to understand spending patterns.
Receipt Attachments| Attach receipt or item images to expense records for better tracking.
Data Storage| Store expense information locally on the device.
CSV Export| Export expense records into CSV format for further use and analysis.

2. Technology Stack

Layer| Technology
Framework| Flutter
Programming Language| Dart
UI Development| Flutter Material Widgets
Development Environment| Visual Studio Code / Android Studio
Data Storage| SharedPreferences (local storage)
Version Control| Git
Code Hosting| GitHub

3. Architecture

Kharcha follows a structured Flutter application organisation to keep the code readable, maintainable, and easier to extend.

lib/
│
├── main.dart
│
├── models/
│   └── expense.dart
│
├── screens/
│   ├── dashboard_screen.dart
│   ├── add_expense_screen.dart
│   ├── expenses_screen.dart
│   └── insights_screen.dart
│
├── widgets/
│   ├── expense_card.dart
│   └── summary_card.dart
│
├── services/
│   └── storage_service.dart
│
└── utils/
    └── app_constants.dart

The application is organised into reusable UI components, expense-related data models, screens, and supporting services. This structure helps make future updates and feature development easier.

Note: Update this folder structure to match the actual files in the repository.

4. User Interface & Screenshots

Kharcha is designed with a clean and user-friendly interface that makes expense tracking simple and convenient.

The dashboard provides an overview of monthly spending, while the expense and insights sections help users manage and understand their financial activity.

<!-- Add actual application screenshots here -->5. Data Storage & Privacy

Kharcha is designed to keep personal expense records stored locally on the user's device.

- Expense information is stored locally using the application's configured storage system.
- Users can record and manage their own transactions.
- Expense data can be exported in CSV format.
- The application does not require a cloud account to use its local expense-tracking features.

The storage and privacy behaviour depends on the application's implemented configuration.

6. Getting Started

Prerequisites

Tool| Requirement
Flutter SDK| Installed and configured
Dart SDK| Included with Flutter
Android Studio / VS Code| Recommended development environment
Git| Required to clone and manage the repository

Installation

1. Clone the repository

git clone https://github.com/Nagasaipraveen/Kharcha-expense-tracker.git

2. Navigate to the project directory

cd Kharcha-expense-tracker

3. Install dependencies

flutter pub get

4. Run the application

flutter run

7. Platform Support

Kharcha is developed using Flutter, which supports building applications for multiple platforms.

The project can be extended to support Android, Web, Windows, and other Flutter-compatible platforms, subject to platform-specific configuration and testing.

8. Future Enhancements

The following improvements can be considered for future versions:

- Income tracking and balance management.
- Dark mode and additional theme options.
- Advanced financial reports and analytics.
- Monthly and yearly spending comparisons.
- Cloud backup and data synchronisation.
- Improved data management and storage.
- Additional testing and performance improvements.

9. Team

Member| Role| Responsibility
Nagasaipraveen| Project Lead & Core Development| Core application development, integration, and project coordination.
Saakethnch| Analytics & Reports| Analytics and expense-reporting features.
Pavan| Data Management| Expense data management and related functionality.

Team responsibilities describe the assigned project areas. Contributions should be updated based on the work actually completed by each member.

10. Project Status

Kharcha is an ongoing personal expense-tracking project built using Flutter and Dart.

The initial version focuses on essential expense management, monthly budgeting, and spending insights. Further improvements and features will be introduced in future updates.

---

Developed with Flutter & Dart ❤️
