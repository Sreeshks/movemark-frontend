import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class AnomalyDetection extends StatefulWidget {
  const AnomalyDetection({Key? key}) : super(key: key);

  @override
  State<AnomalyDetection> createState() => _AnomalyDetectionState();
}

class _AnomalyDetectionState extends State<AnomalyDetection> {
  double _threshold = 0.5;
  List<dynamic> _anomalies = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchAnomalies();
  }

  Future<void> _fetchAnomalies() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await http.get(
        Uri.parse('https://movemark-backend.onrender.com/analytics/anomalies?anomaly_threshold=$_threshold'),
      );

      if (response.statusCode == 200) {
        setState(() {
          _anomalies = json.decode(response.body);
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Failed to fetch anomalies: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.yellow;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Anomaly Detection',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Threshold Control',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Adjust sensitivity (${(_threshold * 100).toStringAsFixed(1)}%)',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    Slider(
                      value: _threshold,
                      min: 0.0,
                      max: 1.0,
                      divisions: 20,
                      label: '${(_threshold * 100).toStringAsFixed(1)}%',
                      onChanged: (value) {
                        setState(() {
                          _threshold = value;
                        });
                      },
                      onChangeEnd: (value) {
                        _fetchAnomalies();
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_error != null)
              Center(
                child: Text(
                  _error!,
                  style: TextStyle(color: Colors.red),
                ),
              )
            else
              Expanded(
                child: Card(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: _anomalies.length,
                    itemBuilder: (context, index) {
                      final anomaly = _anomalies[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: ListTile(
                          title: Text(
                            anomaly['employee_name'],
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text('Type: ${anomaly['anomaly_type']}'),
                              Text('Description: ${anomaly['description']}'),
                              Text(
                                'Date: ${DateFormat('MMM dd, yyyy HH:mm').format(DateTime.parse(anomaly['detected_date']))}',
                              ),
                            ],
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _getSeverityColor(anomaly['severity']),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  anomaly['severity'],
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Score: ${(anomaly['anomaly_score'] * 100).toStringAsFixed(1)}%',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}