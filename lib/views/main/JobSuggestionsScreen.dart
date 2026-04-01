import 'package:flutter/material.dart';
import '../widgets/AppScaffold.dart';

class JobSuggestionsScreen extends StatefulWidget {
	const JobSuggestionsScreen({super.key});

	@override
	State<JobSuggestionsScreen> createState() => _JobSuggestionsScreenState();
}

class _JobSuggestionsScreenState extends State<JobSuggestionsScreen> {
	String _selectedFilter = 'All';
	final List<String> _filters = ['All', 'Remote', 'On-site', 'Entry-level', 'Mid-level', 'Senior'];
	final List<String> _savedJobs = [];

	// Sample job data - replace with your API data
	final List<JobSuggestion> _jobSuggestions = [
		JobSuggestion(
			title: 'Data Analyst',
			company: 'TechCorp Solutions',
			location: 'Remote',
			matchScore: 95,
			salary: '\$60,000 - \$80,000',
			type: 'Remote',
			level: 'Entry-level',
			aiExplanation: 'You performed exceptionally well in analytical reasoning and data interpretation during your interview. Your logical thinking and attention to detail make you an ideal candidate for this Data Analyst role.',
			requirements: ['Python', 'SQL', 'Data Visualization', 'Statistics'],
			isBookmarked: false,
		),
		JobSuggestion(
			title: 'Software Engineer',
			company: 'Innovation Labs',
			location: 'San Francisco, CA',
			matchScore: 88,
			salary: '\$90,000 - \$120,000',
			type: 'On-site',
			level: 'Mid-level',
			aiExplanation: 'Your technical problem-solving skills and clear communication during the coding interview demonstrate strong potential for this Full Stack Developer position.',
			requirements: ['React', 'Node.js', 'MongoDB', 'Git'],
			isBookmarked: false,
		),
		JobSuggestion(
			title: 'UX Designer',
			company: 'Creative Studio',
			location: 'New York, NY',
			matchScore: 82,
			salary: '\$65,000 - \$85,000',
			type: 'On-site',
			level: 'Entry-level',
			aiExplanation: 'Your creativity and user-focused thinking, combined with strong presentation skills, align perfectly with this UX Designer role.',
			requirements: ['Figma', 'User Research', 'Wireframing', 'Prototyping'],
			isBookmarked: false,
		),
		JobSuggestion(
			title: 'Product Manager',
			company: 'StartupX',
			location: 'Remote',
			matchScore: 78,
			salary: '\$80,000 - \$110,000',
			type: 'Remote',
			level: 'Mid-level',
			aiExplanation: 'Your leadership qualities and strategic thinking showcased during the behavioral interview make you a strong candidate for this Product Manager position.',
			requirements: ['Product Strategy', 'Agile', 'Analytics', 'Communication'],
			isBookmarked: false,
		),
		JobSuggestion(
			title: 'Marketing Specialist',
			company: 'Growth Agency',
			location: 'Austin, TX',
			matchScore: 75,
			salary: '\$50,000 - \$70,000',
			type: 'On-site',
			level: 'Entry-level',
			aiExplanation: 'Your excellent communication skills and creative problem-solving approach during the interview indicate strong potential in digital marketing.',
			requirements: ['Digital Marketing', 'SEO', 'Content Creation', 'Analytics'],
			isBookmarked: false,
		),
	];

	List<JobSuggestion> get _filteredJobs {
		if (_selectedFilter == 'All') return _jobSuggestions;
		return _jobSuggestions.where((job) => 
			job.type == _selectedFilter || job.level == _selectedFilter
		).toList();
	}

	void _toggleBookmark(int index) {
		setState(() {
			_jobSuggestions[index].isBookmarked = !_jobSuggestions[index].isBookmarked;
			if (_jobSuggestions[index].isBookmarked) {
				_savedJobs.add(_jobSuggestions[index].title);
			} else {
				_savedJobs.remove(_jobSuggestions[index].title);
			}
		});
	}

