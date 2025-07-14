import 'package:flutter/material.dart';
import '../widgets/NavigationHelper.dart';
import '../widgets/bottom_nav_bar.dart';

class KitchenStatusScreen extends StatefulWidget {
  final String pin;
  final String associatedManagerPin;
  final String token;
  final String restaurantId;
  final String restaurantName;

  const KitchenStatusScreen({
    Key? key,
    required this.pin,
    required this.associatedManagerPin,
    required this.token,
    required this.restaurantId,
    required this.restaurantName,
  }) : super(key: key);


  @override
  _KitchenStatusScreenState createState() => _KitchenStatusScreenState();
}



class _KitchenStatusScreenState extends State<KitchenStatusScreen> {
  final List<int> cardList = List.generate(12, (index) => index);
  int _selectedIndex = 2;

  void _onNavItemTapped(int index) {
    NavigationHelper.handleNavigation(
      context,
      _selectedIndex,
      index,
      widget.pin,
      widget.token,
      widget.restaurantId,
      widget.restaurantName,
    );
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF6F7FB),
      body: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 60), // For AppBar space
              SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Text(
                  'Kitchen Status',
                  style: TextStyle(
                    color: const Color(0xFF4F4E4E),
                    fontSize: 25,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              SizedBox(height: 20),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(14),
                    child: Scrollbar(
                      thumbVisibility: true,
                      child: GridView.builder(
                        itemCount: cardList.length,
                        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 360,
                          crossAxisSpacing: 20,
                          mainAxisSpacing: 20,
                          childAspectRatio: 95 / 145,
                        ),
                        itemBuilder: (context, index) {
                          return KitchenCard(index: index);
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Bottom Navigation Bar
          BottomNavBar(
            selectedIndex: _selectedIndex,
            onItemTapped: _onNavItemTapped,
          ),
        ],
      ),
    );
  }
}

class KitchenCard extends StatefulWidget {
  final int index; // add this

  KitchenCard({required this.index}); // constructor

  @override
  _KitchenCardState createState() => _KitchenCardState();
}


class _KitchenCardState extends State<KitchenCard> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha((0.3 * 255).toInt()),
            spreadRadius: 2,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Color(0xFFF2F4F7),
                borderRadius: BorderRadius.circular(15),
              ),
              padding: EdgeInsets.all(15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Icon(Icons.restaurant, color: Colors.blue, size: 20),
                          SizedBox(width: 4),
                          RichText(
                            text: TextSpan(
                              text: 'KOT No: ',
                              style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.w400,
                                fontSize: 14,
                              ),
                              children: [
                                TextSpan(
                                  text: '#110 ',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      // Show status & timer ONLY for first card
                      if (widget.index == 1)
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Color(0xFFFFE6E6),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '• Preparing',
                                style: TextStyle(
                                  color: Color(0xFFFF5C5C),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),

                  SizedBox(height: 5),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text(
                        'order Id:',
                        style: TextStyle(
                          fontWeight: FontWeight.normal,
                          fontSize: 13,
                          color: Colors.black,
                        ),
                      ),
                      SizedBox(width: 3),
                      Text(
                        '65478',
                        style: TextStyle(
                          fontSize: 11,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(width: 50),
                      if (widget.index == 1)
                        Row(
                          children: [
                            Icon(Icons.hourglass_bottom, color: Color(0xFFFF5C5C), size: 14),
                            SizedBox(width: 4),
                            Text(
                              '00:45',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.black,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),

                  SizedBox(height: 4),
                  Text(
                    '9:37 AM',
                    style: TextStyle(fontSize: 11, color: Colors.black,fontWeight: FontWeight.w700),
                  ),
                  SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Eamon Thornewood',
                        style: TextStyle(
                          fontWeight: FontWeight.w400,
                          fontSize: 11,
                          color: Colors.black,
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Color(0xFFDFF6FD),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'Dine In - Garden-T4',
                          style: TextStyle(
                            color: const Color(0xFF086787),
                            fontSize: 10,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 10),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Container(
                    width: 170,
                    child: Text(
                      'Order',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Text('Qty', style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            SizedBox(height: 8),
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Stack(
                  children: [
                    ListView(
                      controller: _scrollController,
                      padding: EdgeInsets.only(right: 20),
                      children: [
                        _buildOrderItem('Paneer Tikka', '01'),
                        _buildOrderItem('Tandoori Naan', '02'),
                        _buildOrderItem('Garlic Naan', '03'),
                        _buildOrderItem('Paneer Biryani', '01'),
                        _buildOrderItem('Lassi', '01'),
                        _buildOrderItem('Paneer Biryani', '01'),
                        _buildOrderItem('Masala Dosa', '02'),
                        _buildOrderItem('Idli Sambar', '02'),
                      ],
                    ),
                    Positioned(
                      top: 0,
                      bottom: 0,
                      right: -4,
                      child: Scrollbar(
                        thumbVisibility: true,
                        controller: _scrollController,
                        thickness: 6,
                        radius: Radius.circular(10),
                        scrollbarOrientation: ScrollbarOrientation.right,
                        child: Container(width: 0),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFE9F2FF),
                  foregroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: EdgeInsets.symmetric(vertical: 5),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'More option',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(width: 5),
                    Container(
                      padding: EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.menu, color: Colors.white, size: 10),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderItem(String itemName, String qty) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(itemName, style: TextStyle(fontSize: 13)),
          Text(qty, style: TextStyle(fontSize: 13)),
        ],
      ),
    );
  }
}
