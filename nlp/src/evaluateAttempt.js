const { getGeminiRubricScore } = require("./geminiRubricScore");
const { getEmbedding } = require("./geminiEmbeddings");
const { cosineSimilarity } = require("./cosineSimilarity");
const { getCachedEmbedding, cacheEmbedding } = require("./firestoreCache");
const { FieldValue } = require("firebase-admin/firestore");

function truncateText(text, maxLength = 4000) {
  if (!text) return "";
  const value = String(text).trim();
  return value.length > maxLength ? value.substring(0, maxLength) : value;
}

function normalizeScore(value) {
  const num = Number(value);
  if (!Number.isFinite(num)) return 0;
  return Math.max(0, Math.min(100, Math.round(num)));
}

function buildBaseResult() {
  return {
    evaluatorVersion: "v2",
    relevanceGemini: 0,
    accuracyGemini: 0,
    embeddingSimilarity: 0,
    embeddingScore: 0,
    relevanceFinal: 0,
    accuracyFinal: 0,
    feedback: "",
    missingPoints: [],
    wrongClaims: [],
    evaluationError: null,
  };
}

function normalizeAttemptData(raw = {}) {
  return {
    questionText: truncateText(raw.questionText || raw.question || ""),
    correctAnswer: truncateText(raw.correctAnswer || raw.expectedAnswer || ""),
    userAnswer: truncateText(raw.userAnswer || raw.answer || ""),
    status: raw.status || "answered",
    questionId: raw.questionId || null,
  };
}

function validateAttemptData(attemptData) {
  if (!attemptData.questionText) {
    const error = new Error("Missing required field: questionText");
    error.statusCode = 400;
    throw error;
  }

  if (!attemptData.correctAnswer) {
    const error = new Error("Missing required field: correctAnswer");
    error.statusCode = 400;
    throw error;
  }
}

function isSkippedOrEmpty(attemptData) {
  return (
    attemptData.status === "skipped" ||
    !attemptData.userAnswer ||
    !attemptData.userAnswer.trim()
  );
}

async function computeEvaluation(rawAttemptData, options = {}) {
  const { db = null } = options;

  const attemptData = normalizeAttemptData(rawAttemptData);
  validateAttemptData(attemptData);

  const result = buildBaseResult();

  if (isSkippedOrEmpty(attemptData)) {
    result.feedback = "Question was skipped or no answer was provided.";
    result.status = "evaluated";
    return result;
  }

  const { questionText, correctAnswer, userAnswer, questionId } = attemptData;

  try {
    const rubricResult = await getGeminiRubricScore(
      questionText,
      correctAnswer,
      userAnswer
    );

    result.relevanceGemini = normalizeScore(rubricResult?.relevanceScore);
    result.accuracyGemini = normalizeScore(rubricResult?.accuracyScore);
    result.feedback = rubricResult?.feedback || "";
    result.missingPoints = Array.isArray(rubricResult?.missingPoints)
      ? rubricResult.missingPoints
      : [];
    result.wrongClaims = Array.isArray(rubricResult?.wrongClaims)
      ? rubricResult.wrongClaims
      : [];

    let correctEmbedding = null;

    if (db && questionId) {
      try {
        correctEmbedding = await getCachedEmbedding(db, questionId);
      } catch (cacheReadError) {
        console.warn("Could not read cached embedding:", cacheReadError.message);
      }
    }

    if (!correctEmbedding) {
      correctEmbedding = await getEmbedding(correctAnswer);

      if (db && questionId && correctEmbedding) {
        try {
          await cacheEmbedding(db, questionId, correctAnswer, correctEmbedding);
        } catch (cacheWriteError) {
          console.warn("Could not cache embedding:", cacheWriteError.message);
        }
      }
    }

    const userEmbedding = await getEmbedding(userAnswer);

    if (correctEmbedding && userEmbedding) {
      const cosine = cosineSimilarity(correctEmbedding, userEmbedding);
      const similarity01 = Math.max(0, Math.min(1, (cosine + 1) / 2));
      const embeddingScore = normalizeScore(similarity01 * 100);

      result.embeddingSimilarity = Number(similarity01.toFixed(4));
      result.embeddingScore = embeddingScore;

      result.relevanceFinal = normalizeScore(
        0.6 * result.relevanceGemini + 0.4 * embeddingScore
      );

      result.accuracyFinal = normalizeScore(
        0.8 * result.accuracyGemini + 0.2 * embeddingScore
      );
    } else {
      result.embeddingSimilarity = 0;
      result.embeddingScore = 0;
      result.relevanceFinal = result.relevanceGemini;
      result.accuracyFinal = result.accuracyGemini;
    }

    result.status = "evaluated";
    return result;
  } catch (error) {
    console.error("computeEvaluation error:", error);

    result.evaluationError = error.message || "Unknown error";
    result.status = "evaluated_with_error";

    return result;
  }
}

async function evaluateAttempt(
  db,
  interviewId,
  attemptId,
  rawAttemptData,
  options = {}
) {
  const { forceReevaluate = false } = options;

  if (!db) {
    throw new Error("Firestore db instance is required");
  }

  if (!interviewId) {
    throw new Error("interviewId is required");
  }

  if (!attemptId) {
    throw new Error("attemptId is required");
  }

  const attemptRef = db
    .collection("interviews")
    .doc(interviewId)
    .collection("attempts")
    .doc(attemptId);

  const attemptData = normalizeAttemptData(rawAttemptData);

  if (!forceReevaluate && rawAttemptData?.evaluatedAt) {
    console.log(`Attempt ${attemptId} already evaluated, skipping`);
    return {
      skippedBecauseAlreadyEvaluated: true,
      ...rawAttemptData,
    };
  }

  const computed = await computeEvaluation(attemptData, { db });

  const writePayload = {
    ...computed,
    evaluatedAt: FieldValue.serverTimestamp(),
  };

  await attemptRef.set(writePayload, { merge: true });

  return writePayload;
}

module.exports = evaluateAttempt;
module.exports.computeEvaluation = computeEvaluation;
module.exports.normalizeAttemptData = normalizeAttemptData;
module.exports.truncateText = truncateText;