import 'package:flutter/material.dart';
import '../widgets/AppScaffold.dart';

class PracticalQuestionsScreen extends StatefulWidget {
	const PracticalQuestionsScreen({super.key});

	@override
	State<PracticalQuestionsScreen> createState() => _PracticalQuestionsScreenState();
}

class _PracticalQuestionsScreenState extends State<PracticalQuestionsScreen> with TickerProviderStateMixin {
	final TextEditingController _answerController = TextEditingController();
	int _currentQuestion = 1;
	int _totalQuestions = 10;
	int _timeRemaining = 300; // 5 minutes in seconds
	bool _isRecording = false;
	bool _isAnswerSubmitted = false;
  
	// Sample questions - you can replace with your data source
	final List<String> _questions = [
		"Tell me about a challenging project you worked on and how you overcame the obstacles.",
		"How would you handle a situation where you disagree with your team lead's approach?",
		"Describe a time when you had to learn a new technology quickly. How did you approach it?",
		"How would you prioritize tasks when everything seems urgent?",
		"Tell me about a mistake you made and how you handled it.",
	];

	@override
	void initState() {
		super.initState();
		_startTimer();
	}

	void _startTimer() {
		Future.delayed(const Duration(seconds: 1), () {
			if (mounted && _timeRemaining > 0 && !_isAnswerSubmitted) {
				setState(() {
					_timeRemaining--;
				});
				_startTimer();
			}
		});
	}

	String _formatTime(int seconds) {
		int minutes = seconds ~/ 60;
		int remainingSeconds = seconds % 60;
		return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
	}

	void _submitAnswer() {
		setState(() {
			_isAnswerSubmitted = true;
		});
		_showFeedbackDialog();
	}

	void _nextQuestion() {
		if (_currentQuestion < _totalQuestions) {
			setState(() {
				_currentQuestion++;
				_timeRemaining = 300;
				_isAnswerSubmitted = false;
				_answerController.clear();
			});
			_startTimer();
		} else {
			// Go to results screen
			Navigator.of(context).pushReplacementNamed('/interview_result');
		}
	}

	void _skipQuestion() {
		_nextQuestion();
	}

	void _retryQuestion() {
		setState(() {
			_timeRemaining = 300;
			_isAnswerSubmitted = false;
			_answerController.clear();
		});
		_startTimer();
	}

