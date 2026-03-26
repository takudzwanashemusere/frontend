import 'package:flutter/material.dart';
import 'dart:math';
import '../main.dart';
import '../services/auth_service.dart';

class QuizQuestion {
  final String question;
  final List<String> options;
  final int correctIndex;
  final String explanation;

  const QuizQuestion({
    required this.question,
    required this.options,
    required this.correctIndex,
    required this.explanation,
  });
}

class QuizBank {
  static final Map<String, List<QuizQuestion>> _questions = {

    // ── ENGINEERING SCIENCE AND TECHNOLOGY ──
    'Software Engineering': [
      QuizQuestion(
        question: 'Which software development model is best suited for projects with well-defined requirements?',
        options: ['Agile', 'Waterfall', 'Scrum', 'Spiral'],
        correctIndex: 1,
        explanation: 'The Waterfall model works best when requirements are clear and unlikely to change throughout the project.',
      ),
      QuizQuestion(
        question: 'What does OOP stand for in programming?',
        options: ['Object Oriented Programming', 'Online Operational Process', 'Open Output Protocol', 'Ordered Object Pattern'],
        correctIndex: 0,
        explanation: 'OOP (Object Oriented Programming) organizes code around objects that combine data and behaviour.',
      ),
      QuizQuestion(
        question: 'Which of these is NOT a principle of SOLID design?',
        options: ['Single Responsibility', 'Open/Closed', 'Liskov Substitution', 'Dynamic Dependency'],
        correctIndex: 3,
        explanation: 'SOLID stands for: Single Responsibility, Open/Closed, Liskov Substitution, Interface Segregation, Dependency Inversion.',
      ),
      QuizQuestion(
        question: 'What is the purpose of version control systems like Git?',
        options: ['Run code faster', 'Track changes and collaborate', 'Compress files', 'Deploy applications'],
        correctIndex: 1,
        explanation: 'Git tracks changes in code over time, enabling collaboration and the ability to revert to previous versions.',
      ),
      QuizQuestion(
        question: 'What does REST stand for in web development?',
        options: ['Remote Execution State Transfer', 'Representational State Transfer', 'Resource Exchange Standard Technology', 'Remote Server Transfer'],
        correctIndex: 1,
        explanation: 'REST (Representational State Transfer) is an architectural style for designing networked APIs.',
      ),
    ],

    'Database Systems': [
      QuizQuestion(
        question: 'What SQL command is used to retrieve data from a table?',
        options: ['GET', 'FETCH', 'SELECT', 'PULL'],
        correctIndex: 2,
        explanation: 'SELECT is the SQL command used to query and retrieve data from database tables.',
      ),
      QuizQuestion(
        question: 'What does ACID stand for in database transactions?',
        options: ['Atomicity, Consistency, Isolation, Durability', 'Access, Control, Index, Data', 'Atomic, Complete, Integrated, Dynamic', 'None of the above'],
        correctIndex: 0,
        explanation: 'ACID properties ensure reliable database transactions: Atomicity, Consistency, Isolation, and Durability.',
      ),
      QuizQuestion(
        question: 'Which SQL clause is used to filter grouped results?',
        options: ['WHERE', 'FILTER', 'HAVING', 'GROUP BY'],
        correctIndex: 2,
        explanation: 'HAVING is used to filter results after GROUP BY, while WHERE filters before grouping.',
      ),
      QuizQuestion(
        question: 'What is a primary key in a relational database?',
        options: ['The most important column', 'A unique identifier for each record', 'A foreign table reference', 'An encrypted password'],
        correctIndex: 1,
        explanation: 'A primary key uniquely identifies each row in a table and cannot be NULL or duplicate.',
      ),
    ],

    'ICT & Networking': [
      QuizQuestion(
        question: 'What does IP stand for in networking?',
        options: ['Internet Provider', 'Internal Protocol', 'Internet Protocol', 'Interface Port'],
        correctIndex: 2,
        explanation: 'IP (Internet Protocol) is the principal communications protocol for relaying datagrams across networks.',
      ),
      QuizQuestion(
        question: 'Which layer of the OSI model handles routing?',
        options: ['Data Link Layer', 'Transport Layer', 'Network Layer', 'Session Layer'],
        correctIndex: 2,
        explanation: 'The Network Layer (Layer 3) is responsible for routing packets between different networks.',
      ),
      QuizQuestion(
        question: 'What does DNS stand for?',
        options: ['Data Network System', 'Domain Name System', 'Digital Network Service', 'Dynamic Node Setup'],
        correctIndex: 1,
        explanation: 'DNS (Domain Name System) translates human-readable domain names into IP addresses.',
      ),
    ],

    // ── ENTREPRENEURSHIP AND BUSINESS SCIENCES ──
    'Business Management': [
      QuizQuestion(
        question: 'What is a SWOT analysis used for in business?',
        options: ['Financial reporting', 'Strategic planning', 'Employee scheduling', 'Product pricing'],
        correctIndex: 1,
        explanation: 'SWOT (Strengths, Weaknesses, Opportunities, Threats) is a strategic planning tool for assessing a business.',
      ),
      QuizQuestion(
        question: 'Which management function involves setting goals and deciding how to achieve them?',
        options: ['Organizing', 'Leading', 'Planning', 'Controlling'],
        correctIndex: 2,
        explanation: 'Planning involves setting objectives and determining the best course of action to achieve them.',
      ),
      QuizQuestion(
        question: 'What is a mission statement?',
        options: ['A financial target', 'A company\'s purpose and reason for existing', 'A marketing campaign', 'An employee handbook'],
        correctIndex: 1,
        explanation: 'A mission statement defines the organization\'s purpose, values, and primary objectives.',
      ),
      QuizQuestion(
        question: 'What does B2B mean in business?',
        options: ['Back to Basics', 'Business to Business', 'Brand to Brand', 'Buy to Build'],
        correctIndex: 1,
        explanation: 'B2B (Business to Business) refers to transactions conducted between companies rather than between companies and consumers.',
      ),
    ],

    'Entrepreneurship': [
      QuizQuestion(
        question: 'What is a value proposition?',
        options: ['The price of a product', 'The reason customers choose your product over competitors', 'A business loan', 'A marketing budget'],
        correctIndex: 1,
        explanation: 'A value proposition clearly states how your product solves customer problems and why it\'s better than alternatives.',
      ),
      QuizQuestion(
        question: 'What is bootstrapping in entrepreneurship?',
        options: ['Starting a business with external investor funding', 'Building a startup using personal resources and revenue', 'Copying a competitor\'s business model', 'Franchising an existing business'],
        correctIndex: 1,
        explanation: 'Bootstrapping means funding your startup using personal savings and early revenue rather than external investors.',
      ),
      QuizQuestion(
        question: 'What is a minimum viable product (MVP)?',
        options: ['The most expensive version of a product', 'A product with just enough features to validate an idea', 'A rejected prototype', 'A government-approved product'],
        correctIndex: 1,
        explanation: 'An MVP is a product with just enough features to be used by early customers who can provide feedback for future development.',
      ),
    ],

    'Accounting & Finance': [
      QuizQuestion(
        question: 'What is the accounting equation?',
        options: ['Assets = Revenue - Expenses', 'Assets = Liabilities + Equity', 'Profit = Revenue + Costs', 'Cash = Assets - Debts'],
        correctIndex: 1,
        explanation: 'The fundamental accounting equation is: Assets = Liabilities + Owner\'s Equity.',
      ),
      QuizQuestion(
        question: 'What does depreciation mean in accounting?',
        options: ['Increase in asset value', 'Decrease in asset value over time', 'Loss of cash', 'Increase in liabilities'],
        correctIndex: 1,
        explanation: 'Depreciation is the systematic allocation of an asset\'s cost over its useful life.',
      ),
      QuizQuestion(
        question: 'What is a balance sheet?',
        options: ['A record of daily transactions', 'A statement showing assets, liabilities and equity at a point in time', 'A list of employees', 'A marketing budget'],
        correctIndex: 1,
        explanation: 'A balance sheet (statement of financial position) shows what a company owns, owes, and the owner\'s equity at a specific date.',
      ),
    ],

    // ── AGRICULTURE SCIENCES AND TECHNOLOGY ──
    'Crop Science': [
      QuizQuestion(
        question: 'What is crop rotation and why is it important?',
        options: ['Turning crops during harvest', 'Growing different crops in the same area in different seasons to maintain soil health', 'Rotating irrigation pipes', 'Moving crops to different farms'],
        correctIndex: 1,
        explanation: 'Crop rotation prevents soil depletion, reduces pests and diseases, and improves soil structure and fertility.',
      ),
      QuizQuestion(
        question: 'What is the main nutrient required for leaf and stem growth in plants?',
        options: ['Phosphorus (P)', 'Potassium (K)', 'Nitrogen (N)', 'Calcium (Ca)'],
        correctIndex: 2,
        explanation: 'Nitrogen is essential for vegetative growth — it\'s a key component of chlorophyll and amino acids.',
      ),
      QuizQuestion(
        question: 'What is the ideal soil pH range for most crops?',
        options: ['3.0 – 4.5', '5.5 – 7.0', '8.0 – 9.5', '10.0 – 12.0'],
        correctIndex: 1,
        explanation: 'Most crops grow best in slightly acidic to neutral soil with a pH of 5.5 to 7.0.',
      ),
      QuizQuestion(
        question: 'What is drip irrigation?',
        options: ['Flooding the field with water', 'Spraying water from above', 'Delivering water directly to plant roots through tubes', 'Natural rainfall collection'],
        correctIndex: 2,
        explanation: 'Drip irrigation delivers water directly to the root zone, improving water efficiency and reducing waste.',
      ),
    ],

    'Soil Science': [
      QuizQuestion(
        question: 'What are the three main components of soil texture?',
        options: ['Sand, Silt, Clay', 'Humus, Rocks, Water', 'Minerals, Air, Fungi', 'Carbon, Nitrogen, Oxygen'],
        correctIndex: 0,
        explanation: 'Soil texture is determined by the proportions of sand, silt, and clay particles.',
      ),
      QuizQuestion(
        question: 'What is organic matter in soil?',
        options: ['Chemical fertilizers', 'Decomposed plant and animal material', 'Plastic particles', 'Rock minerals'],
        correctIndex: 1,
        explanation: 'Organic matter is decomposed biological material that improves soil structure, water retention, and nutrient availability.',
      ),
      QuizQuestion(
        question: 'What is soil erosion?',
        options: ['Adding nutrients to soil', 'The removal of topsoil by water, wind, or human activity', 'Compacting soil for construction', 'Watering plants'],
        correctIndex: 1,
        explanation: 'Soil erosion is the wearing away of topsoil — the most fertile layer — by natural forces or farming practices.',
      ),
    ],

    'Animal Science': [
      QuizQuestion(
        question: 'What is the rumen in cattle?',
        options: ['A type of cattle breed', 'The first stomach compartment for fermenting feed', 'A cattle disease', 'A feed supplement'],
        correctIndex: 1,
        explanation: 'The rumen is the largest compartment of a cow\'s stomach where microbial fermentation of fibrous plant material occurs.',
      ),
      QuizQuestion(
        question: 'What is selective breeding in animal science?',
        options: ['Breeding animals at random', 'Choosing animals with desired traits to produce offspring', 'Preventing animals from breeding', 'Cloning animals'],
        correctIndex: 1,
        explanation: 'Selective breeding involves choosing parent animals with specific desired traits to improve the next generation.',
      ),
    ],

    // ── WILDLIFE AND ENVIRONMENTAL SCIENCE ──
    'Wildlife Management': [
      QuizQuestion(
        question: 'What is a wildlife corridor?',
        options: ['A zoo passage', 'A strip of habitat connecting fragmented areas', 'A hunting zone', 'A fence around a game reserve'],
        correctIndex: 1,
        explanation: 'Wildlife corridors connect fragmented habitats, allowing animals to move between areas for feeding, breeding, and migration.',
      ),
      QuizQuestion(
        question: 'What is the CAMPFIRE programme in Zimbabwe?',
        options: ['A fire prevention scheme', 'Communal Areas Management Programme for Indigenous Resources', 'A national park lighting system', 'A wildlife photography project'],
        correctIndex: 1,
        explanation: 'CAMPFIRE (Communal Areas Management Programme for Indigenous Resources) gives communities rights to manage and benefit from wildlife.',
      ),
      QuizQuestion(
        question: 'What does biodiversity refer to?',
        options: ['The number of plants in a forest', 'The variety of life forms in an ecosystem', 'The number of endangered species', 'The size of a game reserve'],
        correctIndex: 1,
        explanation: 'Biodiversity refers to the variety of life — including species, genetic, and ecosystem diversity — in a given area.',
      ),
    ],

    'Ecology & Conservation': [
      QuizQuestion(
        question: 'What is a food chain?',
        options: ['A restaurant franchise', 'A sequence showing how energy passes from one organism to another', 'A list of endangered animals', 'A farming method'],
        correctIndex: 1,
        explanation: 'A food chain shows the transfer of energy from producers (plants) through consumers (animals) in an ecosystem.',
      ),
      QuizQuestion(
        question: 'What is the greenhouse effect?',
        options: ['Growing plants in greenhouses', 'The trapping of heat by atmospheric gases', 'A type of solar panel', 'Reforestation'],
        correctIndex: 1,
        explanation: 'The greenhouse effect occurs when gases like CO₂ trap heat in the atmosphere, warming the Earth\'s surface.',
      ),
    ],

    // ── HEALTH SCIENCES AND TECHNOLOGY ──
    'Public Health': [
      QuizQuestion(
        question: 'What is epidemiology?',
        options: ['The study of skin diseases', 'The study of disease distribution and determinants in populations', 'A type of vaccine', 'Emergency medical care'],
        correctIndex: 1,
        explanation: 'Epidemiology studies how diseases spread in populations and what factors determine their frequency and distribution.',
      ),
      QuizQuestion(
        question: 'What is herd immunity?',
        options: ['All animals being vaccinated', 'Protection of a community when enough people are immune to a disease', 'Isolation of sick individuals', 'A type of antibiotic'],
        correctIndex: 1,
        explanation: 'Herd immunity occurs when a large proportion of a population becomes immune, reducing disease spread even to unvaccinated individuals.',
      ),
      QuizQuestion(
        question: 'What are the primary prevention strategies in public health?',
        options: ['Treating existing diseases', 'Actions taken before disease onset to reduce risk', 'Rehabilitation after illness', 'Emergency response'],
        correctIndex: 1,
        explanation: 'Primary prevention aims to prevent disease before it occurs through vaccinations, health education, and healthy environments.',
      ),
    ],

    'Nursing Science': [
      QuizQuestion(
        question: 'What is the normal range for adult resting heart rate?',
        options: ['20-40 bpm', '60-100 bpm', '110-150 bpm', '150-200 bpm'],
        correctIndex: 1,
        explanation: 'A normal adult resting heart rate is 60-100 beats per minute. Below 60 is bradycardia; above 100 is tachycardia.',
      ),
      QuizQuestion(
        question: 'What does SOAP stand for in patient documentation?',
        options: ['Subjective, Objective, Assessment, Plan', 'Symptoms, Operations, Analysis, Prescription', 'Standard Output and Patient care', 'None of the above'],
        correctIndex: 0,
        explanation: 'SOAP notes organize patient information into: Subjective (patient says), Objective (observed), Assessment (diagnosis), Plan (treatment).',
      ),
    ],

    // ── HOSPITALITY AND TOURISM ──
    'Hotel Management': [
      QuizQuestion(
        question: 'What does RevPAR stand for in hotel management?',
        options: ['Revenue Per Available Room', 'Rate Value Per Accommodation Rate', 'Revenue Performance Analysis Report', 'Room Value and Price Analysis Ratio'],
        correctIndex: 0,
        explanation: 'RevPAR (Revenue Per Available Room) is a key hotel performance metric: total room revenue ÷ total available rooms.',
      ),
      QuizQuestion(
        question: 'What is the front office department responsible for?',
        options: ['Cooking and food preparation', 'Guest check-in, check-out and room allocation', 'Housekeeping and laundry', 'Maintenance and repairs'],
        correctIndex: 1,
        explanation: 'The front office is the first point of contact for guests, handling reservations, check-in, check-out, and guest services.',
      ),
      QuizQuestion(
        question: 'What is the purpose of a hotel\'s yield management strategy?',
        options: ['Reducing staff costs', 'Maximizing revenue by adjusting prices based on demand', 'Improving food quality', 'Designing hotel rooms'],
        correctIndex: 1,
        explanation: 'Yield management optimizes pricing and availability to maximize revenue during high and low demand periods.',
      ),
    ],

    'Tourism Management': [
      QuizQuestion(
        question: 'What is ecotourism?',
        options: ['Tourism in electronic spaces', 'Responsible travel to natural areas that conserves the environment', 'Extreme sports tourism', 'City-based tourism'],
        correctIndex: 1,
        explanation: 'Ecotourism is responsible travel to natural areas that conserves the environment and improves the well-being of local people.',
      ),
      QuizQuestion(
        question: 'Zimbabwe is famous for which UNESCO World Heritage Sites?',
        options: ['The Pyramids and Sahara', 'Victoria Falls and Great Zimbabwe', 'Table Mountain and Kruger', 'Serengeti and Kilimanjaro'],
        correctIndex: 1,
        explanation: 'Zimbabwe\'s UNESCO World Heritage Sites include Victoria Falls (shared with Zambia) and the Great Zimbabwe National Monument.',
      ),
    ],

    // ── NATURAL SCIENCES AND MATHEMATICS ──
    'Calculus': [
      QuizQuestion(
        question: 'What is the derivative of f(x) = x³?',
        options: ['3x', '3x²', 'x²', '2x³'],
        correctIndex: 1,
        explanation: 'Using the power rule: d/dx(xⁿ) = nxⁿ⁻¹, so d/dx(x³) = 3x².',
      ),
      QuizQuestion(
        question: 'What is ∫2x dx?',
        options: ['x', 'x² + C', '2x² + C', '2 + C'],
        correctIndex: 1,
        explanation: '∫2x dx = x² + C using the reverse power rule.',
      ),
      QuizQuestion(
        question: 'What does a definite integral represent geometrically?',
        options: ['The slope of a curve', 'The area under a curve between two points', 'The maximum point of a function', 'The x-intercept'],
        correctIndex: 1,
        explanation: 'A definite integral ∫ₐᵇ f(x)dx represents the net area between the curve and x-axis from x=a to x=b.',
      ),
    ],

    'Statistics & Probability': [
      QuizQuestion(
        question: 'What is the median of the dataset: 3, 7, 2, 9, 5?',
        options: ['5', '7', '3', '5.2'],
        correctIndex: 0,
        explanation: 'Sorted: 2, 3, 5, 7, 9. The median (middle value) is 5.',
      ),
      QuizQuestion(
        question: 'What does a p-value of 0.03 indicate in hypothesis testing?',
        options: ['The hypothesis is definitely true', 'There is 3% probability the result occurred by chance', 'The sample is too small', 'The test failed'],
        correctIndex: 1,
        explanation: 'A p-value of 0.03 means there is a 3% probability of observing the result by chance, typically considered statistically significant.',
      ),
      QuizQuestion(
        question: 'What is standard deviation a measure of?',
        options: ['The average of a dataset', 'The spread or variability of a dataset', 'The highest value', 'The total sum'],
        correctIndex: 1,
        explanation: 'Standard deviation measures how spread out the values in a dataset are from the mean.',
      ),
    ],

    // ── ART AND DESIGN ──
    'Graphic Design': [
      QuizQuestion(
        question: 'What does CMYK stand for in printing?',
        options: ['Cyan, Magenta, Yellow, Key (Black)', 'Color, Mixing, Yellow, Kodak', 'Cyan, Mint, Yellow, Khaki', 'Complete Merge Yellow Key'],
        correctIndex: 0,
        explanation: 'CMYK is the colour model used in printing: Cyan, Magenta, Yellow, and Key (Black).',
      ),
      QuizQuestion(
        question: 'What is the golden ratio and why is it important in design?',
        options: ['A colour code', 'A mathematical proportion (~1.618) that creates visually pleasing compositions', 'A font size', 'A printing resolution'],
        correctIndex: 1,
        explanation: 'The golden ratio (≈1.618) appears in nature and art, and designers use it to create balanced, aesthetically pleasing layouts.',
      ),
      QuizQuestion(
        question: 'What file format is best for logos that need to scale to any size?',
        options: ['JPEG', 'PNG', 'SVG', 'BMP'],
        correctIndex: 2,
        explanation: 'SVG (Scalable Vector Graphics) uses mathematical paths instead of pixels, so it scales to any size without losing quality.',
      ),
    ],

    // FALLBACK
    'General': [
      QuizQuestion(
        question: 'What does CUT stand for?',
        options: ['Central University of Technology', 'Chinhoyi University of Technology', 'College University of Training', 'Creative University of Technology'],
        correctIndex: 1,
        explanation: 'CUT stands for Chinhoyi University of Technology, located in Chinhoyi, Zimbabwe.',
      ),
      QuizQuestion(
        question: 'What is the capital city of Zimbabwe?',
        options: ['Bulawayo', 'Mutare', 'Harare', 'Gweru'],
        correctIndex: 2,
        explanation: 'Harare is the capital and largest city of Zimbabwe.',
      ),
      QuizQuestion(
        question: 'What is peer learning?',
        options: ['Learning from textbooks only', 'Students learning from and with each other', 'Learning online only', 'Teacher-led instruction'],
        correctIndex: 1,
        explanation: 'Peer learning involves students sharing knowledge, explaining concepts, and learning collaboratively from each other.',
      ),
    ],
  };

