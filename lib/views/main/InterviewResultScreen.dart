import 'package:flutter/material.dart';
import '../widgets/GlassCard.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import 'dart:developer' as developer;
import 'InterviewScreen.dart';

class InterviewResultScreen extends StatefulWidget {
	final String? interviewId;
	final String? difficulty;
	final int? questionCount;
	final String? position;
	final String? interviewType;
	const InterviewResultScreen({
		super.key,
		this.interviewId,
		this.difficulty,
		this.questionCount,
		this.position,
		this.interviewType,
	});

	@override
	State<InterviewResultScreen> createState() => _InterviewResultScreenState();
}

class _InterviewResultScreenState extends State<InterviewResultScreen> {
	bool _loading = true;
	bool _waitingForBackendAggregate = false;
	double _avgRelevance = 0.0;
	double _avgAccuracy = 0.0;
	int _skippedCount = 0;
	int _correctCount = 0;
	int _totalCount = 0;
	int _wrongCount = 0;
	Map<String, dynamic>? _confidenceAnalysis;
	String? _restartDifficulty;
	int? _restartQuestionCount;
	String? _restartPosition;
	String? _restartInterviewType;

	@override
	void initState() {
		super.initState();
		_restartDifficulty = widget.difficulty;
		_restartQuestionCount = widget.questionCount;
		_restartPosition = widget.position;
		_restartInterviewType = widget.interviewType;
		_loadResults();
	}

	void _hydrateRestartConfig(Map<String, dynamic> data) {
		final String? fetchedDifficulty = (data['difficulty'] ?? data['level'])?.toString().trim();
		final String? fetchedPosition = (data['position'] ?? data['domain'])?.toString().trim();
		final String? fetchedInterviewType = data['interviewType']?.toString().trim();
		final int fetchedQuestionCount = _asInt(
			data['questionCount'] ?? data['totalQuestions'] ?? data['totalCount'],
		);

		_restartDifficulty = (widget.difficulty?.trim().isNotEmpty ?? false)
				? widget.difficulty!.trim()
				: ((fetchedDifficulty?.isNotEmpty ?? false) ? fetchedDifficulty : _restartDifficulty);

		_restartPosition = (widget.position?.trim().isNotEmpty ?? false)
				? widget.position!.trim()
				: ((fetchedPosition?.isNotEmpty ?? false) ? fetchedPosition : _restartPosition);

		_restartInterviewType = (widget.interviewType?.trim().isNotEmpty ?? false)
				? widget.interviewType!.trim()
				: ((fetchedInterviewType?.isNotEmpty ?? false)
						? fetchedInterviewType
						: _restartInterviewType);

		if ((widget.questionCount ?? 0) > 0) {
			_restartQuestionCount = widget.questionCount;
		} else if (fetchedQuestionCount > 0) {
			_restartQuestionCount = fetchedQuestionCount;
		}
	}

	void _restartInterview() {
		final String difficulty = (_restartDifficulty?.trim().isNotEmpty ?? false)
				? _restartDifficulty!.trim()
				: 'Easy';

		Navigator.of(context).pushReplacement(
			MaterialPageRoute(
				builder: (_) => InterviewScreen(
					difficulty: difficulty,
					count: (_restartQuestionCount ?? 0) > 0 ? _restartQuestionCount : null,
					position: _restartPosition,
					interviewType: _restartInterviewType,
				),
			),
		);
	}

