import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:nova_prep/services/gemini_service.dart';
import '../../services/streak_service.dart';
import '../../services/interview_service.dart';
import '../../services/interview_result_service.dart';
import '../../services/gemini_confidence_analyzer.dart';
import '../../controllers/emotion_tracking_controller.dart';
import 'InterviewResultScreen.dart';
import '../widgets/AppScaffold.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import 'package:get/get.dart';
import 'package:camera/camera.dart';
import '../../config/emotion_tracking_config.dart';

class InterviewScreen extends StatefulWidget {
	final String difficulty;
	final int? count;
	final String? position;
	final String? interviewType;
	const InterviewScreen({
		super.key,
		this.difficulty = 'Easy',
		this.count,
		this.position,
		this.interviewType,
	});

	@override
	State<InterviewScreen> createState() => _InterviewScreenState();
}

class _InterviewScreenState extends State<InterviewScreen> with WidgetsBindingObserver {
	final TextEditingController _answerController = TextEditingController();
	final GeminiService _gemini = GeminiService();
	final GeminiConfidenceAnalyzer _confidenceAnalyzer = GeminiConfidenceAnalyzer();
	final EmotionTrackingController _emotionController = Get.put(EmotionTrackingController());
	late stt.SpeechToText _speech;

	List<String> _questions = [];
	List<String> _correctAnswers = [];
	String? _interviewId;
	int _questionIndex = 0;
	String _feedback = '';
	int _timeLeft = 20;
	Timer? _timer;
	bool _loading = true;
	bool _checking = false;
	bool _isListening = false;
	bool _speechAvailable = false;
	int _answeredCount = 0;
	int _requiredAnswerCount = 0;
	bool _isFinishingInterview = false;
	bool _hasSavedFinalResult = false;

	Widget _buildEmotionPreview() {
		if (!EmotionTrackingConfig.showCameraPreview) {
			return const SizedBox.shrink();
		}

		return Obx(() {
			final CameraController? controller = _emotionController.cameraController;
			final canShowPreview =
					_emotionController.isActive.value && controller != null && controller.value.isInitialized;

			if (!canShowPreview) {
				return const SizedBox.shrink();
			}

			return Container(
				width: EmotionTrackingConfig.previewWidth,
				height: EmotionTrackingConfig.previewHeight,
				decoration: BoxDecoration(
					color: Colors.black,
					borderRadius: BorderRadius.circular(12),
					border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
					boxShadow: [
						BoxShadow(
							color: Colors.black.withValues(alpha: 0.18),
							blurRadius: 8,
							offset: const Offset(0, 3),
						),
					],
				),
				child: ClipRRect(
					borderRadius: BorderRadius.circular(11),
					child: Stack(
						children: [
							Positioned.fill(child: CameraPreview(controller)),
							Align(
								alignment: Alignment.bottomLeft,
								child: Container(
									padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
									color: Colors.black.withValues(alpha: 0.45),
									child: const Text(
										'Live',
										style: TextStyle(color: Colors.white, fontSize: 10),
									),
								),
							),
						],
					),
				),
			);
		});
	}

	@override
	void initState() {
		super.initState();
		WidgetsBinding.instance.addObserver(this);
		_speech = stt.SpeechToText();
		_initSpeech();
		_loadQuestions();
		_initEmotionTracking();
	}

	Future<void> _initSpeech() async {
		var status = await Permission.microphone.request();
		if (status.isGranted) {
			bool available = await _speech.initialize(
				onStatus: (status) {
					if (status == 'done' || status == 'notListening') {
						if (mounted) setState(() => _isListening = false);
					}
				},
				onError: (error) {
					if (mounted) {
						setState(() => _isListening = false);
						ScaffoldMessenger.of(context).showSnackBar(
							SnackBar(content: Text('Error: ${error.errorMsg}')),
						);
					}
				},
			);
			if (mounted) setState(() => _speechAvailable = available);
		}
	}

	@override
	void dispose() {
		WidgetsBinding.instance.removeObserver(this);
		_timer?.cancel();
		_answerController.dispose();
		_speech.stop();
		_emotionController.stopTracking();
		super.dispose();
	}

