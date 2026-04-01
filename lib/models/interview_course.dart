class InterviewCourse {
  final String courseTitle;
  final String courseDescription;
  final String courseLink;
  final String imageUrl;

  InterviewCourse({
    required this.courseTitle,
    required this.courseDescription,
    required this.courseLink,
    required this.imageUrl,
  });
}

// Udemy course data
final List<InterviewCourse> interviewCourses = [
  InterviewCourse(
    courseTitle: 'Job Interview English',
    courseDescription: 'Master English communication skills for successful job interviews.',
    courseLink: 'https://www.udemy.com/course/job-interview-english/',
    imageUrl: 'https://img.freepik.com/free-vector/web-programming-concept_3446-448.jpg?w=740&t=st=1700000000~exp=1700000600~hmac=sample',
  ),
  InterviewCourse(
    courseTitle: 'Ten Steps for a Successful Interview',
    courseDescription: 'Complete guide to ace any interview with proven strategies.',
    courseLink: 'https://www.udemy.com/course/10-steps-for-a-successful-interview-get-the-job/',
    imageUrl: 'https://img.freepik.com/free-vector/brainstorming-illustration_52683-60158.jpg?w=740&t=st=1700000000~exp=1700000600~hmac=sample',
  ),
  InterviewCourse(
    courseTitle: 'Software Engineer Interview Masterclass',
    courseDescription: 'Comprehensive masterclass for software engineering interviews.',
    courseLink: 'https://www.udemy.com/course/software-engineer-interview-masterclass-5-courses-in-1/',
    imageUrl: 'https://img.freepik.com/free-vector/web-programming-concept_3446-448.jpg?w=740&t=st=1700000000~exp=1700000600~hmac=sample',
  ),
  InterviewCourse(
    courseTitle: 'Software Engineer Interview Unleashed',
    courseDescription: 'Advanced techniques for software engineering interview success.',
    courseLink: 'https://www.udemy.com/course/software-engineer-interview-unleashed/',
    imageUrl: 'https://img.freepik.com/free-vector/brainstorming-illustration_52683-60158.jpg?w=740&t=st=1700000000~exp=1700000600~hmac=sample',
  ),
];
