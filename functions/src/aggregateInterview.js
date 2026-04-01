// src/aggregateInterview.js
const { FieldValue } = require("firebase-admin/firestore");

/**
 * Recomputes and updates interview-level aggregate scores
 */
async function recomputeInterviewResult(db, interviewId) {
  const interviewRef = db.collection("interviews").doc(interviewId);
  const attemptsRef = interviewRef.collection("attempts");

  // Get all attempts
  const attemptsSnapshot = await attemptsRef.get();

  if (attemptsSnapshot.empty) {
    console.log(`No attempts found for interview ${interviewId}`);
    return {
      answeredCount: 0,
      skippedCount: 0,
      wrongCount: 0,
      totalCount: 0,
      accuracyOverall: 0,
      relevanceOverall: 0,
    };
  }

  let answeredCount = 0;
  let skippedCount = 0;
  let wrongCount = 0;
  let totalAccuracy = 0;
  let totalRelevance = 0;

  // Process all attempts
  attemptsSnapshot.forEach((doc) => {
    const attempt = doc.data();

    // Count skipped
    if (attempt.status === "skipped") {
      skippedCount++;
      return;
    }

    // Count answered (only if userAnswer exists and not empty)
    if (
      attempt.status === "answered" &&
      attempt.userAnswer &&
      attempt.userAnswer.trim() !== ""
    ) {
      answeredCount++;

      // Only include evaluated attempts in averages
      if (attempt.evaluatedAt && typeof attempt.accuracyFinal === "number") {
        totalAccuracy += attempt.accuracyFinal;
        totalRelevance += attempt.relevanceFinal || 0;

        // Count as wrong if accuracy is below 50
        if (attempt.accuracyFinal < 50) {
          wrongCount++;
        }
      }
    }
  });

  const totalCount = answeredCount + skippedCount;

  // Compute overall scores (average of answered attempts only)
  let accuracyOverall = 0;
  let relevanceOverall = 0;

  if (answeredCount > 0) {
    accuracyOverall = Math.round(totalAccuracy / answeredCount);
    relevanceOverall = Math.round(totalRelevance / answeredCount);
  }

  const aggregateData = {
    answeredCount,
    skippedCount,
    wrongCount,
    totalCount,
    accuracyOverall,
    relevanceOverall,
    resultUpdatedAt: FieldValue.serverTimestamp(),
    resultVersion: "v1",
  };

  // Write aggregate scores to interview document
  await interviewRef.set(aggregateData, { merge: true });

  console.log(`Updated interview ${interviewId} with aggregates:`, aggregateData);

  return aggregateData;
}

module.exports = {
  recomputeInterviewResult,
};
