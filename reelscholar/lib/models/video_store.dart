// Simple in-memory store to share videos between screens
// Replace with real API/database later

class VideoStore {
  static final List<Map<String, dynamic>> _videos = [
    {
      'username': '@tatenda_m',
      'name': 'Tatenda Moyo',
      'school': 'School of Engineering Science and Technology',
      'subject': 'Software Engineering',
      'title': 'Introduction to Flutter — Building your first mobile app 📱',
      'likes': '2.4K',
      'comments': '183',
      'shares': '92',
      'color': 0xFF1A1040,
      'accent': 0xFF6C63FF,
      'filePath': null,
    },
    {
      'username': '@rudo_agri',
      'name': 'Rudo Chikwanda',
      'school': 'School of Agriculture Sciences and Technology',
      'subject': 'Crop Science',
      'title': 'Soil Fertility Management for Zimbabwean Farmers 🌱',
      'likes': '1.8K',
      'comments': '97',
      'shares': '44',
      'color': 0xFF0D2818,
      'accent': 0xFF2ECC71,
      'filePath': null,
    },
    {
      'username': '@simba_biz',
      'name': 'Simba Kowo',
      'school': 'School of Entrepreneurship and Business Sciences',
      'subject': 'Business Management',
      'title': 'How to write a Business Plan that actually works 💼',
      'likes': '3.1K',
      'comments': '256',
      'shares': '130',
      'color': 0xFF1A0A00,
      'accent': 0xFFFF6B35,
      'filePath': null,
    },
    {
      'username': '@panashe_health',
      'name': 'Panashe Dzingira',
      'school': 'School of Health Sciences and Technology',
      'subject': 'Public Health',
      'title': 'Understanding the Human Immune System 🧬',
      'likes': '987',
      'comments': '64',
      'shares': '28',
      'color': 0xFF1A0020,
      'accent': 0xFFE040FB,
      'filePath': null,
    },
    {
      'username': '@taku_wildlife',
      'name': 'Takudzwa Musere',
      'school': 'School of Wildlife and Environmental Science',
      'subject': 'Wildlife Management',
      'title': "Conservation strategies for Zimbabwe's wildlife reserves 🦁",
      'likes': '4.2K',
      'comments': '312',
      'shares': '201',
      'color': 0xFF001A2A,
      'accent': 0xFF00BCD4,
      'filePath': null,
    },
  ];

  static List<Map<String, dynamic>> get videos => List.from(_videos);

  static void addVideo(Map<String, dynamic> video) {
    _videos.insert(0, video);
  }
}