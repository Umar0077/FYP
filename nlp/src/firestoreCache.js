// src/firestoreCache.js
const { FieldValue } = require("firebase-admin/firestore");

/**
 * Get cached embedding for a question's correct answer
 * Returns null if not cached
 */
async function getCachedEmbedding(db, questionId) {
  if (!questionId) {
    return null;
  }

  try {
    const questionDoc = await db.collection("questions").doc(questionId).get();

    if (!questionDoc.exists) {
      return null;
    }

    const data = questionDoc.data();
    if (data.correctAnswerEmbedding && Array.isArray(data.correctAnswerEmbedding)) {
      console.log(`Found cached embedding for question ${questionId}`);
      return data.correctAnswerEmbedding;
    }

    return null;
  } catch (error) {
    console.error(`Error getting cached embedding for question ${questionId}:`, error);
    return null;
  }
}

/**
 * Cache embedding for a question's correct answer
 */
async function cacheEmbedding(db, questionId, correctAnswer, embedding) {
  if (!questionId || !embedding) {
    return;
  }

  try {
    await db
      .collection("questions")
      .doc(questionId)
      .set(
        {
          correctAnswer,
          correctAnswerEmbedding: embedding,
          embeddingUpdatedAt: FieldValue.serverTimestamp(),
        },
        { merge: true }
      );

    console.log(`Cached embedding for question ${questionId}`);
  } catch (error) {
    console.error(`Error caching embedding for question ${questionId}:`, error);
    // Don't throw - caching failure shouldn't break evaluation
  }
}

module.exports = {
  getCachedEmbedding,
  cacheEmbedding,
};
