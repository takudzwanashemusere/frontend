// Base URL for the FastAPI messaging backend.
//
// Android emulator → use 10.0.2.2 (maps to your PC's localhost)
// Physical Android device on same Wi-Fi → replace with your PC's local IP, e.g.:
//   const String kBaseUrl = 'http://192.168.1.5:8001';
// iOS simulator → use localhost

// Render-hosted messaging API
const String kBaseUrl    = 'https://messaging-api-pj0t.onrender.com';
const String kWsUrl      = 'wss://messaging-api-pj0t.onrender.com/ws';
const String kLaravelUrl = 'https://reelscholarapi-main-l5f9h5.laravel.cloud';
