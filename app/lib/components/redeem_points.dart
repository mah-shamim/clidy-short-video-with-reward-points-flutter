import 'package:flutter/material.dart';

class RedeemPointsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Dark background color
      appBar: AppBar(
        title: const Text('Withdraw'),
        backgroundColor: Colors.black, // Dark background for AppBar
        foregroundColor: Colors.white, // White text color
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Container showing available coins
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24.0),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.pink, Color(0xFF4A00E0)], // Purple/blue gradient
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20.0),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    'Available Coin',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '150', // Updated available coin amount
                    style: TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 6.0, horizontal: 12.0),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                    child: const Text(
                      '1000 Coin = ₹ 1.00', // Updated conversion rate
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            // Field to enter withdrawal amount
            const Text(
              'Enter Coin',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              decoration: BoxDecoration(
                color: Colors.grey[850], // Dark gray background for input field
                borderRadius: BorderRadius.circular(10.0),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.monetization_on,
                    color: Colors.amber,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      style: const TextStyle(color: Colors.white),
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: 'Enter withdraw coin...',
                        hintStyle: TextStyle(color: Colors.white54),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '*Minimum Withdraw 10,000 Coins', // Updated minimum withdrawal requirement
              style: TextStyle(fontSize: 12, color: Colors.redAccent),
            ),
            const SizedBox(height: 24),
            // Payment method selection
            const Text(
              'Select Payment Gateway',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              decoration: BoxDecoration(
                color: Colors.grey[850],
                borderRadius: BorderRadius.circular(10.0),
              ),
              child: DropdownButton<String>(
                dropdownColor: Colors.grey[900],
                hint: const Text(
                  'Select Payment Gateway',
                  style: TextStyle(color: Colors.white54),
                ),
                icon: const Icon(Icons.arrow_drop_down, color: Colors.white70),
                isExpanded: true,
                underline: Container(), // Removes underline
                onChanged: (String? newValue) {
                  // Payment method selection logic
                },
                items: <String>['Paypal', 'Bank Transfer', 'UPI']
                    .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(
                      value,
                      style: const TextStyle(color: Colors.white),
                    ),
                  );
                }).toList(),
              ),
            ),
            const Spacer(), // Pushes the button to the bottom of the screen
            // Withdraw button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30.0),
                    ),
                    backgroundColor: Colors.pink // Same color as the gradient
                ),
                onPressed: () {
                  // Withdraw logic with minimum requirement check
                  final int availableCoins = 150; // Your current available coins
                  final int minimumWithdrawAmount = 10000;

                  if (availableCoins < minimumWithdrawAmount) {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: const Text('Insufficient Points'),
                          content: const Text(
                            'The minimum withdraw amount is 10,000 coins, and you do not have enough coins.',
                          ),
                          actions: <Widget>[
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                              child: const Text('OK'),
                            ),
                          ],
                        );
                      },
                    );
                  } else {
                    // Implement successful withdrawal logic here
                  }
                },
                child: const Text(
                  'Withdraw',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
