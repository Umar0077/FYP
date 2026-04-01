import 'dart:math' as math;

class EmbeddingsService {
  /// Generate a simple text-based similarity score
  /// This uses string comparison algorithms instead of embeddings
  Future<List<double>> generateEmbedding(String text) async {
    if (text.trim().isEmpty) {
      throw Exception('Cannot generate embedding for empty text');
    }

    // Simple character-based vector representation
    final words = text.toLowerCase().split(RegExp(r'\W+'));
    final Map<String, int> wordFreq = {};
    
    for (final word in words) {
      if (word.isNotEmpty) {
        wordFreq[word] = (wordFreq[word] ?? 0) + 1;
      }
    }
    
    // Create a simple embedding vector (TF representation)
    return wordFreq.values.map((v) => v.toDouble()).toList();
  }

  /// Calculate cosine similarity between two embedding vectors
  double cosineSimilarity(List<double> vecA, List<double> vecB) {
    if (vecA.isEmpty || vecB.isEmpty) {
      return 0.0;
    }

    // Pad vectors to same length with zeros
    final maxLen = math.max(vecA.length, vecB.length);
    final paddedA = List<double>.from(vecA);
    final paddedB = List<double>.from(vecB);
    
    while (paddedA.length < maxLen) paddedA.add(0.0);
    while (paddedB.length < maxLen) paddedB.add(0.0);

    double dotProduct = 0.0;
    double normA = 0.0;
    double normB = 0.0;

    for (int i = 0; i < maxLen; i++) {
      dotProduct += paddedA[i] * paddedB[i];
      normA += paddedA[i] * paddedA[i];
      normB += paddedB[i] * paddedB[i];
    }

    normA = normA.isFinite ? normA : 0.0;
    normB = normB.isFinite ? normB : 0.0;

    if (normA == 0.0 || normB == 0.0) {
      return 0.0;
    }

    final similarity = dotProduct / (math.sqrt(normA) * math.sqrt(normB));

    // Clamp to [-1, 1] to handle floating point errors
    return similarity.clamp(-1.0, 1.0);
  }

  /// Calculate similarity score (0-100) between two texts using simple embeddings
  Future<double> calculateTextSimilarity(
      String text1, String text2) async {
    try {
      final embedding1 = await generateEmbedding(text1);
      final embedding2 = await generateEmbedding(text2);

      final similarity = cosineSimilarity(embedding1, embedding2);

      // Convert from [-1, 1] to [0, 100]
      final score = ((similarity + 1.0) / 2.0) * 100.0;

      return score.clamp(0.0, 100.0);
    } catch (e) {
      print('❌ Error calculating text similarity: $e');
      // Return neutral score on error
      return 50.0;
    }
  }
}
