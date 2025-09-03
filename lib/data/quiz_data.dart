// lib/data/quiz_data.dart

class QuizData {
  static List<Map<String, dynamic>> getQuestionsByLanguage(String language) {
    switch (language.toLowerCase()) {
      case 'flutter':
        return flutterQuestions;
      case 'kotlin':
        return kotlinQuestions;
      case 'python':
        return pythonQuestions;
      default:
        return generalQuestions;
    }
  }

  static List<Map<String, dynamic>> flutterQuestions = [
    {
      'question': 'What is Flutter?',
      'answers': ['A cross-platform UI toolkit', 'A programming language', 'A database', 'An operating system'],
      'correct': 0,
    },
    {
      'question': 'Which language is primarily used for Flutter development?',
      'answers': ['Dart', 'Java', 'Kotlin', 'Swift'],
      'correct': 0,
    },
    {
      'question': 'What is a Widget in Flutter?',
      'answers': ['A UI component', 'A database table', 'A network request', 'A file format'],
      'correct': 0,
    },
    {
      'question': 'Which widget is used for displaying text in Flutter?',
      'answers': ['Text', 'Label', 'TextView', 'TextWidget'],
      'correct': 0,
    },
    {
      'question': 'What does setState() do in Flutter?',
      'answers': ['Triggers UI rebuild', 'Saves data', 'Makes network call', 'Closes app'],
      'correct': 0,
    },
    {
      'question': 'Which widget is used for layout in Flutter?',
      'answers': ['Column', 'List', 'Array', 'Grid'],
      'correct': 0,
    },
    {
      'question': 'What is the main function in a Flutter app?',
      'answers': ['Entry point', 'UI builder', 'Data handler', 'Network manager'],
      'correct': 0,
    },
    {
      'question': 'Which widget makes a child widget clickable?',
      'answers': ['GestureDetector', 'Clickable', 'Button', 'Touch'],
      'correct': 0,
    },
    {
      'question': 'What is pubspec.yaml used for?',
      'answers': ['Package dependencies', 'UI layout', 'Database schema', 'Network config'],
      'correct': 0,
    },
    {
      'question': 'Which widget is used for navigation?',
      'answers': ['Navigator', 'Router', 'Link', 'Path'],
      'correct': 0,
    },
    {
      'question': 'What is hot reload in Flutter?',
      'answers': ['Quick code changes', 'App restart', 'Data refresh', 'Cache clear'],
      'correct': 0,
    },
    {
      'question': 'Which widget creates scrollable lists?',
      'answers': ['ListView', 'ScrollView', 'List', 'Array'],
      'correct': 0,
    },
    {
      'question': 'What is a StatefulWidget?',
      'answers': ['Widget with mutable state', 'Static widget', 'Database widget', 'Network widget'],
      'correct': 0,
    },
    {
      'question': 'Which widget is used for images?',
      'answers': ['Image', 'Picture', 'Photo', 'Graphic'],
      'correct': 0,
    },
    {
      'question': 'What is Scaffold in Flutter?',
      'answers': ['Basic app structure', 'Database tool', 'Network client', 'File manager'],
      'correct': 0,
    },
  ];

  static List<Map<String, dynamic>> kotlinQuestions = [
    {
      'question': 'Kotlin is developed by which company?',
      'answers': ['JetBrains', 'Google', 'Oracle', 'Microsoft'],
      'correct': 0,
    },
    {
      'question': 'Kotlin runs on which virtual machine?',
      'answers': ['JVM', 'CLR', 'ART', 'V8'],
      'correct': 0,
    },
    {
      'question': 'How do you declare a variable in Kotlin?',
      'answers': ['val or var', 'let or const', 'def or set', 'int or string'],
      'correct': 0,
    },
    {
      'question': 'What is the difference between val and var?',
      'answers': ['val is immutable, var is mutable', 'val is mutable, var is immutable', 'No difference', 'val is for strings only'],
      'correct': 0,
    },
    {
      'question': 'How do you define a function in Kotlin?',
      'answers': ['fun', 'function', 'def', 'method'],
      'correct': 0,
    },
    {
      'question': 'What is null safety in Kotlin?',
      'answers': ['Prevention of null pointer exceptions', 'Memory management', 'Thread safety', 'Type checking'],
      'correct': 0,
    },
    {
      'question': 'Which symbol is used for nullable types?',
      'answers': ['?', '!', '&', '*'],
      'correct': 0,
    },
    {
      'question': 'What is a data class in Kotlin?',
      'answers': ['Class for holding data', 'Database class', 'Network class', 'UI class'],
      'correct': 0,
    },
    {
      'question': 'How do you create a singleton in Kotlin?',
      'answers': ['object keyword', 'class keyword', 'singleton keyword', 'static keyword'],
      'correct': 0,
    },
    {
      'question': 'What is extension function?',
      'answers': ['Add functions to existing classes', 'Extend class inheritance', 'Create new classes', 'Override methods'],
      'correct': 0,
    },
    {
      'question': 'Which operator is used for safe call?',
      'answers': ['?.', '!!', '&&', '||'],
      'correct': 0,
    },
    {
      'question': 'What is companion object?',
      'answers': ['Static members in class', 'Object companion', 'Pair object', 'Helper object'],
      'correct': 0,
    },
    {
      'question': 'How do you handle exceptions in Kotlin?',
      'answers': ['try-catch', 'handle-error', 'catch-throw', 'error-handle'],
      'correct': 0,
    },
    {
      'question': 'What is when expression?',
      'answers': ['Switch statement equivalent', 'Time function', 'Condition checker', 'Loop statement'],
      'correct': 0,
    },
    {
      'question': 'Kotlin is 100% interoperable with?',
      'answers': ['Java', 'Python', 'C++', 'JavaScript'],
      'correct': 0,
    },
  ];

