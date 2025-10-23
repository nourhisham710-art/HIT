import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:core';

class Homescreen extends StatefulWidget {
  const Homescreen({super.key});

  @override
  State<Homescreen> createState() => _HomescreenState();
}

List<Map<String, String>> history = [];
var number = TextEditingController();
var base1 = TextEditingController();
var base2 = TextEditingController();

class _HomescreenState extends State<Homescreen> with SingleTickerProviderStateMixin {
  String result = "";
  String? selectedNegativeMode;
  int? bitCount;

  int _charToVal(String ch) {
    final code = ch.codeUnitAt(0);
    if (code >= 48 && code <= 57) return code - 48;
    if (code >= 65 && code <= 90) return code - 65 + 10;
    if (code >= 97 && code <= 122) return code - 97 + 10;
    throw FormatException('رمز غير صالح: $ch');
  }

  String _valToChar(int val) {
    if (val < 10) return String.fromCharCode(48 + val);
    return String.fromCharCode(65 + val - 10);
  }

  bool _isValidForBase(String s, int base) {
    if (s.isEmpty) return false;
    int start = (s.startsWith('+') || s.startsWith('-')) ? 1 : 0;
    int dots = 0;
    for (int i = start; i < s.length; i++) {
      if (s[i] == '.') {
        dots++;
        if (dots > 1) return false;
        continue;
      }
      try {
        if (_charToVal(s[i]) >= base) return false;
      } catch (_) {
        return false;
      }
    }
    return true;
  }

  bool _isOnlyZero(String s) {
    String cleaned = s.trim();
    if (cleaned.isEmpty) return false;
    cleaned = cleaned.replaceAll(RegExp(r'^[+-]'), '');
    cleaned = cleaned.replaceAll('.', '');
    return RegExp(r'^0+$').hasMatch(cleaned);
  }

  /// تحويل عام بين القواعد مع دعم الفواصل (يحافظ على الكسور)
  String convertBase(String input, int fromBase, int toBase, [int precision = 24]) {
    if (fromBase < 2 || fromBase > 36) {
      throw FormatException('قاعدة الإدخال يجب أن تكون بين 2 و 36.');
    }
    if (toBase < 2 || toBase > 36) {
      throw FormatException('قاعدة الإخراج يجب أن تكون بين 2 و 36.');
    }
    if (_isOnlyZero(input)) {
      throw FormatException('لا يمكن إدخال "0" فقط بدون أرقام إضافية.');
    }
    if (!_isValidForBase(input, fromBase)) {
      throw FormatException('العدد "$input" غير صالح للقاعدة $fromBase.');
    }

    bool negative = input.startsWith('-');
    if (input.startsWith('+') || input.startsWith('-')) input = input.substring(1);

    List<String> parts = input.split('.');
    String intPart = parts[0].isEmpty ? '0' : parts[0];
    String fracPart = parts.length > 1 ? parts[1] : '';

    // int part -> decimal (BigInt)
    BigInt base = BigInt.from(fromBase);
    BigInt intValue = BigInt.zero;
    for (int i = 0; i < intPart.length; i++) {
      intValue = intValue * base + BigInt.from(_charToVal(intPart[i]));
    }

    // frac part -> numerator/denominator (BigInt) for exact conversion
    BigInt fracNumerator = BigInt.zero;
    BigInt fracDenominator = BigInt.one;
    for (int i = 0; i < fracPart.length; i++) {
      fracNumerator = fracNumerator * base + BigInt.from(_charToVal(fracPart[i]));
      fracDenominator = fracDenominator * base;
    }

    BigInt numerator = intValue * fracDenominator + fracNumerator;
    BigInt denominator = fracDenominator;
    if (negative) numerator = -numerator;

    bool neg = numerator.isNegative;
    numerator = numerator.abs();

    // integer output
    BigInt intPartOut = numerator ~/ denominator;
    BigInt remainder = numerator % denominator;
    BigInt outBase = BigInt.from(toBase);

    List<String> intChars = [];
    if (intPartOut == BigInt.zero) {
      intChars.add('0');
    } else {
      while (intPartOut > BigInt.zero) {
        BigInt rem = intPartOut % outBase;
        intChars.add(_valToChar(rem.toInt()));
        intPartOut ~/= outBase;
      }
      intChars = intChars.reversed.toList();
    }

    // fractional output
    List<String> fracChars = [];
    int count = 0;
    while (remainder != BigInt.zero && count < precision) {
      remainder *= outBase;
      BigInt digit = remainder ~/ denominator;
      remainder %= denominator;
      fracChars.add(_valToChar(digit.toInt()));
      count++;
    }

    String out = intChars.join();
    if (fracChars.isNotEmpty) out += '.${fracChars.join()}';
    if (neg) out = '-$out';
    return out;
  }

