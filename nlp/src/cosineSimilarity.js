// src/cosineSimilarity.js

/**
 * Compute cosine similarity between two vectors
 * Returns value between -1 and 1
 */
function cosineSimilarity(vectorA, vectorB) {
  if (!vectorA || !vectorB) {
    throw new Error("Both vectors must be provided");
  }

  if (vectorA.length !== vectorB.length) {
    throw new Error("Vectors must have the same length");
  }

  if (vectorA.length === 0) {
    throw new Error("Vectors cannot be empty");
  }

  // Calculate dot product
  let dotProduct = 0;
  for (let i = 0; i < vectorA.length; i++) {
    dotProduct += vectorA[i] * vectorB[i];
  }

  // Calculate magnitudes (norms)
  let normA = 0;
  let normB = 0;
  for (let i = 0; i < vectorA.length; i++) {
    normA += vectorA[i] * vectorA[i];
    normB += vectorB[i] * vectorB[i];
  }
  normA = Math.sqrt(normA);
  normB = Math.sqrt(normB);

  // Handle zero vectors
  if (normA === 0 || normB === 0) {
    return 0;
  }

  // Calculate cosine similarity
  const cosine = dotProduct / (normA * normB);

  // Clamp to [-1, 1] to handle floating point errors
  return Math.max(-1, Math.min(1, cosine));
}

module.exports = {
  cosineSimilarity,
};
