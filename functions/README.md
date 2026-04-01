# Firebase Cloud Functions - Interview Answer Evaluator

This Firebase Cloud Functions module provides automated evaluation of interview answers using Google Gemini AI and semantic embeddings.

## Features

- **Automatic Evaluation**: Triggers on each interview attempt creation
- **Dual Scoring System**: 
  - Gemini AI rubric-based scoring (relevance & accuracy)
  - Semantic similarity using embeddings
- **Smart Caching**: Caches correct answer embeddings to reduce API costs
- **Aggregate Results**: Computes interview-level scores for result screens
- **Error Handling**: Robust retry logic and error handling

## Project Structure

```
functions/
├── src/
│   ├── index.js                 # Main Cloud Functions exports
│   ├── evaluateAttempt.js       # Attempt evaluation logic
│   ├── aggregateInterview.js    # Interview aggregate computation
│   ├── geminiRubricScore.js     # Gemini rubric scoring
│   ├── geminiEmbeddings.js      # Embeddings generation
│   ├── cosineSimilarity.js      # Cosine similarity calculation
│   └── firestoreCache.js        # Firestore caching utilities
├── package.json
└── README.md
```

## Prerequisites

1. **Node.js 18+** installed
2. **Firebase CLI** installed: `npm install -g firebase-tools`
3. **Firebase project** with Firestore enabled
4. **Google Gemini API key** (get from Google AI Studio)

## Setup Instructions

### 1. Initialize Firebase Functions

If you haven't already initialized functions in your Firebase project:

```bash
cd Nova-Prep-main
firebase init functions
```

Select:
- Use an existing project (select your Firebase project)
- Language: JavaScript
- ESLint: Your choice
- Install dependencies: Yes

### 2. Install Dependencies

```bash
cd functions
npm install
```

### 3. Set Environment Variables

Set your Gemini API key as a secret:

```bash
firebase functions:secrets:set GEMINI_API_KEY
```

When prompted, paste your Gemini API key.

Optionally, set model names (defaults are provided):

```bash
# Set Gemini model for rubric scoring (optional)
firebase functions:config:set gemini.model="gemini-2.0-flash-exp"

# Set embedding model (optional)
firebase functions:config:set gemini.embedding_model="text-embedding-004"
```

To use secrets in your functions:
```bash
# For local development, create .env file
echo "GEMINI_API_KEY=your-api-key-here" > .env
```

### 4. Deploy Functions

Deploy all functions to Firebase:

```bash
firebase deploy --only functions
```

Or deploy specific functions:

```bash
# Deploy only the evaluation trigger
firebase deploy --only functions:evaluateAttempt

# Deploy only the aggregation callable
firebase deploy --only functions:recomputeInterviewResult
```

## Usage

### Automatic Evaluation

The `evaluateAttempt` function automatically triggers when a new attempt is created at:
```
interviews/{interviewId}/attempts/{attemptId}
```

It will:
1. Check if the attempt is already evaluated
2. Skip evaluation for skipped attempts
3. Get Gemini rubric scores
4. Compute semantic similarity using embeddings
5. Combine scores into final relevance and accuracy
6. Write results back to the attempt document

### Manual Aggregation

Call the `recomputeInterviewResult` function from your Flutter app:

```dart
import 'package:cloud_functions/cloud_functions.dart';

Future<void> computeInterviewResults(String interviewId) async {
  final callable = FirebaseFunctions.instance.httpsCallable('recomputeInterviewResult');
  
  try {
    final result = await callable.call({
      'interviewId': interviewId,
    });
    
    print('Results computed: ${result.data}');
  } catch (e) {
    print('Error computing results: $e');
  }
}
```

## Data Structure

### Attempt Document
```javascript
{
  questionId: "string",
  questionText: "string",
  correctAnswer: "string",
  userAnswer: "string",
  status: "answered" | "skipped",
  
  // Added by evaluation
  relevanceGemini: 0-100,
  accuracyGemini: 0-100,
  embeddingSimilarity: 0-1,
  embeddingScore: 0-100,
  relevanceFinal: 0-100,
  accuracyFinal: 0-100,
  feedback: "string",
  missingPoints: ["string"],
  wrongClaims: ["string"],
  evaluatedAt: timestamp,
  evaluatorVersion: "v1",
  evaluationError: "string" // optional
}
```

### Interview Document
```javascript
{
  startedAt: timestamp,
  endedAt: timestamp,
  
  // Added by aggregation
  accuracyOverall: 0-100,
  relevanceOverall: 0-100,
  answeredCount: number,
  skippedCount: number,
  wrongCount: number,
  totalCount: number,
  resultUpdatedAt: timestamp,
  resultVersion: "v1"
}
```

## Scoring Logic

### Final Scores Calculation
- `relevanceFinal = 0.6 × relevanceGemini + 0.4 × embeddingScore`
- `accuracyFinal = 0.8 × accuracyGemini + 0.2 × embeddingScore`

### Interview Aggregates
- `accuracyOverall = average(accuracyFinal)` for answered attempts
- `relevanceOverall = average(relevanceFinal)` for answered attempts
- `wrongCount = count(accuracyFinal < 50)` for answered attempts

## Local Testing

Run functions locally using the Firebase emulator:

```bash
cd functions
npm run serve
```

This starts the Functions emulator and allows you to test without deploying.

## Monitoring

View function logs in real-time:

```bash
firebase functions:log
```

Or view logs in the Firebase Console:
1. Go to Firebase Console
2. Select your project
3. Navigate to Functions → Logs

## Cost Optimization

- **Caching**: Correct answer embeddings are cached in `questions/{questionId}` to avoid redundant API calls
- **Text Truncation**: User answers and correct answers are truncated to 4000 characters
- **Single Evaluation**: Attempts are only evaluated once (checked via `evaluatedAt` field)

## Troubleshooting

### Function not triggering
- Check Firestore path matches exactly: `interviews/{interviewId}/attempts/{attemptId}`
- Verify the document is being created (not updated)
- Check function logs for errors

### API Key errors
- Ensure `GEMINI_API_KEY` secret is set correctly
- Verify the API key has access to Gemini API
- Check quota limits in Google Cloud Console

### Parsing errors
- The function retries once with stricter instructions
- Check `evaluationError` field in attempt document
- Review function logs for detailed error messages

## License

MIT
