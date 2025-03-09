# automaton_generator

An automaton generator is a code generator (codegen) for use in generators of converters, scanners, parsers, state machines, etc.

Version: 2.0.10

[![Pub Package](https://img.shields.io/pub/v/automaton_generator.svg)](https://pub.dev/packages/automaton_generator)
[![GitHub Issues](https://img.shields.io/github/issues/mezoni/automaton_generator.svg)](https://github.com/mezoni/automaton_generator/issues)
[![GitHub Forks](https://img.shields.io/github/forks/mezoni/automaton_generator.svg)](https://github.com/mezoni/automaton_generator/forks)
[![GitHub Stars](https://img.shields.io/github/stars/mezoni/automaton_generator.svg)](https://github.com/mezoni/automaton_generator/stargazers)
[![GitHub License](https://img.shields.io/badge/License-BSD_3--Clause-blue.svg)](https://raw.githubusercontent.com/mezoni/automaton_generator/main/LICENSE)

## What is an automaton generator?

An automaton generator is a code generator (codegen) for use in generators of converters, scanners, parsers, state machines, etc.  
It is a template-based branch code generator.  
More precisely, a generator of an automaton consisting of states.  
Each state is a computational unit and must necessarily define one of two (or usually both) template placeholders.  
These are the `acceptance` and `rejection` placeholders.  
They are specified in templates using special markers:

- `{{@accept}}`
- `{{@reject}}`

There are three kinds of states available for generating states:

- `Choice`
- `Sequence`
- `Operation`

The `Choice` state generates selective branches, where each branch is an `alternative`.  
These branches are ordered, meaning that the computations do not happen simultaneously, but they are performed in the order specified.  
The `Sequence` state generates sequential branches. The sequential branch is an indivisible alternative. If any element causes a failure, the entire sequence of computation will be rejected.  

The most important kind of state is `Operation`.  
The `Operation` state acts as a `transition` and as an `action`.  
That is, not a generator, but the source code in the template determines the `transition conditions`.  
With this approach to implementation, the generator does not create any restrictions on the implementation of the automaton logic.  

## What is the difference between a state and an automaton?

The `State` after code generation will contain placeholders (`{{@accept}}`, and/or `{{@reject}}`).  
In fact, at this point in time, the `State` is in an intermediate condition.  
It is ready for further use but it is not yet an automaton.  
The `State` is not yet an automaton, since an automaton implies the presence of acceptors.  
`Acceptor` is a `State` that transfers control to another computation process.  
In this condition, two actions can be performed on the `State`.

- Subsequent state code injection
- Finalization code injection (transformation into an `acceptor`)

Subsequent state code injection is the process of placing the source code of the subsequent `State` into the appropriate placeholder.  
That is, it is part of the process of building a code base based on templates with placeholders for nested code.  
In fact, the templates may seem strange because it is not entirely clear how such code can work.  

Example:

```text
if (condition) {
  {{@accept}}
}
{{@reject}}
```

Another, more complex, example, with a `failure registration` code and a `recovery` code.

```text
final {{pos}} = scanner.position;
if (condition) {
  {{@accept}}
} else {
  // failure registration
}
// Recovery
scanner.position = {{pos}};
{{@reject}}
```

Why will the `rejection` code never execute the code after the `acceptance` code has finished executing?  
The answer is very simple, the `acceptance` code will never return control to the `rejection` code  if `acceptance` branch of computation completes successfully.  
Otherwise (if the `acceptance` branch `rejects` computation), code execution will continue down until it reaches the lowest `rejection` point.  
During code generation, all intermediate `rejection` points will be removed, allowing alternative code to be executed.  
Thus, either a successful exit (`acceptance`) with transfer of control will occur anywhere or at the very bottom point of the computation the control will be transferred forcibly (without any result) to external (or outer) computation.  

Even a single `State` can be an `automaton` but to transform this `State` into an `automaton` it is necessary to `close` it.
That is, transforming it into an `acceptor`.  
It is possible to use `return`, `continue` or `break` statements as `acceptors`. Or `shared` variable assignment `statement` if it is necessary for the computation to descend to a lower point and make a branches based on the analysis of the variable value (an example can be found in the `mux` function in the [extra](https://github.com/mezoni/automaton_generator/blob/main/lib/extra.dart) library.).

It is not very convenient to `close` all `ending` states manually correctly, and therefore there is a special generator (`AutomatonGenerator`) and an auxiliary helper function `automaton` for this purpose. In fact, this is a wrapper for the generator.

## How to use this software?

For convenient code generation, it is not enough to use only states.  
For this purpose (and as an example of usage) the [extra](https://github.com/mezoni/automaton_generator/blob/main/lib/extra.dart) library has helper functions to simplify code generation.  
These are the most commonly used general-purpose computations.  
Below is a list of these functions:

- `automaton`
- `block`
- `functionBody`
- `many`
- `many1`
- `map`
- `mux`
- `optional`
- `procedureBody`
- `recognize`
- `skipMany`
- `skipMany1`

All of them, except for the `recognize` function, are context-free generators.  
The `recognize` function requires context parameters (`position` and `substring`), but can be used in most cases.  

## Example of a command machine

In order to reduce duplicate code, a `helper` library will be used in the examples. It is used exclusively to simplify code generation.  
Also, the need for such `helper` libraries arises because the automaton states are primitive and very limited objects. In fact, they should be considered as `instructions` (and data structures) of an `intermediate` language.

Below is the source code for the `helper` library.

{{@example/example_helper.dart}}

And the source code for a simple `command machine` generator.  
This is a free-form generator in its implementation approach.  

{{@example/example_command_machine_generator.dart}}

This free-form generator generates the following source code:

{{@example/example.dart}}

That is, without much effort, a simple `command machine` code generator was created.  

An example of a `command machine` in operation.

```text
----------------------------------------
turn_off
power: false, volume: 2
Command "turn_off" rejected
----------------------------------------
turn_on
power: true, volume: 2
----------------------------------------
volume_up
power: true, volume: 3
----------------------------------------
volume_up
power: true, volume: 4
----------------------------------------
volume_up
power: true, volume: 5
----------------------------------------
volume_up
power: true, volume: 5
Command "volume_up" rejected
----------------------------------------
volume_down
power: true, volume: 4
----------------------------------------
good_buy
Unknown command: good_buy
----------------------------------------
turn_off
power: false, volume: 0
```

Another way to implement such a generator.

- Using `TOML`
- Using `Stream`

{{@example/example_async_command_machine_generator.dart}}

This generator generates the following source code:

{{@example\example_async_command_machine.dart}}

## Example of a state machine

{{@example/example_state_machine_generator.dart}}

Source code of the generated state machine.

{{@example/example_state_machine.dart}}

An example of how this example works.

```text
Hello, I am a door watcher, the door was open at 2025-03-09 23:46:29.464238
Move from 'closed' state to 'open' state using 'open' command
Move from 'open' state to 'closed' state using 'close' command
Good bye!
Move from 'closed' state to 'locked' state using 'lock' command
Move from 'locked' state to 'closed' state using 'unlock' command
Hello, I am a door watcher, the door was open at 2025-03-09 23:46:29.469235
Move from 'closed' state to 'open' state using 'open' command
```

## More complex examples

More complex application examples will be provided later.  
