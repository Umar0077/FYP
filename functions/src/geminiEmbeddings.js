// src/geminiEmbeddings.js
const { GoogleGenerativeAI } = require("@google/generative-ai");
const functions = require("firebase-functions");

// Initialize Gemini AI
const apiKey = functions.config().gemini?.api_key || process.env.GEMINI_API_KEY;
const genAI = new GoogleGenerativeAI(apiKey);

/**
 * Generate embeddings for text using Gemini API
 * Returns array of floats
 */
async function getEmbedding(text) {
  if (!text || text.trim() === "") {
    console.warn("Empty text provided for embedding");
    return null;
  }

  try {
    const model = genAI.getGenerativeModel({
      model: process.env.EMBEDDING_MODEL || "text-embedding-004",
    });

    const result = await model.embedContent(text);
    const embedding = result.embedding;

    if (!embedding || !embedding.values || !Array.isArray(embedding.values)) {
      throw new Error("Invalid embedding response structure");
    }

    return embedding.values;
  } catch (error) {
    console.error("Error generating embedding:", error);
    throw new Error(`Embedding generation failed: ${error.message}`);
  }
}

module.exports = {
  getEmbedding,
};
