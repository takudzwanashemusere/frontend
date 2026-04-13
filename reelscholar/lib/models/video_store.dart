// In-memory store used when adding freshly-uploaded videos
// before the feed is refreshed from the API.

class VideoStore {
  static final List<Map<String, dynamic>> _videos = [];

  static List<Map<String, dynamic>> get videos => List.from(_videos);

  static void addVideo(Map<String, dynamic> video) {
    _videos.insert(0, video);
  }

  static void clear() {
    _videos.clear();
  }
}