	Future<void> _loadResults({int retryAttempt = 0}) async {
		if (widget.interviewId == null) {
			setState(() {
				_loading = false;
				_waitingForBackendAggregate = false;
			});
			return;
		}

		try {
			final uid = FirebaseAuth.instance.currentUser?.uid;
			Map<String, dynamic> mergedData = <String, dynamic>{};

			final resultDoc = await FirebaseFirestore.instance
					.collection('interview_result')
					.doc(widget.interviewId)
					.get();

			if (resultDoc.exists) {
				final data = resultDoc.data()!;
				if (uid != null && data['userId'] != uid) {
					developer.log(
						'Result document does not belong to current user: ${resultDoc.id}',
						name: 'InterviewResultScreen',
						level: 1000,
					);
					setState(() {
						_loading = false;
						_waitingForBackendAggregate = false;
					});
					return;
				}

				developer.log('Loaded interview_result document: ${resultDoc.id}', name: 'InterviewResultScreen');
				mergedData.addAll(data);
			}

			// Always check interviews document to read backend aggregate fields.
			final legacyDoc = await FirebaseFirestore.instance
					.collection('interviews')
					.doc(widget.interviewId)
					.get();

			if (legacyDoc.exists) {
				final data = legacyDoc.data()!;
				developer.log('Loaded legacy interviews document: ${legacyDoc.id}', name: 'InterviewResultScreen');
				mergedData = {
					...data,
					...mergedData,
					'relevanceOverall': mergedData['relevanceOverall'] ?? data['relevanceOverall'],
					'accuracyOverall': mergedData['accuracyOverall'] ?? data['accuracyOverall'],
					'avgRelevance': mergedData['avgRelevance'] ?? data['avgRelevance'],
					'avgAccuracy': mergedData['avgAccuracy'] ?? data['avgAccuracy'],
					'answeredCount': mergedData['answeredCount'] ?? data['answeredCount'],
					'skippedCount': mergedData['skippedCount'] ?? data['skippedCount'],
					'wrongCount': mergedData['wrongCount'] ?? data['wrongCount'],
					'correctCount': mergedData['correctCount'] ?? data['correctCount'],
					'totalCount': mergedData['totalCount'] ?? data['totalCount'],
					'evaluatedAnsweredCount':
							mergedData['evaluatedAnsweredCount'] ?? data['evaluatedAnsweredCount'],
				};
			}

			if (mergedData.isEmpty) {
				developer.log('Interview result document not found: ${widget.interviewId}', name: 'InterviewResultScreen', level: 900);
				setState(() {
					_loading = false;
					_waitingForBackendAggregate = false;
				});
				return;
			}

			developer.log(
				'Data read by result screen (merged): ${_safeJson(mergedData)}',
				name: 'InterviewResultScreen',
			);

			_hydrateRestartConfig(mergedData);

			if (!_hasUsableAggregateFields(mergedData)) {
				if (retryAttempt < 5) {
					developer.log(
						'Backend aggregate fields not ready yet. Retrying load (${retryAttempt + 1}/5)',
						name: 'InterviewResultScreen',
						level: 900,
					);
					await Future<void>.delayed(const Duration(seconds: 2));
					if (!mounted) return;
					return _loadResults(retryAttempt: retryAttempt + 1);
				}

				setState(() {
					_loading = false;
					_waitingForBackendAggregate = true;
					final answered = _asInt(mergedData['answeredQuestions'] ?? mergedData['answeredCount']);
					final wrong = _asInt(mergedData['wrongAnswers'] ?? mergedData['wrongCount']);
					final total = _asInt(mergedData['totalQuestions'] ?? mergedData['totalCount']);
					final skipped = _asInt(mergedData['skippedCount']);
					_wrongCount = wrong;
					_skippedCount = skipped > 0 ? skipped : (total - answered).clamp(0, total);
					_totalCount = total > 0 ? total : (answered + _skippedCount);
					_correctCount = _asInt(mergedData['correctCount']);
					if (_correctCount <= 0) {
						_correctCount = (answered - wrong).clamp(0, answered);
					}
				});
				return;
			} else {
				developer.log('Final Firestore aggregate loaded for interviewId=${widget.interviewId}', name: 'InterviewResultScreen');
				_applyDataToState(mergedData);
			}
		} catch (e) {
			developer.log('Error loading results: $e', name: 'InterviewResultScreen', error: e, level: 1000);
			setState(() {
				_loading = false;
				_waitingForBackendAggregate = false;
			});
		}
	}