	Future<void> _initEmotionTracking() async {
		final hasPermission = await _emotionController.checkCameraPermission();

		if (!hasPermission) {
			final granted = await _emotionController.requestCameraPermission();

			if (!granted && mounted) {
				ScaffoldMessenger.of(context).showSnackBar(
					const SnackBar(
						content: Text('Camera permission denied. Confidence analysis will be limited.'),
						duration: Duration(seconds: 3),
					),
				);
				return;
			}
		}

		final started = await _emotionController.startTracking();

		if (!started && mounted) {
			ScaffoldMessenger.of(context).showSnackBar(
				const SnackBar(
					content: Text('Emotion tracking unavailable. Continuing interview without it.'),
					duration: Duration(seconds: 3),
				),
			);
		}
	}

	Future<void> _toggleListening() async {
		if (!_speechAvailable) {
			ScaffoldMessenger.of(context).showSnackBar(
				const SnackBar(content: Text('Speech recognition not available')),
			);
			return;
		}

		if (_isListening) {
			await _speech.stop();
			if (mounted) setState(() => _isListening = false);
		} else {
			if (mounted) setState(() => _isListening = true);
			await _speech.listen(
				onResult: (result) {
					if (mounted) {
						setState(() {
							_answerController.text = result.recognizedWords;
						});
					}
				},
				listenFor: const Duration(seconds: 30),
				pauseFor: const Duration(seconds: 5),
				listenOptions: stt.SpeechListenOptions(
					partialResults: true,
					cancelOnError: true,
				),
			);
		}
	}

	Future<void> _loadQuestions() async {
		try {
			final int requestedCount = (widget.count != null && widget.count! > 0)
					? widget.count!
					: 3;

			final result = await _gemini.generateQuestionsWithAnswers(
				difficulty: widget.difficulty,
				count: requestedCount,
				position: widget.position,
				interviewType: widget.interviewType,
			);

			final qs = result['questions'] ?? [];
			final correctAnswers = result['answers'] ?? [];

			if (mounted) {
				setState(() {
					_questions = qs;
					_correctAnswers = correctAnswers;
					_requiredAnswerCount = requestedCount > 0 ? requestedCount : qs.length;
				});

				_interviewId = await InterviewService.createInterviewSession(
					difficulty: widget.difficulty,
					questionCount: _requiredAnswerCount > 0 ? _requiredAnswerCount : qs.length,
					position: widget.position,
					interviewType: widget.interviewType,
				);

				if (mounted) {
					setState(() {
						_loading = false;
					});
					_startTimer();
				}
			}
		} catch (e) {
      Get.log('Error loading questions: $e', isError: true);
			final err = e.toString().toLowerCase();
			final isKeyIssue = err.contains('api key') ||
				err.contains('unauthenticated') ||
				err.contains('permission denied') ||
				err.contains('developer_error');
			if (mounted) {
				setState(() {
					_loading = false;
					_questions = [
						isKeyIssue
							? 'Gemini API key was rejected. Open Settings and save a valid key, then restart the interview.'
							: 'Error loading questions. Please restart the interview.',
					];
				});
			}
		}
	}

	Future<bool> _appendReplacementQuestion() async {
		try {
			final result = await _gemini.generateQuestionsWithAnswers(
				difficulty: widget.difficulty,
				count: 1,
				position: widget.position,
				interviewType: widget.interviewType,
			);

			final nextQuestions = result['questions'] ?? const <String>[];
			final nextAnswers = result['answers'] ?? const <String>[];

			if (nextQuestions.isEmpty || nextAnswers.isEmpty) {
				return false;
			}

			_questions.add(nextQuestions.first);
			_correctAnswers.add(nextAnswers.first);
			return true;
		} catch (e, st) {
			developer.log(
				'Failed to load replacement question: $e',
				name: 'InterviewScreen._appendReplacementQuestion',
				error: e,
				stackTrace: st,
				level: 900,
			);
			return false;
		}
	}

	void _startTimer() {
		_timer?.cancel();
		_timeLeft = 20;
		_timer = Timer.periodic(const Duration(seconds: 1), (t) {
			if (_timeLeft <= 1) {
				t.cancel();
				_nextQuestion(auto: true);
			} else {
				setState(() => _timeLeft--);
			}
		});
	}

