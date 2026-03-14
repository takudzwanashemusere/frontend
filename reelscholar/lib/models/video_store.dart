// Simple in-memory store to share videos between screens
// Replace this with your real API/database later

class VideoStore {
  static final List<Map<String, dynamic>> _videos = [
    {
      'username': '@tatenda_math',
      'name': 'Tatenda Moyo',
      'subject': 'Mathematics',
      'title': 'Solving Quadratic Equations in 60 seconds 🔥',
      'likes': '2.4K',
      'comments': '183',
      'shares': '92',
      'color': 0xFF1A1040,
      'accent': 0xFF6C63FF,
      'filePath': null,
    },
    {
      'username': '@rudo_biology',
      'name': 'Rudo Chikwanda',
      'subject': 'Biology',
      'title': 'How DNA Replication works — simple explanation 🧬',
      'likes': '1.8K',
      'comments': '97',
      'shares': '44',
      'color': 0xFF0D2818,
      'accent': 0xFF2ECC71,
      'filePath': null,
    },
    {
      'username': '@simba_ict',
      'name': 'Simba Kowo',
      'subject': 'ICT',
      'title': 'Flutter vs React Native — which one for CUT students? 📱',
      'likes': '3.1K',
      'comments': '256',
      'shares': '130',
      'color': 0xFF1A0A00,
      'accent': 0xFFFF6B35,
      'filePath': null,
    },
  ];

  static List<Map<String, dynamic>> get videos => List.from(_videos);

  static void addVideo(Map<String, dynamic> video) {
    _videos.insert(0, video); // Add to top of feed
  }
}