  String applyNegativeSystem(String binaryInt, String mode, int bits) {
    // binaryInt: only integer part in binary (e.g. "1100")
    // Ensure binary content only
    if (!RegExp(r'^[01]+$').hasMatch(binaryInt)) return binaryInt;
    // we will handle as magnitude then form representation with 'bits' length
    String mag = binaryInt; // magnitude bits
    // if magnitude longer than bits-1 (for sign-magnitude) or bits (for others),
    // we will keep rightmost bits (truncate left) to fit — this is a practical choice.
    if (mode == 'Sign-Magnitude') {
      int magBits = max(0, bits - 1);
      String padded = mag.padLeft(magBits, '0');
      if (padded.length > magBits) padded = padded.substring(padded.length - magBits);
      return '1' + padded; // leading sign bit = 1
    } else if (mode == 'One’s Complement') {
      // build full bits (bits length) from magnitude, then invert
      String padded = mag.padLeft(bits, '0');
      if (padded.length > bits) padded = padded.substring(padded.length - bits);
      return padded.split('').map((b) => b == '0' ? '1' : '0').join();
    } else if (mode == 'Two’s Complement') {
      // compute (2^bits - magnitude) in binary, padded to bits
      BigInt magVal = BigInt.parse(mag, radix: 2);
      BigInt mod = BigInt.one << bits; // 2^bits
      BigInt twos = (mod - magVal) % mod;
      return twos.toRadixString(2).padLeft(bits, '0');
    }
    return binaryInt;
  }

  // ---------------- convert action ----------------
  void _convertNow() async {
    final input = number.text.trim();
    final fromBase = int.tryParse(base1.text.trim());
    final toBase = int.tryParse(base2.text.trim());

    if (input.isEmpty || fromBase == null || toBase == null) {
      _showError('Please enter the number and bases correctly.');
      return;
    }

    try {
      bool isNegative = input.startsWith('-');
      // First convert generically
      String output = convertBase(input, fromBase, toBase);

      // Only if negative and converting TO binary, show bottom sheets and apply representation
      if (isNegative && toBase == 2) {
        // 1) choose mode (bottom sheet)
        final mode = await _showNegativeSystemBottomSheet();
        if (mode == null) {
          // user canceled -> keep generic output
          setState(() {
            result = _finalizeResultForDisplay(input, output, null);
          });
          return;
        }
        selectedNegativeMode = mode;

        // 2) choose bits (bottom sheet)
        final bits = await _showBitsBottomSheet();
        if (bits == null || bits <= 0) {
          // user canceled or invalid -> keep generic output
          setState(() {
            result = _finalizeResultForDisplay(input, output, selectedNegativeMode);
          });
          return;
        }
        bitCount = bits;

        // Apply representation only to integer part
        String withoutSign = output.replaceAll('-', '');
        List<String> parts = withoutSign.split('.');
        String intPart = parts[0].isEmpty ? '0' : parts[0];
        String fracPart = parts.length > 1 ? parts[1] : '';

        // apply chosen negative system on intPart
        String convertedInt = applyNegativeSystem(intPart, selectedNegativeMode!, bitCount!);

        // if original had fraction -> keep it
        String combined = fracPart.isNotEmpty ? '$convertedInt.$fracPart' : convertedInt;
        output = combined;
      }

      setState(() {
        result = _finalizeResultForDisplay(input, output, selectedNegativeMode);
        history.add({
          'input': input,
          'from': base1.text,
          'output': result,
          'to': base2.text,
        });
      });
    } on FormatException catch (e) {
      _showError(e.message);
    } catch (e) {
      _showError('An unexpected error occurred: $e');
    }
  }

