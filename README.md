# SIEIS Flutter Frontend

Smart Indoor Environmental Intelligence System mobile UI for real-time IEQ monitoring, AI forecasting, alerts, trends, and actionable recommendations.

## Screens

- Dashboard: real-time room health, CO2, VOC, temperature, humidity, forecast warning, and quick actions.
- Trends: visual history for all monitored parameters.
- Forecast: upcoming predicted conditions and risk levels.
- Alerts: active/past environmental alerts and notification settings.
- Actions: occupant recommendations and response checklist.

## Run

If this folder does not yet contain Android/iOS platform files, run this once from the project folder:

```powershell
flutter create --platforms=android,ios .
```

Then run:

```powershell
flutter pub get
flutter run
```

The current frontend uses simulated live readings so the UI can be tested before the IoT/backend APIs are connected.