	Future<void> _nextQuestion({bool auto = false, bool forceSkip = false}) async {
		if (_checking || _questions.isEmpty) return;
		setState(() => _checking = true);

		_timer?.cancel();
		final currentQuestion = _questions[_questionIndex];
		final userAnswer = forceSkip ? '' : _answerController.text.trim();

		if (!auto && !forceSkip && userAnswer.isEmpty) {
			ScaffoldMessenger.of(context).showSnackBar(
				const SnackBar(content: Text('Please type your answer before proceeding.')),
			);
			setState(() => _checking = false);
			_startTimer();
			return;
		}

		String status = 'skipped';
		String feedback = 'Skipped';

		if (userAnswer.isNotEmpty) {
			status = 'answered';
			_answeredCount++;

			String correctAns = _correctAnswers[_questionIndex].toLowerCase();
			String userAns = userAnswer.toLowerCase();

			List<String> correctWords =
					correctAns.split(RegExp(r'\W+')).where((w) => w.length > 3).toList();
			int matchCount = correctWords.where((word) => userAns.contains(word)).length;

			if (matchCount >= (correctWords.length * 0.3)) {
				feedback = '✓ Correct';
			} else {
				feedback = '✗ Incorrect';
			}
		} else {
		}

		if (_interviewId != null && _questionIndex < _correctAnswers.length) {
			await InterviewService.addAttemptToInterview(
				interviewId: _interviewId!,
				questionId: 'q_$_questionIndex',
				questionText: currentQuestion,
				correctAnswer: _correctAnswers[_questionIndex],
				userAnswer: userAnswer.isEmpty ? '' : userAnswer,
				status: status,
				position: widget.position,
				interviewType: widget.interviewType,
			);
		}

		setState(() => _feedback = feedback);
		await Future.delayed(const Duration(seconds: 2));

		final int requiredAnswers = _requiredAnswerCount > 0 ? _requiredAnswerCount : _questions.length;
		if (_answeredCount >= requiredAnswers) {
			_showFinishDialog();
			return;
		}

		if (_questionIndex >= _questions.length - 1) {
			final bool loadedReplacement = await _appendReplacementQuestion();
			if (!loadedReplacement) {
				_questions.add('Describe a challenging technical problem you solved and how you solved it.');
				_correctAnswers.add('A strong answer explains the problem context, your technical approach, trade-offs, and measurable outcome.');
				if (mounted) {
					ScaffoldMessenger.of(context).showSnackBar(
						const SnackBar(
							content: Text('Could not load a new AI question. Continuing with a fallback question.'),
						),
					);
				}
			}
		}

		if (_questionIndex < _questions.length - 1) {
			setState(() {
				_questionIndex++;
				_answerController.clear();
				_feedback = '';
				_checking = false;
			});
			_startTimer();
		} else {
			_showFinishDialog();
		}
	}

	void _showFinishDialog() async {
		if (_isFinishingInterview) {
			developer.log('Finish flow already running. Ignoring duplicate trigger.', name: 'InterviewScreen');
			return;
		}

		_isFinishingInterview = true;
		_timer?.cancel();

		try {
			await _emotionController.stopTracking();
			final rawEmotionReport = _emotionController.getEmotionReport();
			final emotionReport = rawEmotionReport ?? <String, dynamic>{};

			if (_interviewId != null && !_hasSavedFinalResult) {
				final completionResult = await InterviewService.completeInterview(_interviewId!);
				final safeCompletionResult = completionResult ?? <String, dynamic>{};
				final confidenceResult = await _analyzeConfidence(
					emotionReport: emotionReport,
					completionResult: safeCompletionResult,
				);

				await _saveInterviewResultToFirestore(
					interviewId: _interviewId!,
					completionResult: safeCompletionResult,
					confidenceResult: confidenceResult,
					emotionReport: emotionReport,
				);
				_hasSavedFinalResult = true;
			}
		} catch (e, st) {
			developer.log(
				'Failed during finish flow: $e',
				name: 'InterviewScreen',
				error: e,
				stackTrace: st,
				level: 1000,
			);
		} finally {
			_isFinishingInterview = false;
		}

		StreakService.recordPracticeToday();

		if (!mounted) return;

		showDialog<void>(
			context: context,
			barrierDismissible: false,
			builder: (_) => AlertDialog(
				title: const Text('Interview Complete!'),
				content: Text(
					'You have answered all ${_requiredAnswerCount > 0 ? _requiredAnswerCount : _questions.length} required questions. What would you like to do next?',
				),
				actions: [
					TextButton(
						onPressed: () {
							Navigator.of(context).pop();
							Navigator.of(context).pushReplacement(
								MaterialPageRoute(
									builder: (_) => InterviewResultScreen(interviewId: _interviewId),
								),
							);
						},
						child: const Text('See Results'),
					),
					TextButton(
						onPressed: () {
							Navigator.of(context).pop();
							Navigator.of(context).pushReplacementNamed('/job_suggestions');
						},
						child: const Text('See Job Suggestions'),
					),
				],
			),
		);
	}

