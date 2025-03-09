void main(List<String> args) {
  final door = DoorMachine((sm, cmd) {
    throw StateError('''
Unable to move to next state.
State machine: $sm
State: ${sm.state}
Command: $cmd
''');
  });

  door.addListener((command, previous, current) {
    if (command == DoorCommand.open) {
      final now = DateTime.now();
      print('Hello, I am a door watcher, the door was open at $now');
    }
  });

  door.addListener((command, previous, current) {
    print(
        "Move from '${previous.name}' state to '${current.name}' state using '${command.name}' command");
  });

  door.addListener((command, previous, current) {
    if (command == DoorCommand.close) {
      print('Good bye!');
    }
  });

  door.moveNext(DoorCommand.close);
  door.moveNext(DoorCommand.open);
  door.moveNext(DoorCommand.close);
  door.moveNext(DoorCommand.lock);
  door.moveNext(DoorCommand.unlock);
  door.moveNext(DoorCommand.open);
}

class DoorMachine {
  void Function(DoorMachine machine, DoorCommand command) onError;

  final _listeners = <void Function(
    DoorCommand command,
    DoorState previous,
    DoorState current,
  )>[];

  DoorState _state = DoorState.closed;

  DoorMachine(this.onError);

  DoorState get state => _state;

  void addListener(
      void Function(
        DoorCommand command,
        DoorState previous,
        DoorState current,
      ) listener) {
    if (_listeners.contains(listener)) {
      _listeners.remove(listener);
    }

    _listeners.add(listener);
  }

  void moveNext(DoorCommand command) {
    if (_state == DoorState.closed) {
      if (command == DoorCommand.open) {
        _setState(command, _state, DoorState.open);
        return;
      }
      if (command == DoorCommand.lock) {
        _setState(command, _state, DoorState.locked);
        return;
      }
    }
    if (_state == DoorState.open) {
      if (command == DoorCommand.close) {
        _setState(command, _state, DoorState.closed);
        return;
      }
    }
    if (_state == DoorState.locked) {
      if (command == DoorCommand.unlock) {
        _setState(command, _state, DoorState.closed);
        return;
      }
    }
    onError(this, command);
  }

  void removeListener(
      void Function(
        DoorCommand command,
        DoorState previous,
        DoorState current,
      ) listener) {
    _listeners.remove(listener);
  }

  void _setState(DoorCommand command, DoorState previous, DoorState current) {
    _state = current;
    for (final listener in _listeners.toList()) {
      listener(command, previous, current);
    }
  }
}

enum DoorCommand { close, lock, open, unlock }

enum DoorState { closed, locked, open }
