const { GoogleGenerativeAI } = require("@google/generative-ai");

function getGeminiClient() {
  const apiKey = "AIzaSyClS4elyb-G8wRReuKnL3rkZgAYfepYEnk";

  if (!apiKey) {
    throw new Error("GEMINI_API_KEY is not set");
  }

  return new GoogleGenerativeAI(apiKey);
}

function cleanJsonText(text) {
  if (!text) return "";
  return text
    .replace(/```json/g, "")
    .replace(/```/g, "")
    .trim();
}

async function getGeminiRubricScore(
  questionText,
  correctAnswer,
  userAnswer,
  retryCount = 0
) {
  const genAI = getGeminiClient();

  const model = genAI.getGenerativeModel({
    model: "gemini-2.5-flash",
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

1. RELEVANCE (0 to 100): Does the answer address the question and stay on topic?
2. ACCURACY (0 to 100): How correct is the answer compared to the correct answer?

Rules:
1. Penalize off topic content
2. Penalize unrelated extra information
3. Penalize wrong claims and made up facts
4. Penalize missing key points
5. Reward correct and focused answers
6. Very short answers should get lower scores

Return ONLY valid JSON with this exact structure:
{
  "relevanceScore": 0,
  "accuracyScore": 0,
  "missingPoints": [],
  "wrongClaims": [],
  "feedback": ""
}`;

  try {
    const result = await model.generateContent(prompt);
    const text = cleanJsonText(result?.response?.text());
    const parsed = JSON.parse(text);

    if (
      typeof parsed.relevanceScore !== "number" ||
      typeof parsed.accuracyScore !== "number"
    ) {
      throw new Error("Invalid score format in response");
    }

    return {
      relevanceScore: Math.max(0, Math.min(100, Math.round(parsed.relevanceScore))),
      accuracyScore: Math.max(0, Math.min(100, Math.round(parsed.accuracyScore))),
      missingPoints: Array.isArray(parsed.missingPoints) ? parsed.missingPoints : [],
      wrongClaims: Array.isArray(parsed.wrongClaims) ? parsed.wrongClaims : [],
      feedback: typeof parsed.feedback === "string" ? parsed.feedback : "Answer evaluated",
    };
  } catch (error) {
    console.error("Error getting Gemini rubric score:", error);

    if (retryCount === 0) {
      await new Promise((resolve) => setTimeout(resolve, 1000));
      return getGeminiRubricScore(
        questionText,
        correctAnswer,
        userAnswer,
        retryCount + 1
      );
    }

    throw new Error(`Gemini rubric scoring failed after retry: ${error.message}`);
  }
}

module.exports = {
  getGeminiRubricScore,
};