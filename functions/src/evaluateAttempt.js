// src/evaluateAttempt.js
const { getGeminiRubricScore } = require("./geminiRubricScore");
const { getEmbedding } = require("./geminiEmbeddings");
const { cosineSimilarity } = require("./cosineSimilarity");
const { getCachedEmbedding, cacheEmbedding } = require("./firestoreCache");
const { FieldValue } = require("firebase-admin/firestore");

/**
 * Truncate text to prevent excessive API costs
 */
function truncateText(text, maxLength = 4000) {
  if (!text) return "";
  return text.length > maxLength ? text.substring(0, maxLength) : text;
}

/**
 * Main evaluation handler for a single attempt
 */
async function evaluateAttempt(db, interviewId, attemptId, attemptData) {
  const attemptRef = db.collection("interviews").doc(interviewId).collection("attempts").doc(attemptId);

  // Check if already evaluated
  if (attemptData.evaluatedAt) {
    console.log(`Attempt ${attemptId} already evaluated, skipping`);
    return;
  }

  // Validate required fields
  const { questionText, correctAnswer, userAnswer, status, questionId } = attemptData;

  if (!questionText || !correctAnswer) {
    console.log(`Missing questionText or correctAnswer for attempt ${attemptId}`);
    return;
  }

  // Handle skipped attempts
  if (status === "skipped" || !userAnswer || userAnswer.trim() === "") {
    await attemptRef.set(
      {
        relevanceFinal: 0,
        accuracyFinal: 0,
        evaluatedAt: FieldValue.serverTimestamp(),
        evaluatorVersion: "v1",
      },
      { merge: true }
    );
    console.log(`Attempt ${attemptId} was skipped or empty, set scores to 0`);
    return;
  }

  // Truncate texts for safety
  const truncatedQuestion = truncateText(questionText);
  const truncatedCorrect = truncateText(correctAnswer);
  const truncatedUser = truncateText(userAnswer);

  const evaluationResult = {
    evaluatedAt: FieldValue.serverTimestamp(),
    evaluatorVersion: "v1",
  };

  try {
    // Step 1: Get Gemini rubric scores
    console.log(`Getting Gemini rubric scores for attempt ${attemptId}`);
    const rubricResult = await getGeminiRubricScore(
      truncatedQuestion,
      truncatedCorrect,
      truncatedUser
    );

    evaluationResult.relevanceGemini = rubricResult.relevanceScore;
    evaluationResult.accuracyGemini = rubricResult.accuracyScore;
    evaluationResult.feedback = rubricResult.feedback;
    evaluationResult.missingPoints = rubricResult.missingPoints || [];
    evaluationResult.wrongClaims = rubricResult.wrongClaims || [];

    // Step 2: Get embeddings and compute similarity
    console.log(`Computing embeddings similarity for attempt ${attemptId}`);

    // Try to get cached correct answer embedding
    let correctEmbedding = null;
    if (questionId) {
      correctEmbedding = await getCachedEmbedding(db, questionId);
    }

    // If not cached, compute and cache it
    if (!correctEmbedding) {
      console.log(`Computing new embedding for correct answer`);
      correctEmbedding = await getEmbedding(truncatedCorrect);
      if (questionId && correctEmbedding) {
        await cacheEmbedding(db, questionId, correctAnswer, correctEmbedding);
      }
    }

    // Get user answer embedding
    const userEmbedding = await getEmbedding(truncatedUser);

    // Compute cosine similarity
    if (correctEmbedding && userEmbedding) {
      const cosine = cosineSimilarity(correctEmbedding, userEmbedding);
      // Convert from [-1, 1] to [0, 1]
      const similarity01 = Math.max(0, Math.min(1, (cosine + 1) / 2));
      const embeddingScore = Math.round(similarity01 * 100);

      evaluationResult.embeddingSimilarity = parseFloat(similarity01.toFixed(4));
      evaluationResult.embeddingScore = embeddingScore;

      // Step 3: Combine scores
      // relevanceFinal = 60% Gemini + 40% Embedding
      // accuracyFinal = 80% Gemini + 20% Embedding
      const relevanceFinal = Math.round(
        0.6 * rubricResult.relevanceScore + 0.4 * embeddingScore
      );
      const accuracyFinal = Math.round(
        0.8 * rubricResult.accuracyScore + 0.2 * embeddingScore
      );

      evaluationResult.relevanceFinal = relevanceFinal;
      evaluationResult.accuracyFinal = accuracyFinal;
    } else {
      // Fallback: use only Gemini scores if embeddings fail
      console.warn(`Embeddings failed, using only Gemini scores`);
      evaluationResult.relevanceFinal = rubricResult.relevanceScore;
      evaluationResult.accuracyFinal = rubricResult.accuracyScore;
      evaluationResult.embeddingSimilarity = 0;
      evaluationResult.embeddingScore = 0;
    }

    console.log(`Evaluation complete for attempt ${attemptId}:`, evaluationResult);
  } catch (error) {
    console.error(`Error during evaluation of attempt ${attemptId}:`, error);
    evaluationResult.evaluationError = error.message || "Unknown error";
    // Still mark as evaluated even if there's an error
  }

  // Write evaluation results back to Firestore
  await attemptRef.set(evaluationResult, { merge: true });
}

module.exports = evaluateAttempt;
