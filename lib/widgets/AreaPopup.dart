import 'package:flutter/material.dart';

class AreaPopup extends StatefulWidget {
  final TextEditingController areaNameController;
  final bool isDuplicateName;
  final String errorMessage;
  final VoidCallback togglePopup;
  final VoidCallback createArea;

  const AreaPopup({
    Key? key,
    required this.areaNameController,
    required this.isDuplicateName,
    required this.errorMessage,
    required this.togglePopup,
    required this.createArea,
  }) : super(key: key);

  @override
  _AreaPopupState createState() => _AreaPopupState();
}

class _AreaPopupState extends State<AreaPopup> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.togglePopup,
      child: Container(
        color: Colors.black.withAlpha(100),
        child: Center(
          child: GestureDetector(
            onTap: () {}, // Prevent popup dismiss on tap inside
            behavior: HitTestBehavior.translucent,
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                width: 280,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: Colors.black12, blurRadius: 5),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Stack(
                      children: [
                        Align(
                          alignment: Alignment.center,
                          child: Padding(
                            padding: const EdgeInsets.only(
                              top: 25,
                              right: 25,
                              bottom: 20,
                            ),
                            child: Text(
                              "Let’s Create an Area/Zone",
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          right: 0,
                          top: 0,
                          child: GestureDetector(
                            onTap: widget.togglePopup,
                            child: Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                color: Color(0xFFF86157),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Color(0x3F000000),
                                    blurRadius: 11,
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 5),
                    Text(
                      "Area/Zone",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    SizedBox(height: 5),
                    Container(
                      height: 45,
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Color(0xFFECEBEB)),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [BoxShadow(color: Color(0x19000000))],
                      ),
                      child: Row(
                        children: [
                          SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: widget.areaNameController,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Type an Area/Zone name',
                                border: InputBorder.none,
                                isDense: true,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 5),
                    if (widget.isDuplicateName)
                      Padding(
                        padding: const EdgeInsets.only(
                          left: 4.0,
                          bottom: 6,
                        ),
                        child: Text(
                          widget.errorMessage,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFFDA4A38),
                          ),
                        ),
                      ),
                    SizedBox(height: 7),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              widget.areaNameController.clear();
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[100],
                            foregroundColor: Color(0xFF4C5F7D),
                            padding: EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 3,
                            ),
                            minimumSize: Size(0, 30),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            "Clear",
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                        SizedBox(width: 7),
                        ElevatedButton(
                          onPressed: widget.createArea,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFFDA4A38),
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 3,
                            ),
                            minimumSize: Size(0, 30),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            "Create",
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
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