	void _showJobDetails(JobSuggestion job) {
		final bool isDark = Theme.of(context).brightness == Brightness.dark;
		final Color dialogBg = isDark ? const Color(0xFF0B0F4E) : Colors.white;
		final Color textColor = isDark ? Colors.white : const Color(0xFF0A0F2E);
		final Color secondaryTextColor = isDark ? Colors.white70 : const Color(0xFF27308A);

		showModalBottomSheet<void>(
			context: context,
			backgroundColor: dialogBg,
			shape: const RoundedRectangleBorder(
				borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
			),
			builder: (BuildContext context) {
				return Padding(
					padding: const EdgeInsets.all(20),
					child: Column(
						mainAxisSize: MainAxisSize.min,
						crossAxisAlignment: CrossAxisAlignment.start,
						children: <Widget>[
							Row(
								children: <Widget>[
									Expanded(
										child: Text(job.title, style: TextStyle(color: textColor, fontSize: 20, fontWeight: FontWeight.w700)),
									),
									IconButton(
										onPressed: () => Navigator.pop(context),
										icon: Icon(Icons.close, color: textColor),
									),
								],
							),
							Text('${job.company} • ${job.location}', style: TextStyle(color: secondaryTextColor, fontSize: 14)),
							const SizedBox(height: 16),
							Container(
								padding: const EdgeInsets.all(12),
								decoration: BoxDecoration(
									color: isDark ? const Color(0xFF131964) : const Color(0xFFE8EBF8),
									borderRadius: BorderRadius.circular(12),
								),
								child: Column(
									crossAxisAlignment: CrossAxisAlignment.start,
									children: <Widget>[
										Text('AI Match Explanation', style: TextStyle(color: textColor, fontWeight: FontWeight.w600)),
										const SizedBox(height: 8),
										Text(job.aiExplanation, style: TextStyle(color: secondaryTextColor, fontSize: 12)),
									],
								),
							),
							const SizedBox(height: 16),
							Text('Requirements:', style: TextStyle(color: textColor, fontWeight: FontWeight.w600)),
							const SizedBox(height: 8),
							Wrap(
								spacing: 8,
								runSpacing: 8,
								children: job.requirements.map((req) => Container(
									padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
									decoration: BoxDecoration(
										color: isDark ? const Color(0xFF27308A) : const Color(0xFFD6DBFF),
										borderRadius: BorderRadius.circular(12),
									),
									child: Text(req, style: TextStyle(color: textColor, fontSize: 10)),
								)).toList(),
							),
							const SizedBox(height: 20),
							Row(
								children: <Widget>[
									Expanded(
										child: OutlinedButton(
											style: OutlinedButton.styleFrom(
												side: BorderSide(color: isDark ? const Color(0xFF27308A) : const Color(0xFFD6DBFF)),
												shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
												foregroundColor: textColor,
												padding: const EdgeInsets.symmetric(vertical: 12),
											),
											onPressed: () {
												Navigator.pop(context);
												ScaffoldMessenger.of(context).showSnackBar(
													SnackBar(content: Text('Saved ${job.title}')),
												);
											},
											child: const Text('Save Job'),
										),
									),
									const SizedBox(width: 12),
									Expanded(
										child: ElevatedButton(
											style: ElevatedButton.styleFrom(
												backgroundColor: isDark ? Colors.white : const Color(0xFF00002E),
												foregroundColor: isDark ? const Color(0xFF00002E) : Colors.white,
												shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
												padding: const EdgeInsets.symmetric(vertical: 12),
												elevation: 0,
											),
											onPressed: () {
												Navigator.pop(context);
												ScaffoldMessenger.of(context).showSnackBar(
													SnackBar(content: Text('Applied for ${job.title}')),
												);
											},
											child: const Text('Apply Now'),
										),
									),
								],
							),
						],
					),
				);
			},
		);
	}

	@override
	Widget build(BuildContext context) {
		final bool isDark = Theme.of(context).brightness == Brightness.dark;
		final Color backgroundColor = isDark ? const Color(0xFF00002E) : Colors.white;
		final Color textColor = isDark ? Colors.white : const Color(0xFF0A0F2E);
		final Color secondaryTextColor = isDark ? Colors.white70 : const Color(0xFF27308A);

		return AppScaffold(
			appBarTitle: 'Job Suggestions',
			backgroundColor: backgroundColor,
			body: Padding(
				padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
				child: Column(
					crossAxisAlignment: CrossAxisAlignment.start,
					children: <Widget>[
						// Header
						Text('Based on your interview performance', 
								 style: TextStyle(color: secondaryTextColor, fontSize: 12)),
						const SizedBox(height: 16),

						// Filters
						SizedBox(
							height: 40,
							child: ListView.builder(
								scrollDirection: Axis.horizontal,
								itemCount: _filters.length,
								itemBuilder: (context, index) {
									final filter = _filters[index];
									final isSelected = filter == _selectedFilter;
									return Padding(
										padding: const EdgeInsets.only(right: 8),
										child: FilterChip(
											label: Text(filter),
											selected: isSelected,
											onSelected: (bool selected) {
												setState(() {
													_selectedFilter = filter;
												});
											},
											backgroundColor: isDark ? const Color(0xFF0B0F4E) : const Color(0xFFF5F6FA),
											selectedColor: isDark ? const Color(0xFF131964) : const Color(0xFFE8EBF8),
											labelStyle: TextStyle(
												color: textColor,
												fontSize: 12,
											),
											side: BorderSide(
												color: isDark ? const Color(0xFF27308A) : const Color(0xFFD6DBFF),
											),
										),
									);
								},
							),
						),
						const SizedBox(height: 20),

						// Job List
						Expanded(
							child: ListView.builder(
								itemCount: _filteredJobs.length,
								itemBuilder: (context, index) {
									final job = _filteredJobs[index];
									return JobCard(
										job: job,
										onTap: () => _showJobDetails(job),
										onBookmarkTap: () => _toggleBookmark(_jobSuggestions.indexOf(job)),
									);
								},
							),
						),
					],
				),
			),
		);
	}
}

class JobCard extends StatelessWidget {
	const JobCard({
		super.key,
		required this.job,
		required this.onTap,
		required this.onBookmarkTap,
	});

