/// One model input = one labelled text field on the form.
/// Keys, units and allowed values mirror `FlightInput` in API/prediction.py.
class InputField {
  const InputField(this.key, this.label, this.help, {this.isNumber = true});

  final String key; // JSON key the API expects
  final String label; // shown on the text field
  final String help; // allowed values, shown under the text field
  final bool isNumber; // numbers are sent as JSON numbers, the rest as text
}

const inputFields = [
  InputField('payload', 'Payload (g)', '0 to 750'),
  InputField('speed', 'Programmed speed (m/s)', '0 to 12'),
  InputField('wind_speed', 'Wind speed (m/s)', '0 to 20'),
  InputField('ground_speed', 'Ground speed (m/s)', '0 to 13'),
  InputField('velocity_z', 'Vertical speed (m/s)', '-5 to 6, + is up'),
  InputField('tilt_deg', 'Tilt (degrees)', '0 to 45'),
  InputField('height', 'Height above take-off (m)', '-15 to 120'),
  InputField('time', 'Time since logging started (s)', '0 to 450'),
  InputField('route', 'Route', 'R1, H or other', isNumber: false),
  InputField(
    'flight_phase',
    'Flight phase',
    'ground, climb, cruise, hover or descent',
    isNumber: false,
  ),
  InputField(
    'altitude',
    'Planned altitude (m)',
    '3, 25, 50, 75, 100 or 25-50-100-25',
    isNumber: false,
  ),
];
