import 'package:flutter/material.dart';
import 'package:trainlog_app/widgets/logo_bar_chart.dart';

class StatisticsPage extends StatelessWidget {
  const StatisticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: EdgeInsetsGeometry.all(20),
        child: LogoBarChart(
          images: List.generate(10, (i) => Icon(Icons.train)), // Replace with your logos
          values: [130, 70, 55, 45, 40, 20, 15, 10, 10, 60],
          strippedValues: [0, 0, 10, 0, 5, 0, 0, 0, 0, 20],
          valuesTitles: [
            'JR East', 'JR West', 'SNCF', 'JR Central', 'JR Kyushu',
            'Keisei', 'Keihan', 'Seibu', 'DB', 'Other'
          ],
          horizontalAxisTitle: "Kilometers",
          //colors: List.generate(10, (i) => Colors.lightBlue),
          color: Colors.lightBlue,
        ),
      ),
    );
  }
}