	void _applyDataToState(Map<String, dynamic> data) {
		final confidenceMap = _normalizeConfidenceMap(data);
		final int answered = _asInt(data['answeredQuestions'] ?? data['answeredCount']);
		final int wrong = _asInt(data['wrongAnswers'] ?? data['wrongCount']);
		final int total = _asInt(data['totalQuestions'] ?? data['totalCount']);
		final int skippedFromDoc = _asInt(data['skippedCount']);
		final int skipped = skippedFromDoc > 0 ? skippedFromDoc : (total - answered).clamp(0, total);
		final int correctFromDoc = _asInt(data['correctCount']);
		final int correct = correctFromDoc > 0 ? correctFromDoc : (answered - wrong).clamp(0, answered);

		setState(() {
			_avgRelevance = _asDouble(data['relevanceOverall'] ?? data['avgRelevance']);
			_avgAccuracy = _asDouble(data['accuracyOverall'] ?? data['avgAccuracy']);
			_skippedCount = skipped;
			_correctCount = correct;
			_totalCount = total > 0 ? total : (answered + skipped);
			_wrongCount = wrong;
			_confidenceAnalysis = confidenceMap;
			_loading = false;
			_waitingForBackendAggregate = false;
		});

		developer.log(
			'Result screen confidence map selected: ${_safeJson(confidenceMap)}',
			name: 'InterviewResultScreen',
		);
	}

	bool _hasUsableAggregateFields(Map<String, dynamic> data) {
		final relevanceOverall = data['relevanceOverall'];
		final accuracyOverall = data['accuracyOverall'];
		final avgRelevance = data['avgRelevance'];
		final avgAccuracy = data['avgAccuracy'];

		final hasOverall = relevanceOverall is num && accuracyOverall is num;
		final hasAvgFallback = avgRelevance is num && avgAccuracy is num;
		return hasOverall || hasAvgFallback;
	}

	Map<String, dynamic>? _normalizeConfidenceMap(Map<String, dynamic> data) {
		if (data['confidenceAnalysis'] is Map) {
			final rawConfidence = data['confidenceAnalysis'] as Map;
			final confidence = rawConfidence.map((k, v) => MapEntry(k.toString(), v));

			double level = _asDouble(
				confidence['confidence_level'] ?? confidence['confidenceLevel'] ?? data['confidenceLevel'],
			);
			if (level <= 1.0) {
				level = level * 100;
			}

			final label = _normalizeConfidenceLabel(
				confidence['confidence_label'] ?? confidence['confidenceLabel'] ?? data['confidenceLabel'],
				level,
			);

			final reasoning = (confidence['reasoning'] ?? data['confidenceAnalysisSummary'] ?? '').toString();
			final observations = _asStringList(
				confidence['emotion_based_observations'] ?? data['emotion_based_observations'],
			);
			final coachingTips = _asStringList(
				confidence['coaching_tips'] ?? data['coaching_tips'],
			);
			final emotionSummaryUsed = _asMap(
				confidence['emotion_summary_used'] ?? data['emotion_summary_used'],
			);

			return {
				...confidence,
				'confidence_level': level.clamp(0.0, 100.0),
				'confidence_label': label,
				'reasoning': reasoning,
				'emotion_based_observations': observations,
				'coaching_tips': coachingTips,
				if (emotionSummaryUsed != null) 'emotion_summary_used': emotionSummaryUsed,
			};
		}

		if (data['confidenceLevel'] != null || data['confidenceLabel'] != null || data['confidenceAnalysisSummary'] != null) {
			var level = _asDouble(data['confidenceLevel']);
			if (level <= 1.0) {
				level = level * 100;
			}

			return {
				'confidence_level': level,
				'confidence_label': _normalizeConfidenceLabel(data['confidenceLabel'], level),
				'reasoning': (data['confidenceAnalysisSummary'] ?? '').toString(),
				'emotion_based_observations': _asStringList(data['emotion_based_observations']),
				'coaching_tips': _asStringList(data['coaching_tips']),
				if (_asMap(data['emotion_summary_used']) != null)
					'emotion_summary_used': _asMap(data['emotion_summary_used']),
			};
		}

		return null;
	}

	String _normalizeConfidenceLabel(dynamic rawLabel, double level) {
		final normalized = rawLabel?.toString().trim().toLowerCase() ?? '';
		if (normalized == 'moderate') {
			return 'medium';
		}
		if (normalized == 'low' || normalized == 'medium' || normalized == 'high') {
			return normalized;
		}

		if (level >= 71.0) {
			return 'high';
		}
		if (level >= 41.0) {
			return 'medium';
		}
		return 'low';
	}

