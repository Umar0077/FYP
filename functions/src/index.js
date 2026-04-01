// src/index.js
const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { onCall, HttpsError } = require("firebase-functions/v2/https");
const admin = require("firebase-admin");
const { setGlobalOptions } = require("firebase-functions/v2");

// Initialize Firebase Admin
admin.initializeApp();

// Set global options
setGlobalOptions({
  region: "us-central1",
  maxInstances: 10,
});

// Import evaluation modules
const evaluateAttemptHandler = require("./evaluateAttempt");
const { recomputeInterviewResult } = require("./aggregateInterview");

/**
 * Firestore trigger: Evaluates an interview attempt when created
 * Triggers on: interviews/{interviewId}/attempts/{attemptId}
 */
exports.evaluateAttempt = onDocumentCreated(
  {
    document: "interviews/{interviewId}/attempts/{attemptId}",
    region: "us-central1",
    memory: "512MiB",
    timeoutSeconds: 120,
  },
  async (event) => {
    const interviewId = event.params.interviewId;
    const attemptId = event.params.attemptId;
    const attemptData = event.data.data();

    console.log(`Evaluating attempt ${attemptId} for interview ${interviewId}`);

    try {
      await evaluateAttemptHandler(admin.firestore(), interviewId, attemptId, attemptData);
      console.log(`Successfully evaluated attempt ${attemptId}`);
    } catch (error) {
      console.error(`Error evaluating attempt ${attemptId}:`, error);
      // Don't rethrow - we've already written error to Firestore
    }
  }
);

/**
 * Callable function: Recomputes interview result aggregates
 * Called by: Flutter app when interview ends
 */
exports.recomputeInterviewResult = onCall(
  {
    region: "us-central1",
    memory: "256MiB",
    timeoutSeconds: 60,
  },
  async (request) => {
    const { interviewId } = request.data;

    if (!interviewId || typeof interviewId !== "string") {
      throw new HttpsError("invalid-argument", "interviewId is required");
    }

    console.log(`Recomputing result for interview ${interviewId}`);

    try {
      const result = await recomputeInterviewResult(admin.firestore(), interviewId);
      console.log(`Successfully recomputed interview ${interviewId}`, result);
      return {
        success: true,
        ...result,
      };
    } catch (error) {
      console.error(`Error recomputing interview ${interviewId}:`, error);
      throw new HttpsError("internal", error.message);
    }
  }
);
