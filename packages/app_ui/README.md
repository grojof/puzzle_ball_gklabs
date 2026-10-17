# app_ui

Ball Odyssey's visual identity: `AppColors`, `AppTheme.dark` and the bundled Poppins font (400, 500, 600 and 700),
so the app never downloads fonts at runtime.

```dart
MaterialApp(theme: AppTheme.dark);
```

Call `registerAppUiLicenses()` once at startup to list the Poppins license (SIL Open Font License 1.1) in the
app's license page.