	Map<String, dynamic>? _asMap(dynamic value) {
		if (value is Map<String, dynamic>) return value;
		if (value is Map) {
			return value.map((key, val) => MapEntry(key.toString(), val));
		}
		return null;
	}

	List<String> _asStringList(dynamic value) {
		if (value is List) {
			return value
					.map((item) => item.toString().trim())
					.where((item) => item.isNotEmpty)
					.toList();
		}
		return const <String>[];
	}

	String _safeJson(Object? value) {
		try {
			return jsonEncode(value);
		} catch (_) {
			return value.toString();
		}
	}

	double _asDouble(dynamic value) {
		if (value is num) return value.toDouble();
		if (value is String) return double.tryParse(value) ?? 0.0;
		return 0.0;
	}

	int _asInt(dynamic value) {
		if (value is num) return value.toInt();
		if (value is String) return int.tryParse(value) ?? 0;
		return 0;
	}

	@override
	Widget build(BuildContext context) {
		final bool isDark = Theme.of(context).brightness == Brightness.dark;
		final Color backgroundColor = isDark ? const Color(0xFF00002E) : Colors.white;
		
		final Color textColor = isDark ? Colors.white : const Color(0xFF0A0F2E);
		final Color secondaryTextColor = isDark ? Colors.white70 : const Color(0xFF27308A);
		final Color progressBg = isDark ? const Color(0xFF27308A) : const Color(0xFFD6DBFF);

		if (_loading) {
			return Scaffold(
				backgroundColor: backgroundColor,
				body: const Center(child: CircularProgressIndicator()),
			);
		}

		if (_waitingForBackendAggregate) {
			return Scaffold(
				backgroundColor: backgroundColor,
				appBar: AppBar(
					backgroundColor: backgroundColor,
					elevation: 0,
					leading: IconButton(
						icon: Icon(Icons.arrow_back, color: textColor),
						onPressed: () => Navigator.of(context).pop(),
					),
					centerTitle: true,
					title: Text('Result', style: TextStyle(color: textColor, fontWeight: FontWeight.w700)),
				),
				body: Center(
					child: Padding(
						padding: const EdgeInsets.symmetric(horizontal: 24),
						child: Column(
							mainAxisSize: MainAxisSize.min,
							children: [
								const CircularProgressIndicator(),
								const SizedBox(height: 14),
								Text(
									'Final interview scoring is still processing on the server. Please try again in a moment.',
									textAlign: TextAlign.center,
									style: TextStyle(color: secondaryTextColor),
								),
								const SizedBox(height: 14),
								ElevatedButton(
									onPressed: () {
										setState(() => _loading = true);
										_loadResults();
									},
									child: const Text('Retry'),
								),
							],
						),
					),
				),
			);
		}

		final int correctCount = _correctCount < 0 ? 0 : _correctCount;
		final int skippedCount = _skippedCount < 0 ? 0 : _skippedCount;

		return Scaffold(
			backgroundColor: backgroundColor,
			appBar: AppBar(
				backgroundColor: backgroundColor,
				elevation: 0,
				leading: IconButton(
					icon: Icon(Icons.arrow_back, color: textColor),
					onPressed: () => Navigator.of(context).pop(),
				),
				centerTitle: true,
				title: Text('Result', style: TextStyle(color: textColor, fontWeight: FontWeight.w700)),
			),
			body: SafeArea(
				child: Center(
					child: SingleChildScrollView(
						child: ConstrainedBox(
							constraints: const BoxConstraints(maxWidth: 520),
							child: Padding(
								padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
								child: Column(
									crossAxisAlignment: CrossAxisAlignment.start,
									children: <Widget>[
										const SizedBox(height: 6),
										GlassCard(
											padding: const EdgeInsets.all(18),
											child: Column(
												crossAxisAlignment: CrossAxisAlignment.start,
												children: [
													Text('Your results are here!', style: TextStyle(color: secondaryTextColor, fontSize: 12)),
													const SizedBox(height: 16),
													Row(
														mainAxisAlignment: MainAxisAlignment.spaceBetween,
														children: <Widget>[
															_Legend(color: Colors.green, label: 'correct $correctCount / $_totalCount', textColor: secondaryTextColor),
															_Legend(color: Colors.orange, label: 'skipped $skippedCount / $_totalCount', textColor: secondaryTextColor),
															_Legend(color: Colors.red, label: 'wrong $_wrongCount / $_totalCount', textColor: secondaryTextColor),
														],
													),
													const SizedBox(height: 22),
													_Metric(label: 'Answer Relevance', value: _avgRelevance / 100, progressBg: progressBg, textColor: secondaryTextColor, score: _avgRelevance),
													_Metric(label: 'Answer Accuracy', value: _avgAccuracy / 100, progressBg: progressBg, textColor: secondaryTextColor, score: _avgAccuracy),
													
													// Confidence Analysis Section
													if (_confidenceAnalysis != null) ...[
														const SizedBox(height: 22),
														_buildConfidenceSection(secondaryTextColor, textColor, progressBg),
													],
												],
											),
										),
										const SizedBox(height: 28),
										GlassCard(
											padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
											borderRadius: 16,
											child: Column(
												children: [
													SizedBox(
														width: double.infinity,
														child: ElevatedButton(
															style: ElevatedButton.styleFrom(
																backgroundColor: isDark ? Colors.white : const Color(0xFF00002E),
																foregroundColor: isDark ? const Color(0xFF00002E) : Colors.white,
																shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
																padding: const EdgeInsets.symmetric(vertical: 14),
																elevation: 0,
															),
															onPressed: () => Navigator.of(context).pushNamed('/job_suggestions'),
															child: Row(
																mainAxisAlignment: MainAxisAlignment.center,
																children: <Widget>[
																	Icon(Icons.work_outline, size: 20),
																	const SizedBox(width: 8),
																	const Text('View Job Suggestions'),
																],
															),
														),
													),
													const SizedBox(height: 12),
													SizedBox(
														width: double.infinity,
														child: OutlinedButton(
															style: OutlinedButton.styleFrom(
																side: BorderSide(color: isDark ? const Color(0xFF27308A) : const Color(0xFFD6DBFF)),
																shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
																foregroundColor: isDark ? Colors.white : const Color(0xFF0A0F2E),
																padding: const EdgeInsets.symmetric(vertical: 14),
															),
															onPressed: _restartInterview,
															child: const Text('Restart Interview'),
														),
													),
													const SizedBox(height: 10),
													Center(
														child: TextButton(
															onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil('/home', (Route<dynamic> r) => false),
															child: Text('Back To Home', style: TextStyle(color: secondaryTextColor)),
														),
													),
												],
											),
										),
									],
								),
							),
						),
					),
				),
			),
		);
	}
	
