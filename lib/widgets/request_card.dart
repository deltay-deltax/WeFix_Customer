import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../data/models/service_request_model.dart';
import '../views/service_request_detail_screen.dart';

class RequestCard extends StatelessWidget {
  final ServiceRequestModel request;
  const RequestCard({super.key, required this.request});

  Color statusColor(String status) {
    switch (status) {
      case "in_progress":
      case "In Progress":
        return const Color(0xFFD1B7FF);
      case "waiting_for_confirmation":
      case "Pending":
        return const Color(0xFFFFE6B0);
      case "payment_done":
      case "Paid":
        return const Color(0xFFCFF6DF);
      case "payment_required":
      case "Payment":
        return const Color(0xFFFBD7DF);
      case "declined":
      case "Declined":
        return const Color(0xFFFBD7DF);
      case "payment_on_delivery":
        return Colors.purple.shade100;
      default:
        return Colors.grey.shade300;
    }
  }

  Color statusTextColor(String status) {
    switch (status) {
      case "in_progress":
      case "In Progress":
        return const Color(0xFF914DFF);
      case "waiting_for_confirmation":
      case "Pending":
        return Color(0xFFFFB500);
      case "payment_done":
      case "Paid":
        return Color(0xFF039855);
      case "payment_required":
      case "Payment":
        return Color(0xFFEB5685);
      case "declined":
      case "Declined":
        return Color(0xFFEB5685);
      case "payment_on_delivery":
        return Colors.purple.shade800;
      default:
        return Colors.black87;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool canPay = request.status == 'payment_required';
    final String formattedDate = request.createdAt != null
        ? DateFormat('d MMM yy').format(request.createdAt!)
        : '-';

    return Card(
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Device", style: TextStyle(color: Colors.grey[700])),
                    Text(
                      request.deviceType,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
                Text(formattedDate, style: TextStyle(color: Colors.grey[600])),
              ],
            ),
            SizedBox(height: 10),
            Text("Problem", style: TextStyle(color: Colors.grey[700])),
            Text(request.problem, style: TextStyle(fontSize: 15)),
            SizedBox(height: 12),
            Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor(request.status),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    request.status == 'payment_done' ? 'COMPLETED' : request.status.replaceAll('_', ' ').toUpperCase(),
                    style: TextStyle(
                      color: statusTextColor(request.status),
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
                Spacer(),
                Text("Amount", style: TextStyle(color: Colors.grey[600])),
                SizedBox(width: 8),
                Text(
                  '₹${request.amount}',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                SizedBox(width: 8),
                if (canPay)
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ServiceRequestDetailScreen(request: request),
                        ),
                      );
                    },
                    child: Text("Pay"),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      backgroundColor: const Color(0xFF2F74F9),
                      foregroundColor: Colors.white,
                      textStyle: TextStyle(fontWeight: FontWeight.bold),
                      minimumSize: Size(44, 34),
                    ),
                  )
                else
                  TextButton(
                    child: Text(
                      "View",
                      style: TextStyle(color: Color(0xFF2F74F9)),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ServiceRequestDetailScreen(request: request),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
