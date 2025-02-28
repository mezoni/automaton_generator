/// A node is aт element in a automaton.
///
/// A node is both a transition and an action element. That is, the node is a
/// multi-purpose element.
///
/// It is also necessary to note that the node does not represent a compound
/// structure. That is, for example, a sequence of nodes is not some kind of
/// formation that has an input node and an output node. The only indivisible
/// entity is the automaton itself, which is a set of nodes with one output and
/// many outputs.
///
/// The node has two branches, `accept` and `reject.
///
/// The 'accept' branch is the main sequence in the execution process of the
/// automaton.
///
/// The `reject` branch is an alternative sequence in the execution process of
/// the automaton.
///
/// The `reject` branch can also have `accept` and `reject` branches.
///
/// Only in the case of the final (leaf) nodes, the `reject` node indicates
/// that this node has no result.
///
/// The node is a template based unit. Template is a source code template.
///
/// The template uses two keys - `accept` and `reject` to indicate the direction
/// of branching.
class Node {
  /// The result od the computation
  String result;

  /// Code template
  String template;

  Node? _accept;

  Node? _parent;

  Node? _reject;

  Node({
    this.result = 'null',
    this.template = '{{accept}}{{reject}}',
  });

  ///Adds leaf nodes [accept] and [reject] to the corresponding branches.
  void addNodes({Node? accept, Node? reject}) {
    final acceptingNode = getAccept();
    if (acceptingNode == null) {
      if (accept != null) {
        setAccept(accept);
      }
    } else {
      acceptingNode.addNodes(accept: accept, reject: reject);
    }

    final rejectingNode = getReject();
    if (rejectingNode == null) {
      if (reject != null) {
        setReject(reject);
      }
    } else {
      rejectingNode.addNodes(accept: accept, reject: reject);
    }
  }

  /// Returns `accept` node.
  Node? getAccept() {
    return _accept;
  }

  /// Returns `parent` node.
  Node? getParent() {
    return _parent;
  }

  /// Returns `reject` node.
  Node? getReject() {
    return _reject;
  }

  /// Sets `accept` node.
  Node setAccept(Node accept) {
    _checkNotSet(_accept, 'accept');
    accept._setParent(this);
    return _accept = accept;
  }

  /// Sets `reject` node.
  Node setReject(Node reject) {
    _checkNotSet(_reject, 'reject');
    reject._setParent(this);
    return _reject = reject;
  }

  @override
  String toString() {
    return template;
  }

  void _checkNotSet(Object? object, String name) {
    if (object != null) {
      _errorUnableToSet(name);
    }
  }

  Never _errorUnableToSet(String name) {
    throw StateError("Unable to set '$name'");
  }

  void _setParent(Node parent) {
    _checkNotSet(_parent, 'parent');
    _parent = parent;
  }
}