  static List<Map<String, dynamic>> pythonQuestions = [
    {
      'question': 'Python was created by whom?',
      'answers': ['Guido van Rossum', 'James Gosling', 'Dennis Ritchie', 'Bjarne Stroustrup'],
      'correct': 0,
    },
    {
      'question': 'Which of these is not a Python data type?',
      'answers': ['int', 'float', 'string', 'char'],
      'correct': 3,
    },
    {
      'question': 'How do you create a comment in Python?',
      'answers': ['#', '//', '/*', '--'],
      'correct': 0,
    },
    {
      'question': 'Which function is used to get input from user?',
      'answers': ['input()', 'get()', 'read()', 'scan()'],
      'correct': 0,
    },
    {
      'question': 'What is the correct way to create a list?',
      'answers': ['[]', '{}', '()', '<>'],
      'correct': 0,
    },
    {
      'question': 'Which keyword is used to define a function?',
      'answers': ['def', 'function', 'fun', 'define'],
      'correct': 0,
    },
    {
      'question': 'What does len() function do?',
      'answers': ['Returns length', 'Creates length', 'Deletes length', 'Changes length'],
      'correct': 0,
    },
    {
      'question': 'Which loop is used to iterate over sequences?',
      'answers': ['for', 'while', 'do-while', 'repeat'],
      'correct': 0,
    },
    {
      'question': 'What is the correct syntax for if statement?',
      'answers': ['if condition:', 'if (condition)', 'if condition then', 'if {condition}'],
      'correct': 0,
    },
    {
      'question': 'Which operator is used for exponentiation?',
      'answers': ['**', '^', 'pow', 'exp'],
      'correct': 0,
    },
    {
      'question': 'What is indentation used for in Python?',
      'answers': ['Code blocks', 'Comments', 'Variables', 'Functions'],
      'correct': 0,
    },
    {
      'question': 'Which method adds an item to the end of a list?',
      'answers': ['append()', 'add()', 'insert()', 'push()'],
      'correct': 0,
    },
    {
      'question': 'What is the output of print(type(5.0))?',
      'answers': ['<class \'int\'>', '<class \'float\'>', '<class \'number\'>', '<class \'decimal\'>'],
      'correct': 1,
    },
    {
      'question': 'Which keyword is used for exception handling?',
      'answers': ['try', 'catch', 'handle', 'error'],
      'correct': 0,
    },
    {
      'question': 'What is a dictionary in Python?',
      'answers': ['Key-value pairs', 'Ordered list', 'Set of values', 'Array of elements'],
      'correct': 0,
    },
  ];

  static List<Map<String, dynamic>> generalQuestions = [
    {
      'question': 'What is the capital of India?',
      'answers': ['New Delhi', 'Chennai', 'Mumbai', 'Kolkata'],
      'correct': 0,
    },
    {
      'question': 'Which planet is known as the Red Planet?',
      'answers': ['Mars', 'Earth', 'Venus', 'Jupiter'],
      'correct': 0,
    },
    {
      'question': 'Who wrote the play "Romeo and Juliet"?',
      'answers': ['William Shakespeare', 'Charles Dickens', 'Mark Twain', 'Jane Austen'],
      'correct': 0,
    },
    {
      'question': 'What is the largest mammal in the world?',
      'answers': ['Blue Whale', 'Elephant', 'Giraffe', 'Hippopotamus'],
      'correct': 0,
    },
    {
      'question': 'What is the chemical symbol for gold?',
      'answers': ['Au', 'Ag', 'Fe', 'Pb'],
      'correct': 0,
    },
    {
      'question': 'Which country is known as the Land of the Rising Sun?',
      'answers': ['Japan', 'China', 'Korea', 'Thailand'],
      'correct': 0,
    },
    {
      'question': 'What is the smallest prime number?',
      'answers': ['2', '1', '3', '0'],
      'correct': 0,
    },
    {
      'question': 'Which ocean is the largest?',
      'answers': ['Pacific Ocean', 'Atlantic Ocean', 'Indian Ocean', 'Arctic Ocean'],
      'correct': 0,
    },
    {
      'question': 'Who painted the Mona Lisa?',
      'answers': ['Leonardo da Vinci', 'Pablo Picasso', 'Vincent van Gogh', 'Michelangelo'],
      'correct': 0,
    },
    {
      'question': 'What is the hardest natural substance on Earth?',
      'answers': ['Diamond', 'Gold', 'Iron', 'Quartz'],
      'correct': 0,
    },
    {
      'question': 'Which gas makes up most of Earth\'s atmosphere?',
      'answers': ['Nitrogen', 'Oxygen', 'Carbon Dioxide', 'Hydrogen'],
      'correct': 0,
    },
    {
      'question': 'What is the capital of Australia?',
      'answers': ['Canberra', 'Sydney', 'Melbourne', 'Brisbane'],
      'correct': 0,
    },
    {
      'question': 'How many continents are there?',
      'answers': ['7', '6', '5', '8'],
      'correct': 0,
    },
    {
      'question': 'What is the speed of light?',
      'answers': ['299,792,458 m/s', '300,000,000 m/s', '150,000,000 m/s', '200,000,000 m/s'],
      'correct': 0,
    },
    {
      'question': 'Which element has the chemical symbol O?',
      'answers': ['Oxygen', 'Gold', 'Silver', 'Carbon'],
      'correct': 0,
    },
  ];
}