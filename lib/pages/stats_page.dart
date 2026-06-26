import 'package:flutter/material.dart';
import 'package:preference/types/types.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class StatsPage extends StatefulWidget {
  final GameState state;
  const StatsPage({super.key, required this.state});

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  GameState get s => widget.state;

  List<CartesianSeries<_Data, int>> _generateSeries() {
    return s.resHistory.entries.map((entry) {
      final String seriesName = entry.key;
      final List<int> values = entry.value;

      List<_Data> dataPoints = [];
      for (int i = 0; i < values.length; i++) {
        dataPoints.add(_Data(i, values[i]));
      }

      return LineSeries<_Data, int>(
        name: seriesName,
        dataSource: dataPoints,
        xValueMapper: (_Data data, _) => data.index,
        yValueMapper: (_Data data, _) => data.value,
        width: 5,
        markerSettings: const MarkerSettings(isVisible: true),
        dataLabelSettings: const DataLabelSettings(isVisible: true),
        animationDuration: 0,
        dataLabelMapper: (_Data data, int index) {
          if (index == dataPoints.length - 1) {
            return data.value.toString();
          }
          return '';
        },
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return SfCartesianChart(
      series: _generateSeries(),
      legend: const Legend(isVisible: true, position: LegendPosition.bottom, textStyle: TextStyle(
      fontSize: 30)),
      primaryYAxis: NumericAxis(
        plotBands: <PlotBand>[
          PlotBand(
            isVisible: true,
            start: 0,
            end: 0,
            borderWidth: 4,
            borderColor: Colors.red,
            dashArray: const <double>[5, 5],
          ),
        ],
      ),
      primaryXAxis: NumericAxis(decimalPlaces: 1, interval: 1),
      zoomPanBehavior: ZoomPanBehavior(
        enablePinching: true,
        enablePanning: true,
        zoomMode: ZoomMode
            .x,
      ),
    );
  }
}

class _Data {
  final int index;
  final int value;

  _Data(this.index, this.value);
}
