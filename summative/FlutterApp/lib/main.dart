import 'package:material_ui/material_ui.dart';

import 'api.dart';
import 'fields.dart';

void main() => runApp(const PowerDrawApp());

class PowerDrawApp extends StatelessWidget {
  const PowerDrawApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Drone Power Draw',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.indigo),
      home: const PredictPage(),
    );
  }
}

class PredictPage extends StatefulWidget {
  const PredictPage({super.key});

  @override
  State<PredictPage> createState() => _PredictPageState();
}

class _PredictPageState extends State<PredictPage> {
  // One controller per text field, looked up by the input's JSON key
  final _controllers = {
    for (final field in inputFields) field.key: TextEditingController(),
  };
  // What the display area shows, and how
  String _result = 'Fill in every field, then tap Predict.';
  bool _isError = false;
  bool _isLoading = false;

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  /// Turns the text fields into the JSON body for /predict.
  /// The API does all the checking, so nothing is rejected here:
  /// - empty field: left out, so the API answers "Field required"
  /// - number field with text that isn't a number: sent as text,
  ///   so the API answers "Input should be a valid number"
  Map<String, Object> _buildBody() {
    final body = <String, Object>{};
    for (final field in inputFields) {
      final text = _controllers[field.key]!.text.trim();
      if (text.isEmpty) continue;
      final number = num.tryParse(text);
      // isFinite: "Infinity" and "NaN" parse as numbers but aren't valid JSON
      body[field.key] = field.isNumber && number != null && number.isFinite
          ? number
          : text;
    }
    return body;
  }

  Future<void> _predict() async {
    FocusScope.of(context).unfocus(); // hide the keyboard to show the result
    setState(() {
      _isLoading = true;
      _isError = false;
      _result = 'Predicting... the first request can take up to a minute.';
    });

    try {
      final watts = await predictPower(_buildBody());
      _result = 'Predicted power draw: ${watts.toStringAsFixed(2)} W';
    } on PredictionError catch (e) {
      _result = e.message;
      _isError = true;
    }
    if (!mounted) return; // the page was closed while waiting
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Drone Power Draw')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            for (final field in inputFields) ...[
              TextField(
                controller: _controllers[field.key],
                keyboardType: field.isNumber
                    ? const TextInputType.numberWithOptions(
                        decimal: true,
                        signed: true,
                      )
                    : TextInputType.text,
                // "Next" on the keyboard jumps to the next field, "Done" on the last one
                textInputAction: field == inputFields.last
                    ? TextInputAction.done
                    : TextInputAction.next,
                decoration: InputDecoration(
                  labelText: field.label,
                  helperText: field.help,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
            ],
            // Disabled (null) while a request is running, so it can't be sent twice
            FilledButton(
              onPressed: _isLoading ? null : _predict,
              child: const Text('Predict'),
            ),
            const SizedBox(height: 16),
            // Display area: the prediction, or a readable error in red
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _isError
                    ? colors.errorContainer
                    : colors.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _result,
                style: TextStyle(
                  color: _isError ? colors.onErrorContainer : colors.onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
