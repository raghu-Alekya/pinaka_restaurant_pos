import 'dart:async';
import 'package:pinaka_restaurant_pos/ui/tables_screen.dart';
import 'package:flutter/material.dart';
import '../widgets/number_pad.dart';
import '../widgets/pin_input.dart';

class EmployeeLoginPage extends StatefulWidget {
  const EmployeeLoginPage({super.key});

  @override
  _EmployeeLoginPageState createState() => _EmployeeLoginPageState();
}

class _EmployeeLoginPageState extends State<EmployeeLoginPage> {
  String pin = "";
  int _currentIndex = 0;

  final List<String> _images = [
    'assets/img_1.png',
    'assets/loginname.png',
    'assets/POS-systems.jpg',
    'assets/img_1.png',
  ];

  final List<String> _captions = [
    '"Designed for speed and efficiency — PINAKA POS helps you complete sales in seconds with an intuitive and user-friendly interface, reducing training time and increasing productivity."',
    '"Track sales, manage inventory, and handle staff permissions — all from one sleek dashboard that’s built for real-time data access and seamless integration with your business tools."',
    '"Reliable and secure — our POS keeps your business running smoothly every day with 24/7 uptime, cloud backups, and end-to-end encrypted transactions."',
    '"Designed for speed and efficiency — PINAKA POS helps you complete sales in seconds with an intuitive and user-friendly interface, reducing training time and increasing productivity."',
  ];

  late PageController _pageController;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();