	final JobSuggestion job;
	final VoidCallback onTap;
	final VoidCallback onBookmarkTap;

	@override
	Widget build(BuildContext context) {
		final bool isDark = Theme.of(context).brightness == Brightness.dark;
		final Color cardColor = isDark ? const Color(0xFF0B0F4E) : const Color(0xFFF5F6FA);
		final Color borderColor = isDark ? const Color(0xFF27308A) : const Color(0xFFD6DBFF);
		final Color textColor = isDark ? Colors.white : const Color(0xFF0A0F2E);
		final Color secondaryTextColor = isDark ? Colors.white70 : const Color(0xFF27308A);
		final Color matchScoreColor = job.matchScore >= 90 ? Colors.green : 
																 job.matchScore >= 80 ? Colors.orange : Colors.blue;

		return Container(
			margin: const EdgeInsets.only(bottom: 16),
			decoration: BoxDecoration(
				color: cardColor,
				borderRadius: BorderRadius.circular(16),
				border: Border.all(color: borderColor),
			),
			child: InkWell(
				onTap: onTap,
				borderRadius: BorderRadius.circular(16),
				child: Padding(
					padding: const EdgeInsets.all(16),
					child: Column(
						crossAxisAlignment: CrossAxisAlignment.start,
						children: <Widget>[
							// Header Row
							Row(
								children: <Widget>[
									Expanded(
										child: Column(
											crossAxisAlignment: CrossAxisAlignment.start,
											children: <Widget>[
												Text(job.title, style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.w700)),
												const SizedBox(height: 4),
												Text('${job.company} • ${job.location}', 
														 style: TextStyle(color: secondaryTextColor, fontSize: 12)),
											],
										),
									),
									IconButton(
										onPressed: onBookmarkTap,
										icon: Icon(
											job.isBookmarked ? Icons.bookmark : Icons.bookmark_border,
											color: job.isBookmarked ? Colors.amber : secondaryTextColor,
										),
									),
								],
							),
							const SizedBox(height: 12),

							// Match Score
							Row(
								children: <Widget>[
									Container(
										padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
										decoration: BoxDecoration(
											color: matchScoreColor.withOpacity(0.1),
											borderRadius: BorderRadius.circular(12),
											border: Border.all(color: matchScoreColor),
										),
										child: Row(
											mainAxisSize: MainAxisSize.min,
											children: <Widget>[
												Icon(Icons.verified, color: matchScoreColor, size: 12),
												const SizedBox(width: 4),
												Text('${job.matchScore}% Match', 
														 style: TextStyle(color: matchScoreColor, fontSize: 10, fontWeight: FontWeight.w600)),
											],
										),
									),
									const Spacer(),
									Text(job.salary, style: TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.w600)),
								],
							),
							const SizedBox(height: 12),

							// AI Explanation
							Container(
								padding: const EdgeInsets.all(12),
								decoration: BoxDecoration(
									color: isDark ? const Color(0xFF131964) : const Color(0xFFE8EBF8),
									borderRadius: BorderRadius.circular(12),
								),
								child: Column(
									crossAxisAlignment: CrossAxisAlignment.start,
									children: <Widget>[
										Row(
											children: <Widget>[
												Icon(Icons.psychology, color: secondaryTextColor, size: 14),
												const SizedBox(width: 4),
												Text('AI Match Explanation', 
														 style: TextStyle(color: textColor, fontSize: 10, fontWeight: FontWeight.w600)),
											],
										),
										const SizedBox(height: 6),
										Text(job.aiExplanation, 
												 style: TextStyle(color: secondaryTextColor, fontSize: 11, height: 1.3)),
									],
								),
							),
							const SizedBox(height: 12),

							// Tags
							Row(
								children: <Widget>[
									Container(
										padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
										decoration: BoxDecoration(
											color: isDark ? const Color(0xFF27308A) : const Color(0xFFD6DBFF),
											borderRadius: BorderRadius.circular(8),
										),
										child: Text(job.type, style: TextStyle(color: textColor, fontSize: 10)),
									),
									const SizedBox(width: 8),
									Container(
										padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
										decoration: BoxDecoration(
											color: isDark ? const Color(0xFF27308A) : const Color(0xFFD6DBFF),
											borderRadius: BorderRadius.circular(8),
										),
										child: Text(job.level, style: TextStyle(color: textColor, fontSize: 10)),
									),
									const Spacer(),
									Icon(Icons.arrow_forward_ios, color: secondaryTextColor, size: 12),
								],
							),
						],
					),
				),
			),
		);
	}
}

class JobSuggestion {
	final String title;
	final String company;
	final String location;
	final int matchScore;
	final String salary;
	final String type;
	final String level;
	final String aiExplanation;
	final List<String> requirements;
	bool isBookmarked;

	JobSuggestion({
		required this.title,
		required this.company,
		required this.location,
		required this.matchScore,
		required this.salary,
		required this.type,
		required this.level,
		required this.aiExplanation,
		required this.requirements,
		this.isBookmarked = false,
	});
}