  // Department → allowed modules map
  static const Map<String, List<String>> _departmentModules = {
    'School of Natural Sciences and Mathematics': [
      'Calculus', 'Linear Algebra', 'Statistics & Probability',
      'Discrete Mathematics', 'Organic Chemistry', 'Analytical Chemistry',
      'Classical Physics', 'Quantum Mechanics',
    ],
    'School of Engineering Science and Technology': [
      'Software Engineering', 'Computer Science', 'ICT & Networking',
      'Electronics Engineering', 'Civil Engineering', 'Mechanical Engineering',
      'Database Systems', 'Artificial Intelligence',
    ],
    'School of Entrepreneurship and Business Sciences': [
      'Business Management', 'Accounting & Finance', 'Economics',
      'Marketing Management', 'Human Resource Management',
      'Strategic Management', 'Entrepreneurship', 'Supply Chain Management',
    ],
    'School of Agriculture Sciences and Technology': [
      'Crop Science', 'Animal Science', 'Agronomy', 'Agricultural Economics',
      'Soil Science', 'Horticulture', 'Agricultural Engineering',
      'Post-Harvest Technology',
    ],
    'School of Wildlife and Environmental Science': [
      'Wildlife Management', 'Ecology & Conservation', 'Environmental Science',
      'Tourism & Wildlife', 'Forest Management', 'Environmental Policy',
      'Animal Behaviour', 'GIS & Remote Sensing',
    ],
    'School of Health Sciences and Technology': [
      'Nursing Science', 'Public Health', 'Biomedical Science', 'Pharmacy',
      'Environmental Health', 'Medical Laboratory', 'Nutrition & Dietetics',
      'Health Informatics',
    ],
    'School of Hospitality and Tourism': [
      'Hotel Management', 'Tourism Management', 'Food & Beverage Management',
      'Events Management', 'Travel & Tourism', 'Hospitality Operations',
      'Culinary Arts', 'Resort Management',
    ],
    'School of Art and Design': [
      'Graphic Design', 'Visual Arts', 'Digital Media', 'Fine Arts',
      'Interior Design', 'Fashion Design', 'Photography', 'Animation & Film',
    ],
  };

