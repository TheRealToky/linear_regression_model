import 'dart:convert';

import 'package:material_ui/material_ui.dart';

import 'fields.dart';

void main() => runApp(const PowerDrawApp());

class PowerDrawApp extends StatelessWidget {
  const PowerDrawApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Drone Power Draw',
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
  String _result = 'Fill in every field, then tap Predict.';

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
      body[field.key] = field.isNumber ? (num.tryParse(text) ?? text) : text;
    }
    return body;
  }

  void _predict() {
    // Step 3 sends this body to the API; for now it is only shown
    setState(() => _result = jsonEncode(_buildBody()));
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
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: field.label,
                  helperText: field.help,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
            ],
            FilledButton(onPressed: _predict, child: const Text('Predict')),
            const SizedBox(height: 16),
            // Display area: the prediction or a readable error goes here
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colors.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(_result),
            ),
          ],
        ),
      ),
    );
  }
}
