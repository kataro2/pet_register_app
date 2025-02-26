class Pet {
  final String id;
  final String nome;
  final String tipo;
  final String raca;
  final int idade;
  final String userId;
  final String? imageUrl;

  Pet({
    required this.id,
    required this.nome,
    required this.tipo,
    required this.raca,
    required this.idade,
    required this.userId,
    this.imageUrl,
  });

  factory Pet.fromJson(Map<String, dynamic> json) {
    return Pet(
      id: json['id'],
      nome: json['nome'],
      tipo: json['tipo'],
      raca: json['raca'],
      idade: json['idade'],
      userId: json['user_id'],
      imageUrl: json['image_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nome': nome,
      'tipo': tipo,
      'raca': raca,
      'idade': idade,
      'user_id': userId,
      'image_url': imageUrl,
    };
  }
}