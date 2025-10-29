import 'package:dotted_line/dotted_line.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class Sidebarwidgets extends StatefulWidget {
  const Sidebarwidgets({super.key, required userPermissions, Map<String, dynamic>? selectedUser});

  @override
  State<Sidebarwidgets> createState() => _SidebarwidgetsState();
}

class _SidebarwidgetsState extends State<Sidebarwidgets>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _controller;
  late Animation<double> _heightAnimation;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _heightAnimation = Tween<double>(begin: 60, end: 260).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  void _toggleExpand() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    DateTime now = DateTime.now();
    String formattedDate = DateFormat("EEEE, dd MMM yyyy").format(now);
    String formattedTime = DateFormat("hh:mm a").format(now);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F6),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 12, top: 16, right: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ---------- Header Section ----------
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 90,
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFFDEE8FF),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset("assets/icon/-01.png",
                              width: 18, height: 18),
                          const SizedBox(width: 10),
                          const Text(
                            "Back",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF585A5C),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        Image.asset("assets/icon/calender.png",
                            width: 18, height: 18),
                        const SizedBox(width: 3),
                        Text(
                          formattedDate,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF656161),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Image.asset("assets/icon/clock.png",
                            width: 18, height: 18),
                        const SizedBox(width: 3),
                        Text(
                          formattedTime,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF656161),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text(
                      "Order ID #3245",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111827),
                      ),
                    ),
                    Text(
                      "Payment Summary",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF656161),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // ---------- Items Container ----------
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFDEE8FF),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.all(10),
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFFFF),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: ListView.builder(
                        itemCount: 6,
                        itemBuilder: (context, index) {
                          final items = [
                            ["322", "Mutton Fry Biryani", "1", "300.00"],
                            ["524", "Chicken Biryani", "1", "200.00"],
                            ["325", "Paneer Tikka", "1", "180.00"],
                            ["954", "Butter Naan", "5", "200.00"],
                            ["156", "Butter Masala", "1", "220.00"],
                            ["231", "Chicken 65", "1", "210.00"],
                          ];
                          final item = items[index];
                          return Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                child: Row(
                                  mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(item[0],
                                        style: const TextStyle(fontSize: 12)),
                                    Text(item[1],
                                        style: const TextStyle(fontSize: 12)),
                                    Text(item[2],
                                        style: const TextStyle(fontSize: 12)),
                                    Text(item[3],
                                        style: const TextStyle(fontSize: 12)),
                                  ],
                                ),
                              ),
                              const Divider(color: Color(0xFFE6E7E8), thickness: 1),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 60), // space for bottom toggle container
              ],
            ),
          ),

          // ---------- Fixed Bottom Toggle Container ----------
          Align(
            alignment: Alignment.bottomCenter,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Container(
                  width: MediaQuery.of(context).size.width * 0.315,
                  height: _heightAnimation.value,
                  margin: const EdgeInsets.only(left: 12, bottom: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFFFF),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 6,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: _toggleExpand,
                        child: Container(
                          height: 50,
                          decoration: BoxDecoration(
                            color: const Color(0xFFDEE8FF),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Gross Total",
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: _isExpanded
                                      ? Colors.blueAccent
                                      : Colors.black,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                _isExpanded
                                    ? Icons.keyboard_arrow_down
                                    : Icons.keyboard_arrow_up,
                                color: Colors.black,
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (_isExpanded) const Divider(height: 1),

                      // Expanded Details (Gross total section)
                      if (_isExpanded)
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: const [
                                Row(
                                  mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text("Sub Total"),
                                    Text("2210.00"),
                                  ],
                                ),
                                Row(
                                  mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text("Tax"),
                                    Text("00.00"),
                                  ],
                                ),
                                Row(
                                  mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text("Discount (10%)",
                                        style: TextStyle(color: Colors.blue)),
                                    Text("-220.00",
                                        style: TextStyle(color: Colors.blue)),
                                  ],
                                ),
                                Row(
                                  mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text("Coupon (WELCOME50)",
                                        style:
                                        TextStyle(color: Colors.green)),
                                    Text("-200.00",
                                        style: TextStyle(color: Colors.green)),
                                  ],
                                ),
                                DottedLine(
                                    dashLength: 4,
                                    dashGapLength: 4,
                                    lineThickness: 1,
                                    dashColor: Color(0x66666626)),
                                Row(
                                  mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text("Total",
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold)),
                                    Text("1790.00",
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
