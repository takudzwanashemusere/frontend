// Base URL for the FastAPI messaging backend.
//
// Android emulator → use 10.0.2.2 (maps to your PC's localhost)
// Physical Android device on same Wi-Fi → replace with your PC's local IP, e.g.:
//   const String kBaseUrl = 'http://192.168.1.5:8001';
// iOS simulator → use localhost

// Physical Android device on same Wi-Fi as your PC
const String kBaseUrl = 'http://10.250.2.12:8001';
const String kWsUrl   = 'ws://10.250.2.12:8001/ws';