	/// Build confidence analysis section
	Widget _buildConfidenceSection(Color secondaryTextColor, Color textColor, Color progressBg) {
		final confidenceLevel = (_confidenceAnalysis!['confidence_level'] ?? 0).toDouble();
		final confidenceLabel = _confidenceAnalysis!['confidence_label'] ?? 'unknown';
		final reasoning = _confidenceAnalysis!['reasoning'] ?? '';
		final observations = (_confidenceAnalysis!['emotion_based_observations'] as List?)?.cast<String>() ?? [];
		final coachingTips = (_confidenceAnalysis!['coaching_tips'] as List?)?.cast<String>() ?? [];
		
		// Determine color based on label
		Color labelColor;
		switch (confidenceLabel.toLowerCase()) {
			case 'high':
				labelColor = Colors.green;
				break;
			case 'medium':
				labelColor = Colors.orange;
				break;
			case 'low':
				labelColor = Colors.red;
				break;
			default:
				labelColor = Colors.grey;
		}
		
		return Column(
			crossAxisAlignment: CrossAxisAlignment.start,
			children: [
				Divider(color: secondaryTextColor.withValues(alpha: 0.2)),
				const SizedBox(height: 12),
				Row(
					children: [
						Icon(Icons.psychology, color: labelColor, size: 18),
						const SizedBox(width: 8),
						Text(
							'Confidence Analysis',
							style: TextStyle(
								color: textColor,
								fontSize: 14,
								fontWeight: FontWeight.bold,
							),
						),
					],
				),
				const SizedBox(height: 12),
				
				// Confidence Level Bar
				_Metric(
					label: 'Overall Confidence',
					value: confidenceLevel / 100,
					progressBg: progressBg,
					textColor: secondaryTextColor,
					score: confidenceLevel,
				),
				
				// Confidence Label Badge
				Container(
					padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
					decoration: BoxDecoration(
						color: labelColor.withValues(alpha: 0.1),
						border: Border.all(color: labelColor.withValues(alpha: 0.3)),
						borderRadius: BorderRadius.circular(8),
					),
					child: Text(
						confidenceLabel.toUpperCase(),
						style: TextStyle(
							color: labelColor,
							fontSize: 12,
							fontWeight: FontWeight.bold,
						),
					),
				),
				
				const SizedBox(height: 12),
				
				// Reasoning
				if (reasoning.isNotEmpty) ...[
					Text(
						reasoning,
						style: TextStyle(
							color: secondaryTextColor,
							fontSize: 12,
							height: 1.4,
						),
					),
					const SizedBox(height: 12),
				],
				
				// Emotion Observations
				if (observations.isNotEmpty) ...[
					Text(
						'Key Observations:',
						style: TextStyle(
							color: textColor,
							fontSize: 12,
							fontWeight: FontWeight.bold,
						),
					),
					const SizedBox(height: 6),
					...observations.map((obs) => Padding(
						padding: const EdgeInsets.only(bottom: 4, left: 8),
						child: Row(
							crossAxisAlignment: CrossAxisAlignment.start,
							children: [
								Text('• ', style: TextStyle(color: secondaryTextColor, fontSize: 12)),
								Expanded(
									child: Text(
										obs,
										style: TextStyle(color: secondaryTextColor, fontSize: 11),
									),
								),
							],
						),
					)),
					const SizedBox(height: 12),
				],
				
				// Coaching Tips
				if (coachingTips.isNotEmpty) ...[
					Text(
						'Coaching Tips:',
						style: TextStyle(
							color: textColor,
							fontSize: 12,
							fontWeight: FontWeight.bold,
						),
					),
					const SizedBox(height: 6),
					...coachingTips.map((tip) => Padding(
						padding: const EdgeInsets.only(bottom: 4, left: 8),
						child: Row(
							crossAxisAlignment: CrossAxisAlignment.start,
							children: [
								Text('💡 ', style: TextStyle(fontSize: 12)),
								Expanded(
									child: Text(
										tip,
										style: TextStyle(color: secondaryTextColor, fontSize: 11),
									),
								),
							],
						),
					)),
				],
			],
		);
	}
}

