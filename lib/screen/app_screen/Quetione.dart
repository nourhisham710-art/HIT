import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class QuestionScreen extends StatefulWidget {
  const QuestionScreen({super.key});

  @override
  State<QuestionScreen> createState() => _QuestionScreenState();
}

class _QuestionScreenState extends State<QuestionScreen> {
  final TextEditingController _answerController = TextEditingController();
  final Random _random = Random();

  int _decimalNumber = 0;
  String _conversionBase = '';
  String _correctAnswer = '';
  String _feedback = '';
  int _score = 0;
  int _questionNumber = 1;
  final int _totalQuestions = 10;

  final List<String> _bases = ['Binary', 'Octal', 'Hexadecimal'];

  @override
  void initState() {
    super.initState();
    _generateQuestion();
  }

  void _generateQuestion() {
    if (_questionNumber > _totalQuestions) {
      _showFinalScore();
      return;
    }

    setState(() {
      _decimalNumber = _random.nextInt(256);
      _conversionBase = _bases[_random.nextInt(_bases.length)];
      _feedback = '';
      _answerController.clear();

      switch (_conversionBase) {
        case 'Binary':
          _correctAnswer = _decimalNumber.toRadixString(2);
          break;
        case 'Octal':
          _correctAnswer = _decimalNumber.toRadixString(8);
          break;
        case 'Hexadecimal':
          _correctAnswer = _decimalNumber.toRadixString(16).toUpperCase();
          break;
      }
    });
  }

  void _checkAnswer() {
    String userAnswer = _answerController.text.trim();
    if (userAnswer.toUpperCase() == _correctAnswer.toUpperCase()) {
      setState(() {
        _feedback = '✅ Correct!';
        _score++;
      });
    } else {
      setState(() {
        _feedback = '❌ Wrong! Correct answer: $_correctAnswer';
      });
    }

    Future.delayed(const Duration(seconds: 2), () {
      _questionNumber++;
      _generateQuestion();
    });
  }

  void _showFinalScore() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          '🎯 Quiz Finished!',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Your score: $_score / $_totalQuestions',
          style: const TextStyle(fontSize: 18),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _score = 0;
                _questionNumber = 1;
                _generateQuestion();
              });
            },
            child: const Text('Restart', style: TextStyle(color: Colors.blue)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color.fromARGB(255, 243, 33, 33), Color(0xFF21CBF3)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(20.w),
              child: Card(
                elevation: 12,
                shadowColor: Colors.black54,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25.r),
                ),
                child: Padding(
                  padding: EdgeInsets.all(20.w),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 📘 عنوان الصفحة
                      Text(
                        "Number Converter Quiz",
                        style: TextStyle(
                          fontSize: 26.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[800],
                        ),
                      ),
                      SizedBox(height: 15.h),

                      // 📊 عدد الأسئلة
                      Text(
                        "Question $_questionNumber / $_totalQuestions",
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.black54,
                        ),
                      ),
                      SizedBox(height: 20.h),

                      // ❓ نص السؤال
                      Container(
                        padding: EdgeInsets.all(16.w),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(20.r),
                        ),
                        child: Column(
                          children: [
                            Text(
                              "Convert this number:",
                              style: TextStyle(
                                fontSize: 18.sp,
                                fontWeight: FontWeight.w500,
                                color: Colors.black87,
                              ),
                            ),
                            SizedBox(height: 8.h),
                            Text(
                              '$_decimalNumber → $_conversionBase',
                              style: TextStyle(
                                fontSize: 28.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.blueAccent,
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 25.h),

                      // ✏️ إدخال الجواب
                      TextField(
                        controller: _answerController,
                        decoration: InputDecoration(
                          labelText: "Enter your answer",
                          prefixIcon: const Icon(Icons.edit, color: Colors.blue),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20.r),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        style: TextStyle(fontSize: 18.sp),
                      ),
                      SizedBox(height: 25.h),

                      // 🟦 زر التأكيد
                      ElevatedButton.icon(
                        onPressed: _checkAnswer,
                        icon: const Icon(Icons.check_circle_outline),
                        label: Text("Check Answer",
                            style: TextStyle(fontSize: 18.sp)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          padding: EdgeInsets.symmetric(
                              horizontal: 40.w, vertical: 14.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20.r),
                          ),
                          elevation: 5,
                        ),
                      ),
                      SizedBox(height: 20.h),

                      // 💬 النتيجة (صح / خطأ)
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 400),
                        child: Text(
                          _feedback,
                          key: ValueKey(_feedback),
                          style: TextStyle(
                            fontSize: 20.sp,
                            color: _feedback.startsWith('✅')
                                ? Colors.green
                                : Colors.redAccent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      SizedBox(height: 20.h),

                      // 🧮 عرض النقاط
                      Text(
                        "Score: $_score",
                        style: TextStyle(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[800],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
