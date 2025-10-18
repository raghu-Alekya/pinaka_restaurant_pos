import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:pinaka_restaurant_pos/App%20flow/widgets/paymentsucess.dart';
import '../../services/app_database.dart';
import 'coupon_widget.dart';
import 'discount_screen.dart';

class Numberpad extends StatefulWidget {
  const Numberpad({super.key});

  @override
  State<Numberpad> createState() => _NumberpadState();
}

class _NumberpadState extends State<Numberpad> {
  String selectedOption = '';
  String amount = '';
  double balanceAmount = AppDatabase.instance.totalamount ?? 0.0;
  double? calculatedChange;
  String selectedPaymentMode = "Cash";
  bool isCashSelected = true;

  void handleKeyPress(String key) {
    if (key == "C") {
      setState(() {
        amount = '';
      });
    } else if (key == "⌫") {
      if (amount.isNotEmpty) {
        setState(() {
          amount = amount.substring(0, amount.length - 1);
        });
      }
    } else if (key == "Pay") {
      if (amount.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Please enter amount')));
        return;
      }
      if (selectedPaymentMode.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Please select a payment mode')));
        return;
      }
      double tenderAmount = double.tryParse(amount) ?? 0.0;
      calculatedChange = balanceAmount - tenderAmount;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: EdgeInsets.zero,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: EdgeInsets.only(left: 330, top: 60, bottom: 60),
                child:
                //Kitchenstatus(),
                Paymentsucess(
                  amount: amount,
                  paymentMode: selectedPaymentMode,
                  changeAmount: calculatedChange?.toStringAsFixed(2),
                ),
              ),
            ),
          );
        },
      );
    } else {
      setState(() {
        amount += key;
      });
    }
  }

  void _onPresetAmountTap(String value) {
    if (amount.isEmpty) {
      String cleaned = value.replaceAll("\$", "");
      setState(() {
        amount = cleaned;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F5F6),
      body: Row(
        children: [
          Column(
            children: [
              Padding(
                padding: EdgeInsets.only(top: 15),
                child: Container(
                  height: MediaQuery.of(context).size.height * 0.85,
                  width: MediaQuery.of(context).size.width * 0.65,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    // border: Border.all(
                    //   color: Colors.grey.withOpacity(0.5),
                    //   width: 0.8,
                    // ),
                  ),
                  child: Container(
                    height: MediaQuery.of(context).size.height * 0.60,
                    width: MediaQuery.of(context).size.width * 0.50,
                    child: Row(
                      children: [
                        Padding(
                          padding: EdgeInsets.only(left: 15),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(height: 5),
                              _buildPaymentModeItem(
                                "Select Payment Mode",
                                context,
                                selectedPaymentMode,
                                    (val) {
                                  setState(() {
                                    selectedPaymentMode = val;
                                    isCashSelected = val == "Cash";
                                  });
                                },
                              ),
                              SizedBox(height: 5),
                              Container(
                                alignment: Alignment.center,
                                height:
                                MediaQuery.of(context).size.height * 0.68,
                                width: MediaQuery.of(context).size.width * 0.40,
                                decoration: BoxDecoration(
                                  color: Color(0xFFDEE8FF),
                                  borderRadius: BorderRadius.circular(5),
                                  border: Border.all(
                                    color: Color(0xFFFFEBEB).withOpacity(1),
                                    width: 0.8,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    SizedBox(height: 8),
                                    Container(
                                      height:
                                      MediaQuery.of(context).size.height *
                                          0.05,
                                      width:
                                      MediaQuery.of(context).size.width *
                                          0.38,
                                      decoration: BoxDecoration(
                                        color: Color(0xFFFDF7F7),
                                        borderRadius: BorderRadius.circular(5),
                                        border: Border.all(
                                          color: Colors.white.withOpacity(0.5),
                                          width: 0.8,
                                        ),
                                      ),
                                      child: Padding(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 12,
                                        ),
                                        child: Text(
                                          "$selectedPaymentMode Payment",
                                          style: TextStyle(
                                            color: Color(0xFFFE6464),
                                            fontSize: 15,
                                            fontFamily: 'Inter',
                                            fontWeight: FontWeight.w500,
                                            decoration: TextDecoration.none,
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    Container(
                                      height:
                                      MediaQuery.of(context).size.height *
                                          0.07,
                                      width:
                                      MediaQuery.of(context).size.width *
                                          0.38,
                                      decoration: BoxDecoration(
                                        color: Color(0xFFFFFDFD),
                                        borderRadius: BorderRadius.circular(5),
                                        border: Border.all(
                                          color: Color(
                                            0xFFF2EEEE,
                                          ).withOpacity(0.5),
                                          width: 0.8,
                                        ),
                                      ),
                                      child: Padding(
                                        padding: EdgeInsets.only(right: 8.0),
                                        child: Align(
                                          alignment: Alignment.centerRight,
                                          child: Text(
                                            amount.isNotEmpty ? amount : '',
                                            style: TextStyle(
                                              color: Color(0xFF4C5F7D),
                                              fontSize: 15,
                                              fontFamily: 'Inter',
                                              fontWeight: FontWeight.w500,
                                              decoration: TextDecoration.none,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: 5),
                                    Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 12,
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                        children: [
                                          for (String val in [
                                            '\$38.00',
                                            '\$40.00',
                                            '\$50.00',
                                            '\$100.00',
                                            '\$500.00',
                                          ])
                                            GestureDetector(
                                              onTap:
                                                  () => _onPresetAmountTap(val),
                                              child: Container(
                                                height:
                                                MediaQuery.of(
                                                  context,
                                                ).size.height *
                                                    0.05,
                                                width:
                                                MediaQuery.of(
                                                  context,
                                                ).size.width *
                                                    0.05,
                                                decoration: BoxDecoration(
                                                  color: Color(0xFFE1F9DA),
                                                  borderRadius:
                                                  BorderRadius.circular(5),
                                                  border: Border.all(
                                                    color: Color(
                                                      0xFFF2EEEE,
                                                    ).withOpacity(0.5),
                                                    width: 0.8,
                                                  ),
                                                ),
                                                child: Center(
                                                  child: Text(
                                                    val,
                                                    style: TextStyle(
                                                      color: Color(0xFF318616),
                                                      fontSize: 15,
                                                      fontFamily: 'Inter',
                                                      fontWeight:
                                                      FontWeight.w500,
                                                      decoration:
                                                      TextDecoration.none,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      flex: 1,
                                      child: Padding(
                                        padding: EdgeInsets.all(12),
                                        child: NumberPad(
                                          onKeyPressed: handleKeyPress,
                                          selectedPaymentMode:
                                          selectedPaymentMode,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 25),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            buildPayment(
                              context,
                              amount,
                              "Transaction Overview :",
                            ),
                            Text(
                              "Coupons & Discounts :",
                              style: TextStyle(
                                color: Color(0xFF212121),
                                fontSize: 15,
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.none,
                              ),
                              textAlign: TextAlign.start,
                            ),
                            _buildPaymentDiscountItem(context),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

@override
Widget buildPayment(BuildContext context, String amount, String label) {
  double balanceAmount = AppDatabase.instance.totalamount ?? 0.0;
  double tenderAmount =
  amount.isNotEmpty ? double.tryParse(amount) ?? 0.0 : 0.0;
  double changeAmount = (balanceAmount - tenderAmount).abs();

  return Column(
    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SizedBox(height: 5),
      Text(
        label,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Color(0xFF212121),
          fontSize: 14,
          fontFamily: 'Inter',
          fontWeight: FontWeight.bold,
          height: 1.10,
          decoration: TextDecoration.none,
        ),
      ),
      SizedBox(height: 15),
      Container(
        alignment: Alignment.center,
        height: MediaQuery.of(context).size.height * 0.38,
        width: MediaQuery.of(context).size.width * 0.20,
        decoration: BoxDecoration(
          color: Color(0xFFDEE8FF),
          borderRadius: BorderRadius.circular(5),
          border: Border.all(color: Colors.white.withOpacity(0.5), width: 0.8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: 10),
            _buildColumnItem(
              "Balance Amount.",
              balanceAmount.toStringAsFixed(2),
              context,
              amount: balanceAmount,
            ),
            SizedBox(width: 20),
            _buildColumnItem(
              "Tender Amount.",
              tenderAmount.toStringAsFixed(2),
              context,
              amount: tenderAmount,
            ),
            SizedBox(width: 20),
            _buildColumnItem(
              "Change.",
              changeAmount.toStringAsFixed(2),
              context,
              amount: changeAmount,
            ),
          ],
        ),
      ),
    ],
  );
}

class NumberPad extends StatelessWidget {
  final Function(String) onKeyPressed;
  final String selectedPaymentMode;

  const NumberPad({
    super.key,
    required this.onKeyPressed,
    required this.selectedPaymentMode,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Left side 3x4 grid
        Expanded(
          flex: 3,
          child: Column(
            children: [
              _buildRow(["1", "2", "3"]),
              _buildRow(["4", "5", "6"]),
              _buildRow(["7", "8", "9"]),
              _buildRow(["00", ".", "0"]),
            ],
          ),
        ),
        // Right side: Delete, Clear, Pay button stacked vertically
        Expanded(
          flex: 1,
          child: Column(
            children: [
              _buildSideButton("⌫"),
              _buildSideButton("C"),
              Expanded(
                flex: 2,
                child: Padding(
                  padding: EdgeInsets.all(8.0),
                  child: GestureDetector(
                    onTap: () => onKeyPressed("Pay"),
                    child: Container(
                      decoration: BoxDecoration(
                        color:
                        selectedPaymentMode.isNotEmpty
                            ? Color(0xFFFE6464)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        "PAY",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color:
                          selectedPaymentMode.isNotEmpty
                              ? Colors.white
                              : Color(0xFF4C5F7D),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRow(List<String> labels) {
    return Expanded(
      child: Row(children: labels.map((label) => _buildButton(label)).toList()),
    );
  }

  Widget _buildButton(
      String label, {
        int flex = 1,
        Color? backgroundColor,
        Color? textColor,
        BoxBorder? border,
        bool isPayButton = false,
      }) {
    final bool isNumber = RegExp(r'^(\d+|00|\.)\$').hasMatch(label);

    return Expanded(
      flex: flex,
      child: Padding(
        padding: EdgeInsets.all(8.0),
        child: GestureDetector(
          onTap: () => onKeyPressed(label),
          child: Container(
            decoration: BoxDecoration(
              color: backgroundColor ?? Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: border,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              style: TextStyle(
                fontSize: isNumber ? 24 : 18,
                fontWeight: FontWeight.bold,
                color:
                textColor ??
                    (isNumber ? Color(0xFF4C5F7D) : Color(0xFF4C5F7D)),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSideButton(String label) {
    return Expanded(
      child: Padding(
        padding: EdgeInsets.all(8.0),
        child: GestureDetector(
          onTap: () => onKeyPressed(label),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4C5F7D),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Widget _buildPaymentDiscountItem(BuildContext context) {
  return Column(
    children: [
      Container(
        height: MediaQuery.of(context).size.height * 0.37,
        width: MediaQuery.of(context).size.width * 0.20,
        decoration: BoxDecoration(
          color: Color(0xFFDEE8FF),
          borderRadius: BorderRadius.circular(5),
          border: Border.all(color: Colors.white.withOpacity(0.5), width: 0.8),
        ),
        child: Padding(
          padding: const EdgeInsets.all(10), // 👈 space inside container
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, // 👈 align text left
            children: [
              Text(
                "Discount :",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF676C7D),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () {
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (BuildContext context) {
                          return Dialog(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            insetPadding: EdgeInsets.symmetric(
                              horizontal: 50,
                              vertical: 50,
                            ),
                            child: SizedBox(
                              width: 900,
                              height: 600,
                              child: DiscountPopup(),
                            ),
                          );
                        },
                      );
                    },
                    child: Container(
                      height: 50,
                      width: 180,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.grey.shade300,
                          width: 1,
                        ),
                      ),

                      child: Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              decoration: InputDecoration(
                                hintText: "Enter your discount ",
                                hintStyle: TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF636363),
                                ),
                                border:
                                InputBorder.none, // remove default border
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  Container(
                    height: 40,
                    width: 40,
                    decoration: BoxDecoration(
                      color: Color(0xFFFFFFFF), // 👈 background color
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Color(0xFFFFFFFF), width: 1),
                    ),
                    child: Center(
                      child: Image.asset(
                        "assets/images/delete_icon.png",
                        width: 20,
                        height: 20,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ],
              ),
              Text(
                "Coupon :",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF676C7D),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () {
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (BuildContext context) {
                          return Dialog(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            insetPadding: EdgeInsets.symmetric(
                              horizontal: 50,
                              vertical: 50,
                            ),
                            child: SizedBox(
                              width: 900,
                              height: 600,
                              child: Couponscreen(),
                            ),
                          );
                        },
                      );
                    },
                    child: Container(
                      height: 50,
                      width: 180,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.grey.shade300,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              decoration: InputDecoration(
                                hintText: "Enter your coupon code",
                                hintStyle: TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF636363),
                                ),
                                border:
                                InputBorder.none, // remove default border
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  Container(
                    height: 40,
                    width: 40,
                    decoration: BoxDecoration(
                      color: Color(0xFFFFFFFF),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Color(0xFFFFFFFF), width: 1),
                    ),
                    child: Center(
                      child: Image.asset(
                        "assets/images/delete_icon.png",
                        width: 20,
                        height: 20,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10),
              SizedBox(
                width: 230,
                height: 55,
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF1180A4),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    "Apply",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ],
  );
}

Widget _buildPaymentModeItem(
    String label,
    BuildContext context,
    String selectedOption,
    Function(String) onSelect,
    ) {
  final List<Map<String, String>> options = [
    {"label": "Cash", "image": "assets/icon/cash-01.png"},
    {"label": "Card", "image": "assets/icon/card-02(1).png"},
    {"label": "UPI", "image": "assets/icon/upi.png"},
    //{"label": "EBT", "image": "assets/images/EDA.png"},
  ];

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SizedBox(height: 5),
      Text(
        label,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Color(0xFF152148),
          fontSize: 12,
          fontFamily: 'Inter',
          fontWeight: FontWeight.bold,
          height: 1.10,
          decoration: TextDecoration.none,
        ),
      ),
      SizedBox(height: 10),
      Container(
        alignment: Alignment.center,
        height: MediaQuery.of(context).size.height * 0.10,
        width: MediaQuery.of(context).size.width * 0.40,
        decoration: BoxDecoration(
          color: Color(0xFFDEE8FF),
          borderRadius: BorderRadius.circular(5),
          border: Border.all(color: Colors.white.withOpacity(0.5), width: 0.8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children:
          options.map((option) {
            final bool isSelected = selectedOption == option['label'];
            return GestureDetector(
              onTap: () => onSelect(option['label']!),
              child: Container(
                margin: EdgeInsets.symmetric(vertical: 5),
                height: 35,
                width: 120,
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? Color(0xFFFCDFDC) : Color(0xFFFFFFFF),
                  borderRadius: BorderRadius.circular(0),
                  border:
                  isSelected
                      ? Border.all(color: Color(0xFFFE6464))
                      : null,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x10000000),
                      offset: Offset(0, 1),
                      blurRadius: 10,
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      option['image']!,
                      width: 40,
                      height: 40,
                      color:
                      isSelected
                          ? Color(0xFFFE6464)
                          : Color(0xFF4147D5),
                    ),
                    SizedBox(width: 0),
                    Text(
                      option['label']!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color:
                        isSelected
                            ? Color(0xFFFE6464)
                            : Color(0xFF4147D5),
                        fontSize: 13,
                        fontFamily: 'Montserrat',
                        fontWeight: FontWeight.w500,
                        height: 1.50,
                        letterSpacing: 0.60,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    ],
  );
}

Widget _buildColumnItem(
    String label,
    String insideText,
    BuildContext context, {
      num? amount,
    }) {
  // Determine color based on the value
  Color textColor;
  if (amount != null) {
    if (amount == (AppDatabase.instance.totalamount ?? 0.0)) {
      textColor = Color(0xFFFE6464);
    } else if (amount <= 2230.00) {
      textColor = Color(0xFF373535);
    } else {
      textColor = Color(0xFF318616);
    }
  } else {
    textColor = Color(0xFF373535);
  }
  return Padding(
    padding: const EdgeInsets.only(left: 15), // 👈 shift whole column to right
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start, // 👈 align to start
      children: [
        Text(
          label,
          style: TextStyle(
            color: Color(0xFF656161),
            fontSize: 15,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w500,
            decoration: TextDecoration.none,
          ),
        ),
        SizedBox(height: 10),
        Container(
          height: MediaQuery.of(context).size.height * 0.07,
          width: MediaQuery.of(context).size.width * 0.17,
          decoration: BoxDecoration(
            color: Color(0xFFF5F5F6),
            borderRadius: BorderRadius.circular(5),
            border: Border.all(
              color: Colors.white.withOpacity(0.5),
              width: 0.8,
            ),
          ),
          alignment: Alignment.centerLeft, // 👈 text starts at left
          padding: const EdgeInsets.symmetric(
            horizontal: 8,
          ), // small padding inside
          child: Text(
            insideText,
            style: TextStyle(
              color: textColor,
              fontSize: 15,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w500,
              decoration: TextDecoration.none,
            ),
            textAlign: TextAlign.start,
          ),
        ),

        // example extra widgets
        Column(children: [Container()]),
      ],
    ),
  );
}