class _Legend extends StatelessWidget {
	const _Legend({required this.color, required this.label, required this.textColor});

	final Color color;
	final String label;
	final Color textColor;

	@override
	Widget build(BuildContext context) {
		return Row(
			children: <Widget>[
				Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
				const SizedBox(width: 6),
				Text(label, style: TextStyle(color: textColor, fontSize: 12)),
			],
		);
	}
}

class _Metric extends StatelessWidget {
	const _Metric({required this.label, required this.value, required this.progressBg, required this.textColor, required this.score});

	final String label;
	final double value;
	final Color progressBg;
	final Color textColor;
	final double score;

	@override
	Widget build(BuildContext context) {
		return Padding(
			padding: const EdgeInsets.symmetric(vertical: 10),
			child: Column(
				crossAxisAlignment: CrossAxisAlignment.start,
				children: <Widget>[
					Row(
						mainAxisAlignment: MainAxisAlignment.spaceBetween,
						children: [
							Text(label, style: TextStyle(color: textColor, fontSize: 12)),
							Text('${score.toStringAsFixed(1)}%', style: TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.bold)),
						],
					),
					const SizedBox(height: 6),
					ClipRRect(
						borderRadius: BorderRadius.circular(8),
						child: LinearProgressIndicator(
							value: value,
							minHeight: 6,
							color: Colors.white,
							backgroundColor: progressBg,
						),
					),
				],
			),
		);
	}
}