	Future<void> _saveInterviewResultToFirestore({
		required String interviewId,
		required Map<String, dynamic> completionResult,
		required Map<String, dynamic> confidenceResult,
		required Map<String, dynamic> emotionReport,
	}) async {
		final double relevanceOverall =
				(completionResult['relevanceOverall'] as num?)?.toDouble() ??
				(completionResult['avgRelevance'] as num?)?.toDouble() ??
				0.0;
		final double accuracyOverall =
				(completionResult['accuracyOverall'] as num?)?.toDouble() ??
				(completionResult['avgAccuracy'] as num?)?.toDouble() ??
				0.0;
		final int totalCount = (completionResult['totalCount'] as num?)?.toInt() ??
				(completionResult['totalQuestions'] as num?)?.toInt() ??
				_questions.length;
		final int answeredCount = (completionResult['answeredCount'] as num?)?.toInt() ??
				(completionResult['answeredQuestions'] as num?)?.toInt() ??
				_answeredCount;
		final int wrongCount = (completionResult['wrongCount'] as num?)?.toInt() ??
				(completionResult['wrongAnswers'] as num?)?.toInt() ??
				0;
		final int correctCount = (completionResult['correctCount'] as num?)?.toInt() ??
				(answeredCount - wrongCount).clamp(0, answeredCount);
		final int skippedCount = (completionResult['skippedCount'] as num?)?.toInt() ??
				(totalCount - answeredCount).clamp(0, totalCount);

		await InterviewResultService.saveInterviewResultToFirestore(
			interviewId: interviewId,
			avgRelevance: relevanceOverall,
			avgAccuracy: accuracyOverall,
			relevanceOverall: relevanceOverall,
			accuracyOverall: accuracyOverall,
			answeredCount: answeredCount,
			skippedCount: skippedCount,
			wrongCount: wrongCount,
			correctCount: correctCount,
			totalCount: totalCount,
			questionCount: (completionResult['questionCount'] as num?)?.toInt() ?? totalCount,
			evaluatedAnsweredCount: (completionResult['evaluatedAnsweredCount'] as num?)?.toInt(),
			resultVersion: completionResult['resultVersion']?.toString(),
			resultSource: completionResult['resultSource']?.toString() ?? 'attempt_aggregated_in_app',
			difficulty: completionResult['difficulty']?.toString(),
			startedAt: completionResult['startedAt'],
			confidenceAnalysis: confidenceResult,
			emotionReport: emotionReport.isEmpty ? null : emotionReport,
			status: (completionResult['status']?.toString().isNotEmpty ?? false)
					? completionResult['status'].toString()
					: 'completed',
		);
	}

	Future<Map<String, dynamic>> _analyzeConfidence({
		required Map<String, dynamic> emotionReport,
		required Map<String, dynamic> completionResult,
	}) async {
		try {
			developer.log('Running confidence analysis...', name: 'InterviewScreen');

			final requiredQuestions = (completionResult['questionCount'] as num?)?.toInt() ??
					(_requiredAnswerCount > 0 ? _requiredAnswerCount : _questions.length);
			final totalQuestions = (completionResult['totalQuestions'] as num?)?.toInt() ??
					(completionResult['totalCount'] as num?)?.toInt() ??
					requiredQuestions;
			final answeredQuestions = (completionResult['answeredQuestions'] as num?)?.toInt() ??
					(completionResult['answeredCount'] as num?)?.toInt() ??
					_answeredCount;
			final skippedQuestions = (completionResult['skippedCount'] as num?)?.toInt() ??
					(totalQuestions - answeredQuestions).clamp(0, totalQuestions);
			final avgRelevance = (completionResult['relevanceOverall'] as num?)?.toDouble() ??
					(completionResult['avgRelevance'] as num?)?.toDouble() ??
					0.0;
			final avgAccuracy = (completionResult['accuracyOverall'] as num?)?.toDouble() ??
					(completionResult['avgAccuracy'] as num?)?.toDouble() ??
					0.0;

			final summary =
					'Interview completed: target=$requiredQuestions answered, actual answered=$answeredQuestions, skipped=$skippedQuestions, total asked=$totalQuestions, relevanceOverall=${avgRelevance.toStringAsFixed(1)}, accuracyOverall=${avgAccuracy.toStringAsFixed(1)}';
			final nlpScores = {
				'avg_relevance': avgRelevance / 100,
				'avg_accuracy': avgAccuracy / 100,
				'answered_ratio': requiredQuestions == 0 ? 0.0 : answeredQuestions / requiredQuestions,
				'completion_rate': requiredQuestions == 0 ? 0.0 : answeredQuestions / requiredQuestions,
			};

			final confidenceResult = await _confidenceAnalyzer.analyzeConfidence(
				interviewSummary: summary,
				nlpScores: nlpScores,
				emotionReport: emotionReport,
			);

			if (confidenceResult != null) {
				developer.log(
					'Confidence analysis ready: ${confidenceResult['confidence_label']}',
					name: 'InterviewScreen',
				);
				return confidenceResult;
			}

			return {
				'confidence_level': 0.0,
				'confidence_label': 'low',
				'reasoning': 'Confidence analysis unavailable',
			};
		} catch (e) {
			developer.log('Error analyzing confidence: $e', name: 'InterviewScreen', error: e);
			return {
				'confidence_level': 0.0,
				'confidence_label': 'low',
				'reasoning': 'Confidence analysis failed safely',
			};
		}
	}

