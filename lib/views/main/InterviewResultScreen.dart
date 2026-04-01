import 'package:flutter/material.dart';
import '../widgets/GlassCard.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:developer' as developer;

class InterviewResultScreen extends StatefulWidget {
	final String? interviewId;
	const InterviewResultScreen({super.key, this.interviewId});

	@override
	State<InterviewResultScreen> createState() => _InterviewResultScreenState();
}

class _InterviewResultScreenState extends State<InterviewResultScreen> {
	bool _loading = true;
	double _avgRelevance = 0.0;
	double _avgAccuracy = 0.0;
	int _answeredCount = 0;
	int _totalCount = 0;
	int _wrongCount = 0;
	Map<String, dynamic>? _confidenceAnalysis;

	@override
	void initState() {
		super.initState();
		_loadResults();
	}

	Future<void> _loadResults() async {
		if (widget.interviewId == null) {
			setState(() => _loading = false);
			return;
		}

		try {
			final uid = FirebaseAuth.instance.currentUser?.uid;
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
					setState(() => _loading = false);
					return;
				}

				developer.log('Loaded interview_result document: ${resultDoc.id}', name: 'InterviewResultScreen');
				_applyDataToState(data);
				return;
			}

			// Backward compatibility: fallback to legacy interviews document.
			final legacyDoc = await FirebaseFirestore.instance
					.collection('interviews')
					.doc(widget.interviewId)
					.get();

			if (legacyDoc.exists) {
				final data = legacyDoc.data()!;
				developer.log('Loaded legacy interviews document: ${legacyDoc.id}', name: 'InterviewResultScreen');
				_applyDataToState(data);
			} else {
				developer.log('Interview result document not found: ${widget.interviewId}', name: 'InterviewResultScreen', level: 900);
				setState(() => _loading = false);
			}
		} catch (e) {
			developer.log('Error loading results: $e', name: 'InterviewResultScreen', error: e, level: 1000);
			setState(() => _loading = false);
		}
	}

	void _applyDataToState(Map<String, dynamic> data) {
		final confidenceMap = _normalizeConfidenceMap(data);
		setState(() {
			_avgRelevance = _asDouble(data['avgRelevance']);
			_avgAccuracy = _asDouble(data['avgAccuracy']);
			_answeredCount = _asInt(data['answeredQuestions'] ?? data['answeredCount']);
			_totalCount = _asInt(data['totalQuestions'] ?? data['totalCount']);
			_wrongCount = _asInt(data['wrongAnswers'] ?? data['wrongCount']);
			_confidenceAnalysis = confidenceMap;
			_loading = false;
		});
	}

	Map<String, dynamic>? _normalizeConfidenceMap(Map<String, dynamic> data) {
		if (data['confidenceAnalysis'] is Map<String, dynamic>) {
			final confidence = Map<String, dynamic>.from(data['confidenceAnalysis'] as Map<String, dynamic>);
			final level = _asDouble(confidence['confidence_level'] ?? confidence['confidenceLevel']);
			confidence['confidence_level'] = level <= 1.0 ? level * 100 : level;
			confidence['confidence_label'] = (confidence['confidence_label'] ?? confidence['confidenceLabel'] ?? 'unknown').toString();
			return confidence;
		}

		if (data['confidenceLevel'] != null || data['confidenceLabel'] != null || data['confidenceAnalysisSummary'] != null) {
			var level = _asDouble(data['confidenceLevel']);
			if (level <= 1.0) {
				level = level * 100;
			}

			return {
				'confidence_level': level,
				'confidence_label': (data['confidenceLabel'] ?? 'unknown').toString(),
				'reasoning': (data['confidenceAnalysisSummary'] ?? '').toString(),
			};
		}

		return null;
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

		final int rawCorrect = _answeredCount - _wrongCount;
		final int correctCount = rawCorrect < 0 ? 0 : rawCorrect;
		final int rawSkipped = _totalCount - _answeredCount;
		final int skippedCount = rawSkipped < 0 ? 0 : rawSkipped;

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
															onPressed: () => Navigator.of(context).pushReplacementNamed('/interview'),
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