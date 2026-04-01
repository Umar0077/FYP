import 'package:flutter/material.dart';
import 'InterviewScreen.dart';
import 'ResourcesScreen.dart';
import '../widgets/AppScaffold.dart';

class InterviewPrepScreen extends StatefulWidget {
	const InterviewPrepScreen({super.key});

	@override
	State<InterviewPrepScreen> createState() => _InterviewPrepScreenState();
}

class _InterviewPrepScreenState extends State<InterviewPrepScreen> {
	String? _selectedPosition;
	String? _selectedInterviewType;
	String? _difficulty;
	int? _selectedCount;

	// Dropdown options
	final List<String> _positions = [
		'Software Engineer',
		'Frontend Developer',
		'Backend Developer',
		'Full Stack Developer',
		'Mobile Developer',
		'DevOps Engineer',
		'Data Engineer',
		'Data Scientist',
		'Machine Learning Engineer',
		'QA Engineer',
		'UI/UX Designer',
		'Product Manager',
		'System Architect',
	];

	final List<String> _interviewTypes = [
		'Technical Interview',
		'Behavioral Interview',
		'System Design Interview',
		'Coding Interview',
		'Phone Screening',
		'Panel Interview',
		'Case Interview',
		'HR Interview',
	];

	@override
	void dispose() {
		super.dispose();
	}