  static bool isModuleAllowedForDepartment(String subject, String department) {
    final modules = _departmentModules[department];
    if (modules == null) return true;
    return modules.any(
      (m) =>
          m.toLowerCase() == subject.toLowerCase() ||
          m.toLowerCase().contains(subject.toLowerCase()) ||
          subject.toLowerCase().contains(m.toLowerCase()),
    );
  }

  static List<QuizQuestion> getRandomQuestions(String subject,
      {int count = 3}) {
    // Try exact match first, then try partial match
    String? key = _questions.containsKey(subject) ? subject : null;
    key ??= _questions.keys.firstWhere(
        (k) => k.toLowerCase().contains(subject.toLowerCase()) ||
            subject.toLowerCase().contains(k.toLowerCase()),
        orElse: () => 'General',
      );
    final list = List<QuizQuestion>.from(_questions[key]!);
    list.shuffle(Random());
    return list.take(count.clamp(1, list.length)).toList();
  }
}

// ─────────────────────────────────────────
// QUIZ POPUP WIDGET
// ─────────────────────────────────────────

class QuizPopup extends StatefulWidget {
  final String subject;
  final String videoTitle;

  const QuizPopup({
    super.key,
    required this.subject,
    required this.videoTitle,
  });

  @override
  State<QuizPopup> createState() => _QuizPopupState();
}

