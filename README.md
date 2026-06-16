# Macrode

Macrode is an offline macronutrient and calorie tracker for iOS.

It stores all data locally on the device using SwiftData. It does not require user accounts and does not use external database servers.

---

### Application Previews

---

## Core Features

### Dietary & Health Tracking

* **Logging:** Track calories, protein, carbohydrates, and fats.
* **Local Database:** Includes a database of common whole foods and generic restaurant items.
* **Recipes:** Combine ingredients into reusable meal entries.
* **Barcode Scanning:** Uses the device camera (VisionKit) to retrieve nutritional data.
* **Daily Metrics:** Track daily water intake, body weight, and dietary supplements.

### Algorithms

* **TDEE Calculation:** Analyzes 14-day historical weight trends against caloric intake to estimate Total Daily Energy Expenditure.
* **Mifflin-St. Jeor Onboarding:** Calculates baseline macro targets based on height, weight, age, biological sex, and physical activity level.

### System Integration

* **Apple HealthKit:** Optional synchronization to write consumed dietary metrics to the Apple Health app.
* **WidgetKit:** Homescreen widgets for daily macronutrient progress.
* **Local Notifications:** Scheduled push notifications for hydration and supplement reminders.

### Data Management

* **CSV Export/Import:** Export meal history to a `.csv` file and restore it.

## Technical Stack

* **Language:** Swift 5.9
* **Minimum OS:** iOS 17.0+
* **User Interface:** SwiftUI, Swift Charts
* **Persistence:** SwiftData (SQLite)
* **Extensions:** WidgetKit
* **Hardware APIs:** VisionKit, UIImpactFeedbackGenerator
* **Networking:** URLSession (for Open Food Facts API queries)

## Build Instructions

### Prerequisites

* macOS Sonoma or later
* Xcode 15.0 or later
* Physical iPhone (recommended for barcode scanning)

### Setup

1. Clone the repository:
   ```bash
   git clone https://github.com/LaurinKuepfer/Macrode.git
   ```
2. Open `Macrode.xcodeproj` in Xcode.
3. In **Signing & Capabilities**, assign your Apple Developer account to the main `Macrode` and `MacrodeWidgetExtension` targets.
4. Update the App Group identifier to match across both targets (e.g., `group.com.yourname.macrode`).
5. Build and run (`Cmd + R`).

## Support

If you would like to support the development:
[Support Macrode on Ko-fi](https://ko-fi.com/laurinkuepfer)

## Attribution

Barcode lookup uses the [Open Food Facts](https://world.openfoodfacts.org/) database.

## License

Please review the included `LICENSE` file.