  String _finalizeResultForDisplay(String originalInput, String convertedOutput, String? mode) {
    // Show decimal point only if original input contains '.'
    bool hasFraction = originalInput.contains('.');
    String out = hasFraction ? convertedOutput : convertedOutput.replaceAll('.', '');
    // Only show mode name in UI separately (we already store mode in selectedNegativeMode)
    return out;
  }

  // ---------------- Bottom Sheets ----------------
  Future<String?> _showNegativeSystemBottomSheet() {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: false,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      builder: (context) {
        return Container(
          margin: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF121212), // dark sheet
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 10)],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 5,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white12,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.sign_language, color: Colors.white70),
                  title: const Text("Sign-Magnitude", style: TextStyle(color: Colors.white)),
                  subtitle: const Text("leading sign bit + magnitude", style: TextStyle(color: Colors.white70, fontSize: 12)),
                  onTap: () => Navigator.pop(context, "Sign-Magnitude"),
                ),
                const Divider(color: Colors.white12, height: 1),
                ListTile(
                  leading: const Icon(Icons.swap_horiz, color: Colors.white70),
                  title: const Text("One’s Complement", style: TextStyle(color: Colors.white)),
                  subtitle: const Text("invert bits", style: TextStyle(color: Colors.white70, fontSize: 12)),
                  onTap: () => Navigator.pop(context, "One’s Complement"),
                ),
                const Divider(color: Colors.white12, height: 1),
                ListTile(
                  leading: const Icon(Icons.calculate, color: Colors.white70),
                  title: const Text("Two’s Complement", style: TextStyle(color: Colors.white)),
                  subtitle: const Text("invert bits + add 1", style: TextStyle(color: Colors.white70, fontSize: 12)),
                  onTap: () => Navigator.pop(context, "Two’s Complement"),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.pop(context, null),
                  child: const Text("Cancel", style: TextStyle(color: Colors.white70)),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<int?> _showBitsBottomSheet() {
    final controller = TextEditingController(text: '8');
    return showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Container(
            margin: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF121212),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 10)],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 5,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white12,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text("Enter number of bits", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: controller,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'e.g., 8',
                      hintStyle: TextStyle(color: Colors.white38),
                      filled: true,
                      fillColor: Colors.white10,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context, null),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.white12),
                          ),
                          child: const Text("Cancel", style: TextStyle(color: Colors.white70)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            final v = int.tryParse(controller.text.trim());
                            Navigator.pop(context, v);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1E88E5),
                          ),
                          child: const Text("Confirm"),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.redAccent),
    );
  }

  // ---------------- UI ----------------
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
              padding: const EdgeInsets.all(20),
              child: Card(
                elevation: 12,
                shadowColor: Colors.black54,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      Text(
                        "Base Converter",
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[800],
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: number,
                        decoration: InputDecoration(
                          labelText: "Number",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: base1,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: "From Base",
                                prefixIcon: const Icon(Icons.input),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Icon(Icons.arrow_forward_rounded, size: 28, color: Colors.blue),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: base2,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: "To Base",
                                prefixIcon: const Icon(Icons.output),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 25),
                      ElevatedButton.icon(
                        onPressed: _convertNow,
                        icon: const Icon(Icons.transform),
                        label: const Text("Convert", style: TextStyle(fontSize: 18)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          elevation: 5,
                        ),
                      ),
                      const SizedBox(height: 25),
                      if (result.isNotEmpty)
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(15),
                          ),
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              Text(
                                "Result",
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue[900]),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                result,
                                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.blueAccent),
                              ),
                              if (selectedNegativeMode != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    "Mode: $selectedNegativeMode",
                                    style: const TextStyle(fontSize: 16, color: Colors.black54),
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
      ),
    );
  }
}
