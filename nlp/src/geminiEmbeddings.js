const { GoogleGenerativeAI } = require("@google/generative-ai");

function getGeminiClient() {
  const apiKey = "AIzaSyClS4elyb-G8wRReuKnL3rkZgAYfepYEnk";

  if (!apiKey) {
    throw new Error("GEMINI_API_KEY is not set");
  }

  return new GoogleGenerativeAI(apiKey);
}

async function getEmbedding(text) {
  if (!text || text.trim() === "") {
    console.warn("Empty text provided for embedding");
    return null;
  }

  try {
    const genAI = getGeminiClient();

    const model = genAI.getGenerativeModel({
      model: "gemini-embedding-001",
    });

    const result = await model.embedContent(text);
    const values = result?.embedding?.values;

    if (!Array.isArray(values)) {
      throw new Error("Invalid embedding response structure");
    }

    return values;
  } catch (error) {
    console.error("Error generating embedding:", error);
    throw new Error(`Embedding generation failed: ${error.message}`);
  }
}

module.exports = {
  getEmbedding,
};