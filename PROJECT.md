# Project: Macrode Persona Feedback Report

## Architecture
- Swift-based iOS app using SwiftData for persistence.
- Renders progress visualizations (Calorie HUD, MacroBar, weekly/monthly calendar).
- Implements:
  - `MetabolismEngine`: Calculates True TDEE from 21-day energy & weight changes.
  - `BalanceEngine`: Smoothes target calories using 7-day rolling window offsets.
  - `SmartSuggester`: Finds combination of foods to meet remaining macros.
- Standard tab navigation (Dashboard, Insights, Add Meal, Settings).
- App Group `"group.com.kuepferlaurin.macrode"` shares SwiftData and UserDefaults with Widget extensions.

## Milestones
| # | Name | Scope | Dependencies | Status |
|---|---|---|---|---|
| 1 | Codebase Analysis | Map out Macrode source files, structures, routing, views, state management | None | DONE |
| 2 | Persona Simulation & UX Audit | Run simulated walkthroughs for 5 personas, identify friction points and bugs | M1 | DONE |
| 3 | Report Generation & Review | Compile findings into `persona_feedback_report.md` in root and review | M2 | DONE |

## Interface Contracts
- Output file format: `persona_feedback_report.md` in project root directory.

## Code Layout
- `Macrode/App/MacrodeApp.swift` - App entry point
- `Macrode/App/Components.swift` - UI helper views (CalorieHUD, MacroBar, MealRow)
- `Macrode/Models/Models.swift` - SwiftData models (`FoodItem`, `DailyLog`, `ConsumedMeal`, etc.)
- `Macrode/ViewModels/` - View models for dashboard, onboarding/calculator, and search
- `Macrode/Views/` - UI views for dashboard tabs, food entry, recipe logging, settings, and suggestions
- `Macrode/Engines/` - Computational modules (`MetabolismEngine`, `BalanceEngine`, `ReviewEngine`, `SmartSuggesterView`)
