const { onRequest, onCall, HttpsError } = require("firebase-functions/v2/https");
const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { setGlobalOptions } = require("firebase-functions/v2");
const admin = require("firebase-admin");

const evaluateAttempt = require("./src/evaluateAttempt");
const {
  computeEvaluation,
  normalizeAttemptData,
} = require("./src/evaluateAttempt");
const { recomputeInterviewResult } = require("./src/aggregateInterview");

if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.firestore();

setGlobalOptions({
  region: "us-central1",
  maxInstances: 10,
});

function sendJson(res, statusCode, payload) {
  return res.status(statusCode).json(payload);
}

exports.helloNlp = onRequest(
  {
    region: "us-central1",
    cors: true,
    timeoutSeconds: 60,
    memory: "256MiB",
  },
  (req, res) => {
    res.status(200).send("NLP functions setup is working");
  }
);

exports.evaluateAttemptHttp = onRequest(
  {
    region: "us-central1",
    cors: true,
    timeoutSeconds: 120,
    memory: "512MiB",
  },
  async (req, res) => {
    try {
      if (req.method !== "POST") {
        return sendJson(res, 405, {
          success: false,
          error: "Method not allowed. Use POST.",
        });
      }

      const body = req.body || {};

      const hasFirestoreMode = !!body.interviewId && !!body.attemptId;
      const hasDirectMode =
        !!(body.questionText || body.question) && !!body.correctAnswer;

      if (!hasFirestoreMode && !hasDirectMode) {
        return sendJson(res, 400, {
          success: false,
          error:
            "Send either interviewId and attemptId, or questionText and correctAnswer and userAnswer.",
        });
      }

      if (hasFirestoreMode) {
        const { interviewId, attemptId, forceReevaluate = false } = body;

        const attemptRef = db
          .collection("interviews")
          .doc(interviewId)
          .collection("attempts")
          .doc(attemptId);

        const attemptSnap = await attemptRef.get();

        if (!attemptSnap.exists) {
          return sendJson(res, 404, {
            success: false,
            error: "Attempt document not found.",
          });
        }

        const attemptData = attemptSnap.data();

        const result = await evaluateAttempt(
          db,
          interviewId,
          attemptId,
          attemptData,
          { forceReevaluate }
        );

        const updatedSnap = await attemptRef.get();

        return sendJson(res, 200, {
          success: true,
          mode: "firestore",
          data: updatedSnap.exists ? updatedSnap.data() : result,
        });
      }

      const directAttemptData = normalizeAttemptData({
        questionText: body.questionText || body.question,
        correctAnswer: body.correctAnswer,
        userAnswer: body.userAnswer,
        status: body.status || "answered",
        questionId: body.questionId || null,
      });

      const result = await computeEvaluation(directAttemptData, { db });

      return sendJson(res, 200, {
        success: true,
        mode: "direct",
        data: result,
      });
    } catch (error) {
      console.error("evaluateAttemptHttp error:", error);

      return sendJson(res, error.statusCode || 500, {
        success: false,
        error: error.message || "Internal server error",
      });
    }
  }
);

exports.evaluateAttemptOnCreate = onDocumentCreated(
  {
    document: "interviews/{interviewId}/attempts/{attemptId}",
    region: "us-central1",
    memory: "512MiB",
    timeoutSeconds: 120,
  },
  async (event) => {
    try {
      const interviewId = event.params.interviewId;
      const attemptId = event.params.attemptId;
      const attemptData = event.data?.data();

      if (!attemptData) {
        console.warn("No attempt data found in trigger");
        return;
      }

      await evaluateAttempt(db, interviewId, attemptId, attemptData);
      console.log(`Successfully evaluated attempt ${attemptId}`);
    } catch (error) {
      console.error("evaluateAttemptOnCreate error:", error);
    }
  }
);

exports.recomputeInterviewResultCallable = onCall(
  {
    region: "us-central1",
    memory: "256MiB",
    timeoutSeconds: 60,
  },
  async (request) => {
    const { interviewId } = request.data || {};

    if (!interviewId || typeof interviewId !== "string") {
      throw new HttpsError("invalid-argument", "interviewId is required");
    }

    try {
      const result = await recomputeInterviewResult(db, interviewId);

      return {
        success: true,
        ...result,
      };
    } catch (error) {
      console.error("recomputeInterviewResultCallable error:", error);
      throw new HttpsError("internal", error.message || "Aggregation failed");
    }
  }
);