	@override
	Widget build(BuildContext context) {
		final bool isDark = Theme.of(context).brightness == Brightness.dark;
		final Color backgroundColor = isDark ? const Color(0xFF00002E) : Colors.white;
		final Color fieldColor = isDark ? const Color(0xFF0B0F4E) : const Color(0xFFF5F6FA);
		final Color borderClr = isDark ? const Color(0xFF27308A) : const Color(0xFFD6DBFF);
		final Color labelColor = isDark ? Colors.white70 : const Color(0xFF27308A);
		final Color textColor = isDark ? Colors.white : const Color(0xFF0A0F2E);
		final Color hintColor = isDark ? Colors.white38 : const Color(0xFF8A93B2);
		final Color chipSelected = isDark ? const Color(0xFF131964) : const Color(0xFFE8EBF8);
		final Color chipUnselected = isDark ? const Color(0xFF0B0F4E) : Colors.white;
		final Color chipBorder = isDark ? const Color(0xFF27308A) : const Color(0xFFD6DBFF);

		return AppScaffold(
			appBarTitle: 'Start Interview',
			backgroundColor: backgroundColor,
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
									Text('Position Applying For *', style: TextStyle(color: labelColor, fontSize: 12)),
									const SizedBox(height: 6),
									_FilledField(
										color: fieldColor,
										borderColor: borderClr,
										child: DropdownButtonHideUnderline(
											child: DropdownButton<String>(
												value: _selectedPosition,
												isExpanded: true,
												hint: Text('Select Position', style: TextStyle(color: hintColor)),
												style: TextStyle(color: textColor),
												dropdownColor: fieldColor,
												items: _positions.map((String position) {
													return DropdownMenuItem<String>(
														value: position,
														child: Text(position),
													);
												}).toList(),
												onChanged: (String? newValue) {
													setState(() {
														_selectedPosition = newValue;
													});
												},
												),
											),
										),
										const SizedBox(height: 16),
									Text('Type of Interview *', style: TextStyle(color: labelColor, fontSize: 12)),
									const SizedBox(height: 6),
									_FilledField(
										color: fieldColor,
										borderColor: borderClr,
										child: DropdownButtonHideUnderline(
											child: DropdownButton<String>(
												value: _selectedInterviewType,
												isExpanded: true,
												hint: Text('Select Interview Type', style: TextStyle(color: hintColor)),
												style: TextStyle(color: textColor),
												dropdownColor: fieldColor,
												items: _interviewTypes.map((String type) {
													return DropdownMenuItem<String>(
														value: type,
														child: Text(type),
													);
												}).toList(),
												onChanged: (String? newValue) {
													setState(() {
														_selectedInterviewType = newValue;
													});
												},
												),
											),
										),
										const SizedBox(height: 16),
								Text('Difficulty Level *', style: TextStyle(color: labelColor, fontSize: 12)),
										const SizedBox(height: 8),
										Wrap(
											spacing: 10,
											children: <Widget>[
												_DifficultyChip(
													label: 'Easy',
													selected: _difficulty == 'Easy',
													onSelected: () async {
													// When user selects Easy, ask for 5 or 10 questions
													final sel = await showDialog<int>(
														context: context,
														builder: (_) => AlertDialog(
															title: const Text('Select number of questions'),
															content: const Text('Choose how many easy questions you want'),
															actions: [
																TextButton(onPressed: () => Navigator.of(context).pop(3), child: const Text('3')),
																TextButton(onPressed: () => Navigator.of(context).pop(5), child: const Text('5')),
															],
														),
													);
													if (sel != null) {
														setState(() {
															_difficulty = 'Easy';
															_selectedCount = sel;
														});
													}
													},
													selectedColor: chipSelected,
													unselectedColor: chipUnselected,
													borderColor: chipBorder,
													textColor: textColor,
												),
												_DifficultyChip(
													label: 'Medium',
													selected: _difficulty == 'Medium',
													onSelected: () async {
													// For Medium, ask for 3 or 5
													final sel = await showDialog<int>(
														context: context,
														builder: (_) => AlertDialog(
															title: const Text('Select number of questions'),
															content: const Text('Choose how many medium questions you want'),
															actions: [
																TextButton(onPressed: () => Navigator.of(context).pop(3), child: const Text('3')),
																TextButton(onPressed: () => Navigator.of(context).pop(5), child: const Text('5')),
															],
														),
													);
													if (sel != null) {
														setState(() {
															_difficulty = 'Medium';
															_selectedCount = sel;
														});
													}
													},
													selectedColor: chipSelected,
													unselectedColor: chipUnselected,
													borderColor: chipBorder,
													textColor: textColor,
												),
												_DifficultyChip(
													label: 'Hard',
													selected: _difficulty == 'Hard',
													onSelected: () async {
													// Inform user that AI will decide the number (up to 15)
													final confirmed = await showDialog<bool>(
														context: context,
														builder: (_) => AlertDialog(
															title: const Text('Hard Difficulty'),
															content: const Text('AI will generate between 5-15 hard questions based on your level.'),
															actions: [
																TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
																TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('OK')),
															],
														),
													);
													if (confirmed == true) {
														setState(() {
															_difficulty = 'Hard';
															_selectedCount = null; // AI will decide
														});
													}
													},
													selectedColor: chipSelected,
													unselectedColor: chipUnselected,
													borderColor: chipBorder,
													textColor: textColor,
												),
											],
										),
										const SizedBox(height: 26),
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
												onPressed: () {
												// Validate all mandatory fields
												if (_selectedPosition == null) {
													ScaffoldMessenger.of(context).showSnackBar(
														const SnackBar(content: Text('Please select a position')),
													);
													return;
												}
												if (_selectedInterviewType == null) {
													ScaffoldMessenger.of(context).showSnackBar(
														const SnackBar(content: Text('Please select an interview type')),
													);
													return;
												}
												if (_difficulty == null) {
													ScaffoldMessenger.of(context).showSnackBar(
														const SnackBar(content: Text('Please select a difficulty level')),
													);
													return;
												}
												if (_difficulty != 'Hard' && _selectedCount == null) {
													ScaffoldMessenger.of(context).showSnackBar(
														const SnackBar(content: Text('Please select number of questions')),
													);
													return;
												}
												// Navigate to InterviewScreen and pass difficulty/count
												Navigator.of(context).push(MaterialPageRoute(
													builder: (_) => InterviewScreen(
														difficulty: _difficulty!,
															count: _selectedCount,
														),
													));
												},
												child: const Text('Start Interview'),
											),
										),
										const SizedBox(height: 12),
										SizedBox(
											width: double.infinity,
											child: OutlinedButton(
												style: OutlinedButton.styleFrom(
													side: BorderSide(color: borderClr),
													shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
													foregroundColor: textColor,
													padding: const EdgeInsets.symmetric(vertical: 14),
												),
												onPressed: () {
													Navigator.of(context).push(
														MaterialPageRoute(
															builder: (context) => const ResourcesScreen(),
														),
													);
												},
												child: const Text('View Resources'),
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
}

class _FilledField extends StatelessWidget {
	const _FilledField({required this.child, required this.color, required this.borderColor});

	final Widget child;
	final Color color;
	final Color borderColor;

	@override
	Widget build(BuildContext context) {
		return Container(
			padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
			decoration: BoxDecoration(
				color: color,
				borderRadius: BorderRadius.circular(10),
				border: Border.all(color: borderColor),
			),
			child: child,
		);
	}
}

class _DifficultyChip extends StatelessWidget {
	const _DifficultyChip({
		required this.label,
		required this.selected,
		required this.onSelected,
		required this.selectedColor,
		required this.unselectedColor,
		required this.borderColor,
		required this.textColor,
	});

	final String label;
	final bool selected;
	final VoidCallback onSelected;
	final Color selectedColor;
	final Color unselectedColor;
	final Color borderColor;
	final Color textColor;

	@override
	Widget build(BuildContext context) {
		return GestureDetector(
			onTap: onSelected,
			child: Container(
				padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
				decoration: BoxDecoration(
					color: selected ? selectedColor : unselectedColor,
					borderRadius: BorderRadius.circular(10),
					border: Border.all(color: borderColor),
					boxShadow: <BoxShadow>[
						if (selected) BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 10, offset: const Offset(0, 6)),
					],
				),
				child: Text(label, style: TextStyle(color: textColor)),
			),
		);
	}
}