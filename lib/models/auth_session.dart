class AuthSession {
  const AuthSession({required this.token, required this.owner});

  final String token;
  final AuthOwner owner;
}

class AuthOwner {
  const AuthOwner({required this.id, required this.name});

  final String id;
  final String name;
}
