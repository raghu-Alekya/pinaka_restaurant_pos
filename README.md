# pinaka_restaurant_pos

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

/////TokenExpired_Session
Key Fixes:
Reliable Logout & Session Clearing:
Modified AuthRepository.logout to always clear the local session (token, permissions, etc.), even if the server request fails or the token is already invalid. This ensures that users don't get stuck in a broken state.
Added an auto-logout trigger in 
TablesScreen
. If the app receives an Unauthorized (401) error from the server while loading tables, it will now automatically clear the session and return you to the login screen instead of just showing an error message.
Fixed Navigation & Inconsistent Tokens:
Updated the 
SplashScreen
 to check for both token and auth_token keys consistently.
Added logic to ensure that if any critical session data (like the restaurant ID or token) is missing, the app will correctly redirect to the Employee Login Page instead of trying to open the tables screen.
Prevented Data Loss on Startup:
Commented out a line in 
main.dart
 that was deleting the local database (tables.db) every time the app started. This was likely contributing to the "Failed to load Tables" error and data inconsistency.
Improved Error Messaging:
Updated 
TableRepository
 and 
EmployeeRepository
 to provide more descriptive error messages (e.g., "Unauthorized: Please login again") when API calls fail, making it easier to diagnose connection or session issues.
How to verify:
When you run the app now, if your previous session was invalid or expired, you should be automatically taken to the Employee Login screen.
If you are on the Tables screen and encounter a session error, the app will now allow you to log out and log back in with your PIN to refresh the connection.

