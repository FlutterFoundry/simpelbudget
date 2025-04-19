import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PeriodSelector extends StatefulWidget {
  final DateTime currentPeriodStart;
  final DateTime currentPeriodEnd;
  final int cutoffDay;
  final Function(int) onCutoffChanged;
  final VoidCallback onPreviousPeriod;
  final VoidCallback onNextPeriod;
  final bool canGoNext;

  const PeriodSelector({
    super.key,
    required this.currentPeriodStart,
    required this.currentPeriodEnd,
    required this.cutoffDay,
    required this.onCutoffChanged,
    required this.onPreviousPeriod,
    required this.onNextPeriod,
    required this.canGoNext,
  });

  @override
  _PeriodSelectorState createState() => _PeriodSelectorState();
}

class _PeriodSelectorState extends State<PeriodSelector> {
  bool _isEditingCutoff = false;
  late TextEditingController _cutoffController;

  @override
  void initState() {
    super.initState();
    _cutoffController = TextEditingController(
      text: widget.cutoffDay.toString(),
    );
  }

  @override
  void dispose() {
    _cutoffController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back_ios, size: 20),
                  onPressed: widget.onPreviousPeriod,
                  tooltip: 'Previous Period',
                  splashRadius: 24,
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        'Budget Period',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[700],
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        '${DateFormat('MMM d').format(widget.currentPeriodStart)} - ${DateFormat('MMM d').format(widget.currentPeriodEnd)}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.arrow_forward_ios, size: 20),
                  onPressed: widget.canGoNext ? widget.onNextPeriod : null,
                  tooltip: 'Next Period',
                  splashRadius: 24,
                  color: widget.canGoNext ? null : Colors.grey[400],
                ),
              ],
            ),
            SizedBox(height: 8),
            Divider(),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.date_range,
                  size: 16,
                  color: Theme.of(context).primaryColor,
                ),
                SizedBox(width: 8),
                Text(
                  'Monthly Cutoff Day:',
                  style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                ),
                SizedBox(width: 12),
                _isEditingCutoff
                    ? SizedBox(
                      width: 50,
                      child: TextField(
                        controller: _cutoffController,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        maxLength: 2,
                        decoration: InputDecoration(
                          counterText: "",
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 0,
                          ),
                          border: OutlineInputBorder(),
                        ),
                        onSubmitted: (value) {
                          _saveCutoffDay();
                        },
                      ),
                    )
                    : Text(
                      '${widget.cutoffDay}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                SizedBox(width: 8),
                IconButton(
                  icon: Icon(
                    _isEditingCutoff ? Icons.check : Icons.edit,
                    size: 18,
                  ),
                  onPressed: () {
                    if (_isEditingCutoff) {
                      _saveCutoffDay();
                    } else {
                      setState(() {
                        _isEditingCutoff = true;
                      });
                    }
                  },
                  tooltip: _isEditingCutoff ? 'Save' : 'Edit Cutoff Day',
                  splashRadius: 20,
                  padding: EdgeInsets.all(4),
                  constraints: BoxConstraints(minWidth: 32, minHeight: 32),
                ),
              ],
            ),
            SizedBox(height: 8),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Your budget period starts on day ${widget.cutoffDay} of each month and ends on day ${widget.cutoffDay - 1} of the next month.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _saveCutoffDay() {
    final newCutoffDay =
        int.tryParse(_cutoffController.text) ?? widget.cutoffDay;
    // Validate the input: cutoff day should be between 1 and 28
    final validCutoffDay = newCutoffDay.clamp(1, 28);

    if (validCutoffDay != newCutoffDay) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cutoff day must be between 1 and 28')),
      );
      _cutoffController.text = validCutoffDay.toString();
    }

    widget.onCutoffChanged(validCutoffDay);
    setState(() {
      _isEditingCutoff = false;
    });
  }
}
