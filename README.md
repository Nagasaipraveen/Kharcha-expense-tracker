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

# 💸 Kharcha — Expense Tracker

> **Spend smart. Live happy.**
> A bright, easy-to-use expense tracker built with **Flutter** and **Dart**. Record expenses and income, set a monthly budget, and see where your money goes — all stored privately on your own device.



![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)




![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart&logoColor=white)




![Material 3](https://img.shields.io/badge/Material-3-6C5CE7)




![Platform](https://img.shields.io/badge/Platform-Web%20%7C%20Android%20%7C%20Windows-FF6B9D)



---

## 1. Overview and features

Kharcha is a Flutter group project built during the **Flutter Application Development Programme (KHIT, Guntur)**. The team chose the **Expense Tracker** topic. The app works fully offline: every record is typed in by the user and saved locally.

| Feature | Description |
|---|---|
| Add / edit / delete | Add an entry with name, amount, category, date, payment method and note. Swipe left to delete, with an **Undo** option. |
| Income and expenses | A toggle in the form records money coming in or going out. The home card shows the **total balance**. |
| Pictures for each entry | Pick an emoji sticker for every entry, or paste an optional photo link with a live preview. |
| Categories | Food, Travel, Shopping, Bills, Health, Education, Entertainment, Other, and Income — each with its own colour and icon. |
| Payment methods | Cash, UPI, Card and Net banking. |
| Monthly budget | Set your own budget. A progress bar shows how much of this month's budget is used, and warns you when you go over. |
| Search | Find entries by name, note, category or payment method. |
| Filters and sorting | Filter by period (All time, Today, This week, This month) and by category. Sort by Newest, Highest, Lowest or Important. |
| Important star | Mark any entry as important with a star. |
| Detail screen | Tap an entry to see a large picture, all its details, and Edit / Delete buttons. |
| Insights | Donut chart by category, last-7-days bar chart, biggest expenses, and average spend. |
| Charts | Custom `CustomPainter` donut chart and Container-based bar chart (no third-party chart library). |
| Copy report | One tap copies a text summary (income, expenses, balance, category split) to the clipboard. |
| Persistence | All data and the budget are saved on the device and survive app restarts. |

---

## 2. Technology stack

| Layer | Choice |
|---|---|
| Framework | Flutter (recent stable release), Dart 3 with null safety |
| UI toolkit | Material 3 (`ColorScheme.fromSeed`) with a custom bright colour palette |
| State management | Built-in `StatefulWidget` + `setState` |
| Local storage | `shared_preferences` (expenses saved as JSON, budget saved as a number) |
| Data format | `dart:convert` (`jsonEncode` / `jsonDecode`) |
| Charts | `CustomPainter` donut chart and Container-based bar chart |
| Clipboard | `flutter/services.dart` (`Clipboard.setData`) for the copy-report feature |
| Images | `Image.network` for optional photo links, with an emoji fallback if a link fails |
| Currency and dates | Indian rupee (₹) formatting and `DD/MM/YYYY` dates, written with plain Dart helpers |
| Editor | Visual Studio Code with the Flutter and Dart extensions |

---

## 3. Architecture

The whole app lives in a single file, `lib/main.dart`, organised into clearly separated sections.

```
Kharcha-expense-tracker/
├── lib/
│   └── main.dart          # Complete app (models, screens, widgets)
├── web/                   # Flutter web support files
├── android/               # Android platform files
├── pubspec.yaml           # Dependencies (shared_preferences)
└── README.md
```

### Inside `main.dart`

| Section | Type | Responsibility |
|---|---|---|
| `main()` | Function | App entry point; starts `ExpenseTrackerApp`. |
| `AppColors` | Class | Bright theme colours used across the app. |
| `Cat` and `categories` | Class and list | Category name, icon, colour and default emoji. |
| `Expense` | Model class | One income or expense record, with `toJson()` / `fromJson()`. |
| `ExpenseTrackerApp` | `StatelessWidget` | `MaterialApp` and Material 3 theme. |
| `HomePage` | `StatefulWidget` | Home and Insights tabs, search, filters, sorting, totals, budget and saving. |
| `ExpenseForm` | `StatefulWidget` | Add / Edit bottom sheet with validation. |
| `ExpenseDetailPage` | `StatelessWidget` | Detail screen with Edit and Delete actions. |
| `ExpensePicture` | `StatelessWidget` | Shows the photo or emoji picture for an entry. |
| `DonutPainter` | `CustomPainter` | Draws the category donut chart. |

### Data model: `Expense`

| Field | Type | Description |
|---|---|---|
| `id` | `String` | Unique id for the entry. |
| `title` | `String` | Name of the expense or income. |
| `amount` | `double` | Amount in rupees. |
| `category` | `String` | Category name (`Income` for income entries). |
| `date` | `DateTime` | Date of the entry. |
| `note` | `String` | Optional note. |
| `important` | `bool` | Starred or not. |
| `isIncome` | `bool` | `true` for income, `false` for expense. |
| `emoji` | `String` | Sticker picture shown for the entry. |
| `photoUrl` | `String` | Optional photo link. |
| `method` | `String` | Cash, UPI, Card or Net banking. |

---

## 4. Screens

| Screen | What it shows | Screenshot |
|---|---|---|
| Home | Gradient balance card, income and expense totals, monthly budget bar, search, period and category chips, transaction list | `

![Home](screenshots/home.png)

` |
| Add / Edit entry | Expense / Income toggle, name, amount, category, sticker picker, payment method, date, photo link, note | `

![Add](screenshots/add.png)

` |
| Expense details | Large picture, amount, category, payment method, date, note, Edit and Delete | `

![Details](screenshots/details.png)

` |
| Insights | Totals, donut chart, last-7-days bar chart, biggest expenses, Copy report | `

![Insights](screenshots/insights.png)

` |

---

## 5. Data source

Kharcha uses **no external data source**. Every entry is typed in by the user through the in-app form and stored **locally**:

- **Android / Windows:** saved on the device through `shared_preferences`.
- **Web:** saved in the browser's local storage through `shared_preferences`, so entries stay after a page reload or browser restart.

There are no network calls (except loading an optional photo link), no accounts, no analytics and no third-party services. Category names, icons, emoji stickers and payment methods are static constants defined in `lib/main.dart`.

| Storage key | Content |
|---|---|
| `expenses_v3` | List of all entries, saved as JSON |
| `budget_v2` | Monthly budget amount |

---

## 6. Getting started

### Prerequisites

| Tool | Version | Notes |
|---|---|---|
| Flutter SDK | Recent stable release | Run `flutter doctor` and fix any issue it shows |
| Dart | Included with Flutter | — |
| VS Code | Latest | Install the **Flutter** and **Dart** extensions |
| Google Chrome | Latest | Used to run the web version |
| Windows Developer Mode | On | Required by Flutter plugins. Run `start ms-settings:developers` and turn it on |

### Run it

```bash
# 1. Clone the repository
git clone https://github.com/Nagasaipraveen/Kharcha-expense-tracker.git
cd Kharcha-expense-tracker

# 2. Install packages
flutter pub get

# 3. Run in Chrome
flutter run -d chrome
```

To run on a different device, use `flutter devices` to list them, then `flutter run -d <device-id>`.

> If Flutter says *"Building with plugins requires symlink support"*, turn on **Developer Mode** in Windows settings, restart VS Code, and run `flutter pub get` again.

---

## 7. Website (web) version

Kharcha is also available as a **fully working website** — the same codebase compiled with `flutter build web`. On the web, data is kept in the browser's local storage, so **records survive page reloads and browser restarts**.

**Run locally**

```bash
flutter run -d chrome
```

**Build for release**

```bash
flutter build web --release
```

The finished website is created in the `build/web` folder.

**Deploy anywhere static files are served** — GitHub Pages, Netlify, Firebase Hosting, Vercel or any web server — by uploading the `build/web` folder.

| Platform | Storage backend | Persistence |
|---|---|---|
| Android | `shared_preferences` (app storage) | Saved until the app data is cleared |
| Windows | `shared_preferences` (local file) | Saved until the file is deleted |
| Web | `shared_preferences` (browser local storage) | Saved until the browser data is cleared |

---

## 8. Testing

Manual test cases used to check the app:

| # | Test case | Steps | Expected result |
|---|---|---|---|
| 1 | Add an expense | Tap **Add new**, fill in all fields, tap **Save** | Entry appears in the list; total and budget bar update |
| 2 | Add income | Choose **Income** in the form and save | Balance increases; amount shows in green with `+` |
| 3 | Validation | Leave the name empty or enter an amount of `0` | Error message appears and the entry is not saved |
| 4 | Edit an entry | Tap an entry, tap **Edit**, change values, tap **Update** | List shows the updated values |
| 5 | Delete and undo | Swipe an entry left, then tap **UNDO** | Entry is removed, then restored |
| 6 | Important star | Tap the star on an entry | Star turns orange; entry comes first under **Important** sort |
| 7 | Search | Type part of a name or note in the search box | Only matching entries are shown |
| 8 | Filters | Select a category chip and a period chip | List shows only matching entries |
| 9 | Budget warning | Set a small budget and add a larger expense | Bar is full and shows an over-budget message |
| 10 | Persistence | Add entries, then refresh the page or restart the app | All entries and the budget are still there |
| 11 | Photo link | Paste a valid image link in the form | Preview appears; the list shows the photo |
| 12 | Broken photo link | Paste an invalid image link | App falls back to the emoji picture |
| 13 | Insights | Open the **Insights** tab | Donut chart, 7-day chart and biggest expenses are shown |
| 14 | Copy report | Tap **Copy report** | Summary is copied to the clipboard |

---

## 9. Limitations and future scope

**Current limitations**

- Data stays on one device or browser and **does not sync between devices** — an offline-first privacy model.
- Clearing browser data or app data removes the saved entries.
- Photos are added by link, not picked from the gallery.
- The whole app is in a single file.

**Planned improvements**

| Idea | Benefit |
|---|---|
| Pick photos from the gallery (`image_picker`) | Add real pictures to each entry |
| SQLite database | Faster handling of very large histories |
| Split code into `models/`, `screens/`, `widgets/` | Cleaner, easier-to-maintain project |
| `provider` state management | Better separation of UI and logic |
| CSV export | Share or back up records |
| Dark mode | Comfortable use at night |
| Recurring expenses and reminders | Never miss rent or bills |
| Cloud backup | Sync between devices |

---

## 10. Team

| Member | Role | Parts built |
|---|---|---|
| N.V.N. Sai Praveen | Project Lead & Core Developer | App setup, project architecture, core application development and UI integration. |
| Pavan | Data Management Developer | Expense data organisation, expense record management, data storage and CSV export functionality. |
| Saakethnch | Analytics & Reports Developer | Expense summaries, category-wise spending analysis and analytics/reporting features. |

**Institution:** KHIT, Guntur — Flutter Application Development Programme
---

## 📄 License

This project was created for educational purposes as part of a college programme.
