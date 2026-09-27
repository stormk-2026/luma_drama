class EngagementSnapshot {
  const EngagementSnapshot({
    this.savedDramaIds = const {},
    this.likedDramaIds = const {},
    this.commentsByDrama = const {},
  });

  final Set<String> savedDramaIds;
  final Set<String> likedDramaIds;
  final Map<String, List<String>> commentsByDrama;
}