	@override
	Widget build(BuildContext context) {
		final bool isDark = Theme.of(context).brightness == Brightness.dark;
		final Color backgroundColor = isDark ? const Color(0xFF00002E) : Colors.white;
		final Color cardColor = isDark ? const Color(0xFF0B0F4E) : const Color(0xFFF5F6FA);
		final Color borderColor = isDark ? const Color(0xFF27308A) : const Color(0xFFD6DBFF);
		final Color labelColor = isDark ? Colors.white70 : const Color(0xFF27308A);
		final Color textColor = isDark ? Colors.white : const Color(0xFF0A0F2E);
		final Color hintColor = isDark ? Colors.white38 : const Color(0xFF8A93B2);
		final Color chipColor = isDark ? const Color(0xFF131964) : const Color(0xFFE8EBF8);
		final Color micBg = isDark ? Colors.white : const Color(0xFF00002E);
		final Color micIcon = isDark ? const Color(0xFF00002E) : Colors.white;
		final Color nextBtnBg = isDark ? Colors.white : const Color(0xFF00002E);
		final Color nextBtnFg = isDark ? const Color(0xFF00002E) : Colors.white;
		final Color backBtnFg = isDark ? Colors.white : const Color(0xFF00002E);

		return AppScaffold(
			appBarTitle: 'Flutter Interview',
			backgroundColor: backgroundColor,
			body: SafeArea(
				child: Stack(
					children: [
						if (_loading)
							const Center(child: CircularProgressIndicator())
						else
							Center(
								child: SingleChildScrollView(
									child: ConstrainedBox(
										constraints: const BoxConstraints(maxWidth: 520),
										child: Padding(
											padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
											child: Column(
												crossAxisAlignment: CrossAxisAlignment.start,
												children: <Widget>[
													Obx(() {
														if (_emotionController.isActive.value) {
															return Container(
																margin: const EdgeInsets.only(bottom: 8),
																padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
																decoration: BoxDecoration(
																	color: Colors.green.withValues(alpha: 0.1),
																	border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
																	borderRadius: BorderRadius.circular(8),
																),
																child: const Row(
																	mainAxisSize: MainAxisSize.min,
																	children: [
																		Icon(Icons.video_camera_front, size: 14, color: Colors.green),
																		SizedBox(width: 6),
																		Text('Confidence tracking active', style: TextStyle(color: Colors.green, fontSize: 11)),
																	],
																),
															);
														}
														if (_emotionController.statusMessage.value.isNotEmpty) {
															return Container(
																margin: const EdgeInsets.only(bottom: 8),
																padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
																decoration: BoxDecoration(
																	color: Colors.orange.withValues(alpha: 0.1),
																	border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
																	borderRadius: BorderRadius.circular(8),
																),
																child: Row(
																	mainAxisSize: MainAxisSize.min,
																	children: [
																		const Icon(Icons.info_outline, size: 14, color: Colors.orange),
																		const SizedBox(width: 6),
																		Expanded(
																			child: Text(
																				_emotionController.statusMessage.value,
																				style: const TextStyle(color: Colors.orange, fontSize: 11),
																				overflow: TextOverflow.ellipsis,
																			),
																		),
																	],
																),
															);
														}
														return const SizedBox.shrink();
													}),
													Row(
														mainAxisAlignment: MainAxisAlignment.end,
														children: [Text('$_timeLeft s', style: TextStyle(color: labelColor))],
													),
													Row(
														mainAxisAlignment: MainAxisAlignment.spaceBetween,
														children: [
															Container(
																padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
																decoration: BoxDecoration(color: chipColor, borderRadius: BorderRadius.circular(14)),
																child: Text('Question ${_questionIndex + 1}', style: TextStyle(color: textColor, fontSize: 12)),
															),
															Text('Answered $_answeredCount/${_requiredAnswerCount > 0 ? _requiredAnswerCount : _questions.length}', style: TextStyle(color: labelColor)),
														],
													),
													const SizedBox(height: 16),
													Container(
														width: double.infinity,
														height: 160,
														decoration: BoxDecoration(
															color: cardColor,
															borderRadius: BorderRadius.circular(12),
															border: Border.all(color: borderColor),
														),
														child: Center(
															child: Padding(
																padding: const EdgeInsets.all(12),
																child: Text(
																	_questions[_questionIndex],
																	textAlign: TextAlign.center,
																	style: TextStyle(color: labelColor, fontSize: 16),
																),
															),
														),
													),
													const SizedBox(height: 16),
													Container(
														decoration: BoxDecoration(
															color: cardColor,
															borderRadius: BorderRadius.circular(12),
															border: Border.all(color: borderColor),
														),
														child: TextField(
															controller: _answerController,
															minLines: 4,
															maxLines: 6,
															style: TextStyle(color: textColor),
															decoration: InputDecoration(
																hintText: 'Type your answer',
																hintStyle: TextStyle(color: hintColor),
																border: InputBorder.none,
																contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
															),
														),
													),
													const SizedBox(height: 12),
													if (_feedback.isNotEmpty)
														Center(
															child: Text(
																_feedback,
																style: TextStyle(
																	color: _feedback == 'Correct' ? Colors.greenAccent : Colors.redAccent,
																	fontWeight: FontWeight.bold,
																),
															),
														),
													const SizedBox(height: 18),
													Center(
														child: Container(
															width: 56,
															height: 56,
															decoration: BoxDecoration(
																color: _isListening ? Colors.red : micBg,
																shape: BoxShape.circle,
															),
															child: IconButton(
																icon: Icon(
																	_isListening ? Icons.stop : Icons.mic_none,
																	color: _isListening ? Colors.white : micIcon,
																),
																onPressed: _toggleListening,
															),
														),
													),
													if (_isListening)
														Center(
															child: Padding(
																padding: const EdgeInsets.only(top: 8),
																child: const Text('Listening... Tap to stop', style: TextStyle(color: Colors.red, fontSize: 12)),
															),
														),
													const SizedBox(height: 24),
													Row(
														mainAxisAlignment: MainAxisAlignment.spaceBetween,
														children: [
															OutlinedButton(
																style: OutlinedButton.styleFrom(
																	side: BorderSide(color: borderColor),
																	shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
																	foregroundColor: backBtnFg,
																	padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
																),
																onPressed: () => Navigator.of(context).pop(),
																child: const Text('Back'),
															),
															OutlinedButton(
																style: OutlinedButton.styleFrom(
																	side: const BorderSide(color: Colors.orange),
																	shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
																	foregroundColor: Colors.orange,
																	padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
																),
																onPressed: _checking ? null : () => _nextQuestion(forceSkip: true),
																child: const Text('Skip'),
															),
															ElevatedButton(
																style: ElevatedButton.styleFrom(
																	backgroundColor: nextBtnBg,
																	foregroundColor: nextBtnFg,
																	shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
																	padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
																	elevation: 0,
																),
																onPressed: _checking ? null : () => _nextQuestion(),
																child: const Text('Next'),
															),
														],
													),
												],
											),
										),
									),
								),
							),
						if (EmotionTrackingConfig.showCameraPreview)
							Positioned(
								top: 8,
								right: 12,
								child: IgnorePointer(
									ignoring: true,
									child: _buildEmotionPreview(),
								),
							),
					],
				),
			),
		);
	}
}
