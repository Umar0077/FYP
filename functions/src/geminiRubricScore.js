// src/geminiRubricScore.js
const { GoogleGenerativeAI } = require("@google/generative-ai");
const functions = require("firebase-functions");

// Initialize Gemini AI
const apiKey = functions.config().gemini?.api_key || process.env.GEMINI_API_KEY;
const genAI = new GoogleGenerativeAI(apiKey);

/**
 * Get rubric-based scoring from Gemini with strict JSON output
 * Retries once if JSON parsing fails
 */
async function getGeminiRubricScore(questionText, correctAnswer, userAnswer, retryCount = 0) {
  const model = genAI.getGenerativeModel({
    model: process.env.GEMINI_MODEL || "gemini-2.0-flash-exp",
    generationConfig: {
      responseMimeType: "application/json",
      temperature: 0.3,
    },
  });

  const prompt = `You are an expert technical interviewer evaluating a candidate's answer.

Question: "${questionText}"

Correct Answer: "${correctAnswer}"

Candidate's Answer: "${userAnswer}"

Evaluate the candidate's answer based on these criteria:

1. RELEVANCE (0-100): Does the answer address the question and stay on topic?
   - Penalize off-topic content
   - Penalize unrelated extra information
   - Reward focused, on-topic responses

2. ACCURACY (0-100): How correct is the answer compared to the correct answer?
   - Penalize wrong claims and made-up facts
   - Penalize missing key points
   - Reward correct information
   - Very short answers should get lower scores

Provide your evaluation as JSON with this exact structure:
{
  "relevanceScore": <number 0-100>,
  "accuracyScore": <number 0-100>,
  "missingPoints": [<array of strings, key points missing from the answer>],
  "wrongClaims": [<array of strings, incorrect statements in the answer>],
  "feedback": "<one short sentence summarizing the answer quality>"
}

Return ONLY valid JSON, no other text.`;

  try {
    const result = await model.generateContent(prompt);
    const response = result.response;
    const text = response.text();

    // Parse JSON response
    const parsed = JSON.parse(text);

    // Validate structure
    if (
      typeof parsed.relevanceScore !== "number" ||
      typeof parsed.accuracyScore !== "number"
    ) {
      throw new Error("Invalid score format in response");
    }

    // Clamp scores to 0-100
    return {
      relevanceScore: Math.max(0, Math.min(100, Math.round(parsed.relevanceScore))),
      accuracyScore: Math.max(0, Math.min(100, Math.round(parsed.accuracyScore))),
      missingPoints: Array.isArray(parsed.missingPoints) ? parsed.missingPoints : [],
      wrongClaims: Array.isArray(parsed.wrongClaims) ? parsed.wrongClaims : [],
      feedback: parsed.feedback || "Answer evaluated",
    };
  } catch (error) {
    console.error("Error getting Gemini rubric score:", error);

    // Retry once with stricter instruction
    if (retryCount === 0) {
      console.log("Retrying with stricter instruction...");
      await new Promise((resolve) => setTimeout(resolve, 1000)); // Wait 1 second
      return getGeminiRubricScore(questionText, correctAnswer, userAnswer, 1);
    }

    // If retry also fails, throw error
    throw new Error(`Gemini rubric scoring failed after retry: ${error.message}`);
  }
}

module.exports = {
  getGeminiRubricScore,
};