    _timer = Timer.periodic(const Duration(seconds: 2), (Timer timer) {
      _currentIndex++;

      _pageController.animateToPage(
        _currentIndex,
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeInOut,
      );

      if (_currentIndex == _images.length - 1) {
        Future.delayed(const Duration(milliseconds: 710), () {
          _pageController.jumpToPage(0);
          _currentIndex = 0;
        });
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _timer.cancel();
    super.dispose();
  }

  void _onKeyPressed(String value) {
    setState(() {
      if (value == "C") {
        pin = "";
      } else if (value == "⌫" && pin.isNotEmpty) {
        pin = pin.substring(0, pin.length - 1);
      } else if (pin.length < 6 && value != "C" && value != "⌫") {
        pin += value;
      }
    });
  }

  // Future<void> _login() async {
  //   if (pin == "999999") {
  //     Navigator.push(
  //       context,
  //       MaterialPageRoute(builder: (context) => TablesScreen()),
  //     );
  //   } else {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(content: Text("Invalid PIN")),
  //     );
  //   }
  // }
  Future<void> _login() async {
    if (pin == "999999") {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return GuestDetailsDialog();
        },
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Invalid PIN")),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SizedBox(
          width: 1920, height: 1080,
          child: Row(
            children: [
              // Left Side - Image + Caption
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _images.length,
                  physics: const NeverScrollableScrollPhysics(),
                  itemBuilder: (context, index) {
                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.asset(
                          _images[index],
                          fit: BoxFit.cover,
                        ),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 700),
                          transitionBuilder: (Widget child, Animation<double> animation) {
                            final offsetAnimation = Tween<Offset>(
                              begin: const Offset(-1.0, 0.0),
                              end: Offset.zero,
                            ).animate(animation);
                            return SlideTransition(position: offsetAnimation, child: child);
                          },
                          child: Container(
                            key: ValueKey<int>(index),
                            padding: const EdgeInsets.symmetric(horizontal: 150),
                            alignment: Alignment.bottomCenter,
                            margin: const EdgeInsets.only(bottom: 70),
                            child: Text(
                              _captions[index],
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w400,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),

              // Right Side - Login Form
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        'assets/pinaka.png',
                        height: 100,
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'Employee Login',
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 25,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w600,
                          height: 0.9,
                        ),
                      ),
                      const SizedBox(height: 19),
                      const Text(
                        'Please Input your PIN to Validate your self',
                        style: TextStyle(
                          color: Color(0xFF4C5F7D),
                          fontSize: 18.5,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w500,
                          height: 0.92,
                        ),
                      ),
                      const SizedBox(height: 22),
                      SizedBox(
                        width: 450,
                        child: Column(
                          children: [
                            PinInput(pin: pin),
                            const SizedBox(height: 20),
                            NumberPad(onKeyPressed: _onKeyPressed),
                            const SizedBox(height: 30),
                            ElevatedButton(
                              onPressed: _login,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                padding: const EdgeInsets.symmetric(vertical: 20),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                minimumSize: const Size(440, 40),
                              ),
                              child: const Text(
                                "Login",
                                style: TextStyle(
                                  fontSize: 20,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


class GuestDetailsDialog extends StatefulWidget {
  @override
  _GuestDetailsDialogState createState() => _GuestDetailsDialogState();
}

class _GuestDetailsDialogState extends State<GuestDetailsDialog> {
  final TextEditingController mobileController = TextEditingController();
  final TextEditingController nameController = TextEditingController();

  List<Map<String, String>> staticGuests = [
    {"name": "Ajith Kiran", "mobile": "98765 40321"},
    {"name": "Ajith Kishan", "mobile": "98765 32103"},
    {"name": "Swapna", "mobile": "7680074982"},
    {"name": "Krishna", "mobile": "9963205582"},
    {"name": "Madhuri", "mobile": "98765 32104"},
  ];

  List<Map<String, String>> filteredGuests = [];

  void filterGuests(String query) {
    setState(() {
      filteredGuests = staticGuests.where((guest) {
        return guest["name"]!.toLowerCase().contains(query.toLowerCase()) ||
            guest["mobile"]!.contains(query);
      }).toList();
    });
  }

  void selectGuest(Map<String, String> guest) {
    setState(() {
      nameController.text = guest["name"]!;
      mobileController.text = guest["mobile"]!;
      filteredGuests = [];
    });
  }

  @override
  void initState() {
    super.initState();
    nameController.addListener(() {
      filterGuests(nameController.text);
    });
    mobileController.addListener(() {
      filterGuests(mobileController.text);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 500,
        height: filteredGuests.isNotEmpty ? 540 : 350,
        clipBehavior: Clip.antiAlias,
        decoration: ShapeDecoration(
          color: const Color(0xFFFBFBFB),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(40, 20, 40, 20),
                child: Column(
                  children: [
                    Text(
                      'Guest Details',
                      style: TextStyle(
                        color: const Color(0xFF373535),
                        fontSize: 21,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Please enter guest details for further process',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: const Color(0xFF4C5F7D),
                        fontSize: 16,
                        fontFamily: 'Montserrat',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 20),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Mobile Number',
                          style: TextStyle(
                            color: const Color(0xFF4C5F7D),
                            fontSize: 14,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w500,
                          )),
                    ),
                    SizedBox(height: 5),
                    Container(
                      height: 45,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Color(0xFF6D7A8F)),
                      ),
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Center(
                        child: TextField(
                          controller: mobileController,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: '98765 43210',
                            hintStyle: TextStyle(color: Color(0xFF656161)),
                          ),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Montserrat',
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Guest Name',
                          style: TextStyle(
                            color: const Color(0xFF4C5F7D),
                            fontSize: 14,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w500,
                          )),
                    ),
                    SizedBox(height: 5),
                    Container(
                      height: 45,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Color(0xFF6D7A8F)),
                      ),
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Center(
                        child: TextField(
                          controller: nameController,
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: 'Type here',
                            hintStyle: TextStyle(color: Color(0xFFD9D9D9)),
                          ),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Montserrat',
                          ),
                        ),
                      ),
                    ),
                    if (filteredGuests.isNotEmpty) ...[
                      SizedBox(height: 12),
                      Container(
                        padding: EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                        color: Color(0xFF999393),
                        child: Row(
                          children: const [
                            SizedBox(
                                width: 20,
                                child: Text('#', style: TextStyle(color: Colors.white,fontWeight: FontWeight.bold))),
                            SizedBox(
                                width: 150,
                                child: Text('Name', style: TextStyle(color: Colors.white,fontWeight: FontWeight.bold))),
                            Expanded(
                                child: Text('Mobile', style: TextStyle(color: Colors.white,fontWeight: FontWeight.bold))),
                            SizedBox(width: 60),
                          ],
                        ),
                      ),
                      SizedBox(height: 4),
                      Container(
                        height: 130,
                        child: ListView.builder(
                          itemCount: filteredGuests.length,
                          itemBuilder: (context, index) {
                            final guest = filteredGuests[index];
                            return Card(
                              color: Colors.white,
                              margin: EdgeInsets.symmetric(vertical: 4),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              elevation: 1.5,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                child: Row(
                                  children: [
                                    SizedBox(width: 20, child: Text('${index + 1}')),
                                    SizedBox(width: 150, child: Text(guest["name"]!)),
                                    Expanded(child: Text(guest["mobile"]!)),
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: Icon(Icons.check_circle, color: Colors.blue),
                                          onPressed: () => selectGuest(guest),
                                          iconSize: 20,
                                          padding: EdgeInsets.zero,
                                        ),
                                        IconButton(
                                          icon: Icon(Icons.edit, color: Colors.orange),
                                          onPressed: () {
                                            nameController.text = guest["name"]!;
                                            mobileController.text = guest["mobile"]!;
                                          },
                                          iconSize: 20,
                                          padding: EdgeInsets.zero,
                                        ),
                                      ],
                                    )
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      )
                    ],
                    SizedBox(height: 20),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          filteredGuests.clear();
                        });
                        Navigator.pop(context);
                      },
                      child: Container(
                        width: 200,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Color(0xFFD93535),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            'Save Details',
                            style: TextStyle(
                              color: Color(0xFFF9F6F6),
                              fontSize: 16,
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              right: 20,
              top: 20,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: Color(0xFFF84337),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.close, color: Colors.white, size: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
