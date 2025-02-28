import 'dart:collection';

void main(List<String> args) {
  final audio = Audio();
  final commands = [
    'turn_off',
    'turn_on',
    'volume_up',
    'volume_up',
    'volume_up',
    'volume_up',
    'volume_down',
  ];
  audio.commands.addAll(commands);
  audio.execute();
  commands.clear();
  commands.addAll([
    'good_buy',
    'turn_off',
  ]);
  audio.commands.addAll(commands);
  audio.execute();
}

class Audio {
  final Queue<String> commands = Queue();

  var power = false;

  int volume = 2;

  void execute() {
    while (commands.isNotEmpty) {
      final command = commands.removeFirst();
      print('*' * 40);
      print(command);
      {
        if (command == 'turn_on') {
          {
            if (!power) {
              power = true;
              volume = 2;
              print('power: $power, volume: $volume');
              continue;
            }
          }
          print("Command 'turn_on' rejected");
          continue;
        }
      }
      {
        if (command == 'turn_off') {
          {
            if (power) {
              power = false;
              print('power: $power, volume: $volume');
              continue;
            }
          }
          print("Command 'turn_off' rejected");
          continue;
        }
      }
      {
        if (command == 'volume_up') {
          {
            if (volume < 5 && power) {
              volume++;
              print('power: $power, volume: $volume');
              continue;
            }
          }
          print("Command 'volume_up' rejected");
          continue;
        }
      }
      {
        if (command == 'volume_down') {
          {
            if (volume > 0 && power) {
              volume--;
              print('power: $power, volume: $volume');
              continue;
            }
          }
          print("Command 'volume_down' rejected");
          continue;
        }
      }
      print('Unknown command: $command');
      continue;
    }
  }
}