	void _showFeedbackDialog() {
		final bool isDark = Theme.of(context).brightness == Brightness.dark;
		final Color dialogBg = isDark ? const Color(0xFF0B0F4E) : Colors.white;
		final Color textColor = isDark ? Colors.white : const Color(0xFF0A0F2E);
		final Color buttonBg = isDark ? Colors.white : const Color(0xFF00002E);
		final Color buttonFg = isDark ? const Color(0xFF00002E) : Colors.white;

		showDialog<void>(
			context: context,
			barrierDismissible: false,
			builder: (BuildContext context) {
				return Dialog(
					backgroundColor: dialogBg,
					shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
					child: Padding(
						padding: const EdgeInsets.all(20),
						child: Column(
							mainAxisSize: MainAxisSize.min,
							crossAxisAlignment: CrossAxisAlignment.start,
							children: <Widget>[
								Text('AI Feedback', style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.w700)),
								const SizedBox(height: 16),
								Text('Strengths:', style: TextStyle(color: textColor, fontWeight: FontWeight.w600)),
								const SizedBox(height: 4),
								Text('• Clear communication and structured response\n• Good use of specific examples\n• Confident delivery', 
										 style: TextStyle(color: textColor, fontSize: 12)),
								const SizedBox(height: 12),
								Text('Areas for Improvement:', style: TextStyle(color: textColor, fontWeight: FontWeight.w600)),
								const SizedBox(height: 4),
								Text('• Could provide more quantifiable results\n• Consider mentioning lessons learned\n• Add more detail about your role', 
										 style: TextStyle(color: textColor, fontSize: 12)),
								const SizedBox(height: 20),
								Row(
									children: <Widget>[
										Expanded(
											child: OutlinedButton(
												style: OutlinedButton.styleFrom(
													side: BorderSide(color: isDark ? const Color(0xFF27308A) : const Color(0xFFD6DBFF)),
													shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
													foregroundColor: textColor,
													padding: const EdgeInsets.symmetric(vertical: 10),
												),
												onPressed: () {
													Navigator.of(context).pop();
													_retryQuestion();
												},
												child: const Text('Retry'),
											),
										),
										const SizedBox(width: 10),
										Expanded(
											child: ElevatedButton(
												style: ElevatedButton.styleFrom(
													backgroundColor: buttonBg,
													foregroundColor: buttonFg,
													shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
													padding: const EdgeInsets.symmetric(vertical: 10),
													elevation: 0,
												),
												onPressed: () {
													Navigator.of(context).pop();
													_nextQuestion();
												},
												child: Text(_currentQuestion == _totalQuestions ? 'Finish' : 'Next'),
											),
										),
									],
								),
							],
						),
					),
				);
			},
		);
	}

	@override
	Widget build(BuildContext context) {
		final bool isDark = Theme.of(context).brightness == Brightness.dark;
		final Color backgroundColor = isDark ? const Color(0xFF00002E) : Colors.white;
		final Color cardColor = isDark ? const Color(0xFF0B0F4E) : const Color(0xFFF5F6FA);
		final Color borderColor = isDark ? const Color(0xFF27308A) : const Color(0xFFD6DBFF);
		final Color textColor = isDark ? Colors.white : const Color(0xFF0A0F2E);
		final Color secondaryTextColor = isDark ? Colors.white70 : const Color(0xFF27308A);
		final Color hintColor = isDark ? Colors.white38 : const Color(0xFF8A93B2);
		final Color chipColor = isDark ? const Color(0xFF131964) : const Color(0xFFE8EBF8);
		final Color micBg = isDark ? Colors.white : const Color(0xFF00002E);
		final Color micIcon = isDark ? const Color(0xFF00002E) : Colors.white;
		final Color buttonBg = isDark ? Colors.white : const Color(0xFF00002E);
		final Color buttonFg = isDark ? const Color(0xFF00002E) : Colors.white;
		final Color timerColor = _timeRemaining <= 60 ? Colors.red : secondaryTextColor;

		return AppScaffold(
			appBarTitle: 'Practical Questions',
			backgroundColor: backgroundColor,
			resizeToAvoidBottomInset: true,
			body: SafeArea(
				child: SingleChildScrollView(
					padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
					child: Column(
						mainAxisSize: MainAxisSize.min,
						crossAxisAlignment: CrossAxisAlignment.start,
						children: <Widget>[
							// Progress and Timer Row
							Row(
								mainAxisAlignment: MainAxisAlignment.spaceBetween,
								children: <Widget>[
									Container(
										padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
										decoration: BoxDecoration(
											color: chipColor,
											borderRadius: BorderRadius.circular(14),
										),
										child: Text('$_currentQuestion / $_totalQuestions', style: TextStyle(color: textColor, fontSize: 12)),
									),
									Container(
										padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
										decoration: BoxDecoration(
											color: _timeRemaining <= 60 ? Colors.red.withOpacity(0.1) : chipColor,
											borderRadius: BorderRadius.circular(14),
											border: _timeRemaining <= 60 ? Border.all(color: Colors.red) : null,
										),
										child: Row(
											mainAxisSize: MainAxisSize.min,
											children: <Widget>[
												Icon(Icons.timer, color: timerColor, size: 16),
												const SizedBox(width: 4),
												Text(_formatTime(_timeRemaining), style: TextStyle(color: timerColor, fontSize: 12, fontWeight: FontWeight.w600)),
											],
										),
									),
								],
							),
							const SizedBox(height: 20),

							// Progress Bar
							ClipRRect(
								borderRadius: BorderRadius.circular(4),
								child: LinearProgressIndicator(
									value: _currentQuestion / _totalQuestions,
									minHeight: 6,
									color: isDark ? Colors.white : const Color(0xFF00002E),
									backgroundColor: isDark ? const Color(0xFF27308A) : const Color(0xFFD6DBFF),
								),
							),
							const SizedBox(height: 24),

							// Question Card
							Container(
								width: double.infinity,
								padding: const EdgeInsets.all(20),
								decoration: BoxDecoration(
									color: cardColor,
									borderRadius: BorderRadius.circular(16),
									border: Border.all(color: borderColor),
								),
								child: Column(
									crossAxisAlignment: CrossAxisAlignment.start,
									children: <Widget>[
										Text('Question', style: TextStyle(color: secondaryTextColor, fontSize: 12, fontWeight: FontWeight.w600)),
										const SizedBox(height: 8),
										Text(
											_questions[(_currentQuestion - 1) % _questions.length],
											style: TextStyle(color: textColor, fontSize: 16, height: 1.4),
										),
									],
								),
							),
							const SizedBox(height: 20),

							// Answer Input
							Container(
								height: 200,
								decoration: BoxDecoration(
									color: cardColor,
									borderRadius: BorderRadius.circular(16),
									border: Border.all(color: borderColor),
								),
									child: Column(
										children: <Widget>[
											Container(
												height: 120,
												padding: const EdgeInsets.all(16),
												child: TextField(
													controller: _answerController,
													maxLines: null,
													enabled: !_isAnswerSubmitted,
													style: TextStyle(color: textColor),
													decoration: InputDecoration(
														hintText: 'Type your answer here...',
														hintStyle: TextStyle(color: hintColor),
														border: InputBorder.none,
														contentPadding: const EdgeInsets.all(4),
													),
												),
											),
											Container(
												padding: const EdgeInsets.all(16),
												decoration: BoxDecoration(
													color: isDark ? const Color(0xFF131964) : const Color(0xFFE8EBF8),
													borderRadius: const BorderRadius.only(
														bottomLeft: Radius.circular(16),
														bottomRight: Radius.circular(16),
													),
												),
												child: Row(
													children: <Widget>[
														Text('Voice Response', style: TextStyle(color: secondaryTextColor, fontSize: 12)),
														const Spacer(),
														GestureDetector(
															onTap: _isAnswerSubmitted ? null : () {
																setState(() {
																	_isRecording = !_isRecording;
																});
															},
															child: Container(
																width: 40,
																height: 40,
																decoration: BoxDecoration(
																	color: _isRecording ? Colors.red : micBg,
																	shape: BoxShape.circle,
																),
																child: Icon(
																	_isRecording ? Icons.stop : Icons.mic,
																	color: _isRecording ? Colors.white : micIcon,
																	size: 20,
																),
															),
														),
													],
												),
											),
										],
									),
								),
							const SizedBox(height: 20),

							// Action Buttons
							if (!_isAnswerSubmitted)
								Row(
									children: <Widget>[
										Flexible(
											child: OutlinedButton(
												style: OutlinedButton.styleFrom(
													side: BorderSide(color: borderColor),
													shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
													foregroundColor: textColor,
													padding: const EdgeInsets.symmetric(vertical: 14),
												),
												onPressed: _skipQuestion,
												child: const Text('Skip', style: TextStyle(fontSize: 14)),
											),
										),
										const SizedBox(width: 12),
										Flexible(
											flex: 2,
											child: ElevatedButton(
												style: ElevatedButton.styleFrom(
													backgroundColor: buttonBg,
													foregroundColor: buttonFg,
													shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
													padding: const EdgeInsets.symmetric(vertical: 14),
													elevation: 0,
												),
												onPressed: _answerController.text.trim().isNotEmpty || _isRecording ? _submitAnswer : null,
												child: const Text('Submit Answer', style: TextStyle(fontSize: 14)),
											),
										),
									],
								),

							// View Performance Button
							const SizedBox(height: 12),
							Center(
								child: TextButton.icon(
									onPressed: () {
										// Navigate to performance reports
										ScaffoldMessenger.of(context).showSnackBar(
											const SnackBar(content: Text('Performance reports coming soon')),
										);
									},
									icon: Icon(Icons.analytics_outlined, color: secondaryTextColor, size: 16),
									label: Text('View Past Performance', style: TextStyle(color: secondaryTextColor, fontSize: 12)),
								),
							),
						],
					),
				),
			),
		);
	}

	@override
	void dispose() {
		_answerController.dispose();
		super.dispose();
	}
}