class _QuizPopupState extends State<QuizPopup>
    with SingleTickerProviderStateMixin {
  late List<QuizQuestion> _questions;
  int _currentIndex = 0;
  int? _selectedAnswer;
  bool _answered = false;
  int _score = 0;
  bool _finished = false;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _questions = QuizBank.getRandomQuestions(widget.subject, count: 3);
    _animController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _selectAnswer(int index) {
    if (_answered) return;
    setState(() {
      _selectedAnswer = index;
      _answered = true;
      if (index == _questions[_currentIndex].correctIndex) _score++;
    });
  }

  void _nextQuestion() {
    if (_currentIndex < _questions.length - 1) {
      setState(() {
        _currentIndex++;
        _selectedAnswer = null;
        _answered = false;
      });
      _animController.reset();
      _animController.forward();
    } else {
      setState(() => _finished = true);
    }
  }

  Color _optionColor(int i) {
    if (!_answered) return AppColors.surface;
    if (i == _questions[_currentIndex].correctIndex) {
      return AppColors.success.withValues(alpha: 0.2);
    }
    if (i == _selectedAnswer) return Colors.redAccent.withValues(alpha: 0.2);
    return AppColors.surface;
  }

  Color _optionBorder(int i) {
    if (!_answered) return Colors.white.withValues(alpha: 0.08);
    if (i == _questions[_currentIndex].correctIndex) {
      return AppColors.success;
    }
    if (i == _selectedAnswer) return Colors.redAccent;
    return Colors.white.withValues(alpha: 0.08);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Container(
            margin: EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(children: [
                        Icon(Icons.quiz_rounded,
                            color: AppColors.accent, size: 14),
                        SizedBox(width: 4),
                        Text(widget.subject,
                            style: TextStyle(
                                color: AppColors.accent,
                                fontSize: 12,
                                fontWeight: FontWeight.w600)),
                      ]),
                    ),
                    const SizedBox(height: 4),
                    const Text('Quick Quiz',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w700)),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded,
                      color: Colors.white38, size: 22),
                ),
              ],
            ),
          ),
          Expanded(
            child: _finished ? _buildResults() : _buildQuestion(),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestion() {
    final q = _questions[_currentIndex];
    return FadeTransition(
      opacity: _fadeAnim,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Question ${_currentIndex + 1} of ${_questions.length}',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.45),
                        fontSize: 13)),
                Spacer(),
                Text('Score: $_score',
                    style: TextStyle(
                        color: AppColors.accentLight,
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (_currentIndex + 1) / _questions.length,
                backgroundColor: Colors.white10,
                valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.accent),
                minHeight: 4,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: Colors.white.withValues(alpha: 0.06)),
              ),
              child: Text(q.question,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      height: 1.5)),
            ),
            const SizedBox(height: 16),
            ...q.options.asMap().entries.map((e) {
              final i = e.key;
              final opt = e.value;
              return GestureDetector(
                onTap: () => _selectAnswer(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: _optionColor(i),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _optionBorder(i)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Center(
                          child: Text(['A', 'B', 'C', 'D'][i],
                              style: const TextStyle(
                                  color: Colors.white60,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(opt,
                            style: TextStyle(
                                color: _answered
                                    ? (i == q.correctIndex
                                        ? AppColors.success
                                        : i == _selectedAnswer
                                            ? Colors.redAccent
                                            : Colors.white60)
                                    : Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w500)),
                      ),
                      if (_answered)
                        Icon(
                          i == q.correctIndex
                              ? Icons.check_circle_rounded
                              : i == _selectedAnswer
                                  ? Icons.cancel_rounded
                                  : null,
                          color: i == q.correctIndex
                              ? AppColors.success
                              : Colors.redAccent,
                          size: 18,
                        ),
                    ],
                  ),
                ),
              );
            }),
            if (_answered) ...[
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: AppColors.accent.withValues(alpha: 0.2)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.lightbulb_outline_rounded,
                        color: AppColors.accentLight, size: 16),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(q.explanation,
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.65),
                              fontSize: 12,
                              height: 1.4)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _nextQuestion,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(
                    _currentIndex < _questions.length - 1
                        ? 'Next Question →'
                        : 'See Results',
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResults() {
    final pct = (_score / _questions.length * 100).round();
    final emoji = pct == 100 ? '🏆' : pct >= 66 ? '🎉' : pct >= 33 ? '📚' : '💪';
    final msg = pct == 100
        ? 'Perfect score! Outstanding!'
        : pct >= 66
            ? 'Great job! Keep it up!'
            : pct >= 33
                ? 'Good effort! Review and retry!'
                : 'Keep studying! You got this!';

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          Text(msg,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700),
              textAlign: TextAlign.center),
          const SizedBox(height: 24),
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.accent.withValues(alpha: 0.15),
              border: Border.all(color: AppColors.accent, width: 3),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('$_score/${_questions.length}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w800)),
                  Text('$pct%',
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 13)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _questions = QuizBank.getRandomQuestions(widget.subject,
                      count: 3);
                  _currentIndex = 0;
                  _selectedAnswer = null;
                  _answered = false;
                  _score = 0;
                  _finished = false;
                });
                _animController.reset();
                _animController.forward();
              },
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try Again',
                  style:
                      TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white60,
                side: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('Back to Video',
                  style:
                      TextStyle(fontWeight: FontWeight.w500, fontSize: 15)),
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> showQuiz(
    BuildContext context, String subject, String videoTitle) async {
  final dept = await AuthService.getDepartment();

  if (!context.mounted) return;

  if (dept != null &&
      dept.isNotEmpty &&
      !QuizBank.isModuleAllowedForDepartment(subject, dept)) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _QuizBlockedSheet(subject: subject, department: dept),
    );
    return;
  }

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => QuizPopup(subject: subject, videoTitle: videoTitle),
  );
}

class _QuizBlockedSheet extends StatelessWidget {
  final String subject;
  final String department;

  const _QuizBlockedSheet({
    required this.subject,
    required this.department,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.lock_outline_rounded,
                color: AppColors.error, size: 30),
          ),
          const SizedBox(height: 16),
          const Text(
            'Quiz Not Available',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$subject is not part of your department\'s curriculum.\nYou can only take quizzes for your enrolled modules.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.55),
              fontSize: 13,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            department,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.accent,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('Got it',
                  style:
                      TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
            ),
          ),
        ],
      ),
    );
  }
}