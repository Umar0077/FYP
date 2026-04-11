const { FieldValue } = require("firebase-admin/firestore");

async function recomputeInterviewResult(db, interviewId) {
  const interviewRef = db.collection("interviews").doc(interviewId);
  const attemptsRef = interviewRef.collection("attempts");

  const attemptsSnapshot = await attemptsRef.get();

  if (attemptsSnapshot.empty) {
    const emptyResult = {
      answeredCount: 0,
      skippedCount: 0,
      wrongCount: 0,
      totalCount: 0,
      evaluatedAnsweredCount: 0,
      accuracyOverall: 0,
      relevanceOverall: 0,
      resultUpdatedAt: FieldValue.serverTimestamp(),
      resultVersion: "v2",
    };

    await interviewRef.set(emptyResult, { merge: true });
    return emptyResult;
  }

  let answeredCount = 0;
  let skippedCount = 0;
  let wrongCount = 0;
  let evaluatedAnsweredCount = 0;
  let totalAccuracy = 0;
  let totalRelevance = 0;

  attemptsSnapshot.forEach((doc) => {
    const attempt = doc.data();

    if (attempt.status === "skipped") {
      skippedCount++;
      return;
    }

    if (
      attempt.status === "answered" &&
      attempt.userAnswer &&
      attempt.userAnswer.trim() !== ""
    ) {
      answeredCount++;

      const hasAccuracy = typeof attempt.accuracyFinal === "number";
      const hasRelevance = typeof attempt.relevanceFinal === "number";

      if (attempt.evaluatedAt && hasAccuracy && hasRelevance) {
        evaluatedAnsweredCount++;
        totalAccuracy += attempt.accuracyFinal;
        totalRelevance += attempt.relevanceFinal;

        if (attempt.accuracyFinal < 50) {
          wrongCount++;
        }
      }
    }
  });

  const totalCount = answeredCount + skippedCount;

  let accuracyOverall = 0;
  let relevanceOverall = 0;

  if (evaluatedAnsweredCount > 0) {
    accuracyOverall = Math.round(totalAccuracy / evaluatedAnsweredCount);
    relevanceOverall = Math.round(totalRelevance / evaluatedAnsweredCount);
  }

  const aggregateData = {
    answeredCount,
    skippedCount,
    wrongCount,
    totalCount,
    evaluatedAnsweredCount,
    accuracyOverall,
    relevanceOverall,
    resultUpdatedAt: FieldValue.serverTimestamp(),
    resultVersion: "v2",
  };

  await interviewRef.set(aggregateData, { merge: true });

  console.log(`Updated interview ${interviewId} with aggregates:`, aggregateData);

  return aggregateData;
}

module.exports = {
  recomputeInterviewResult,
};