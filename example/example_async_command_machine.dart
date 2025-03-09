import 'dart:async';

void main(List<String> args) async {
  final commands = StreamController<String>();
  Audio(commands.stream);
  final commandList = [
    'turn_off',
    'turn_on',
    'volume_up',
    'volume_up',
    'volume_up',
    'volume_up',
    'volume_down',
    'good_buy',
    'turn_off',
  ];

  await for (final command in Stream.fromIterable(commandList)) {
    commands.add(command);
  }
}

class Audio {
  final Stream<String> commands;

  var power = false;

  int volume = 2;

  Audio(this.commands) {
    commands.listen(_onCommand);
  }

  void _onCommand(String command) {
    print('-' * 40);
    print(command);
    if (command == "turn_on") {
      if (!power) {
        power = true;
        volume = 2;
        print('power: $power, volume: $volume');
        return;
      }
      print('Command "turn_on" rejected');
      print('power: $power, volume: $volume');
      return;
    }
    if (command == "turn_off") {
      if (power) {
        power = false;
        volume = 0;
        print('power: $power, volume: $volume');
        return;
      }
      print('Command "turn_off" rejected');
      print('power: $power, volume: $volume');
      return;
    }
    if (command == "volume_up") {
      if (volume < 5 && power) {
        volume++;
        print('power: $power, volume: $volume');
        return;
      }
      print('Command "volume_up" rejected');
      print('power: $power, volume: $volume');
      return;
    }
    if (command == "volume_down") {
      if (volume > 0 && power) {
        volume--;
        print('power: $power, volume: $volume');
        return;
      }
      print('Command "volume_down" rejected');
      print('power: $power, volume: $volume');
      return;
    }
    print('Unknown command: $command');
    return;
  }
}
