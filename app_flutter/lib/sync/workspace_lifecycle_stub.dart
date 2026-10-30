class WorkspaceLifecycle {
  WorkspaceLifecycle(this.onAvailable, this.onLock);
  final void Function(bool) onAvailable;
  final void Function() onLock;
  Future<void> start() async => onAvailable(true);
  void broadcastLock() {}
  void dispose() {}
}
