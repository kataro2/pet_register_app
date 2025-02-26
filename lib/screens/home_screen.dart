import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/pet.dart';
import 'pet_details_screen.dart';  // Adicione esta linha

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Pet> _pets = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPets();
  }

Future<void> _loadPets() async {
  try {
    final userId = Supabase.instance.client.auth.currentUser?.id;

    if (userId == null) {
      print('Usuário não autenticado. Abortando a consulta.');
      setState(() => _isLoading = false);
      return;
    }

    print('Loading pets for user: $userId'); // Debug

    final response = await Supabase.instance.client
        .from('pets')
        .select()
        .eq('user_id', userId);

    print('Pets loaded: $response'); // Debug

    setState(() {
      _pets = (response as List).map((pet) => Pet.fromJson(pet)).toList();
      _isLoading = false;
    });
  } catch (e) {
    print('Erro ao carregar pets: $e'); // Debug
    setState(() => _isLoading = false);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Erro ao carregar os pets: ${e.toString()}'),
        backgroundColor: Colors.red,
      ),
    );
  }
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meus Pets'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await Supabase.instance.client.auth.signOut();
              if (!mounted) return;
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _pets.isEmpty
              ? const Center(child: Text('Nenhum pet cadastrado'))
              : ListView.builder(
                  itemCount: _pets.length,
                  itemBuilder: (context, index) {
                    final pet = _pets[index];
                    return ListTile(
                      leading: Hero(
                        tag: 'pet-${pet.id}',
                        child: pet.imageUrl != null
                            ? CircleAvatar(
                                backgroundImage: NetworkImage(pet.imageUrl!),
                              )
                            : const CircleAvatar(
                                child: Icon(Icons.pets),
                              ),
                      ),
                      title: Text(pet.nome),
                      subtitle: Text('${pet.tipo} - ${pet.raca}'),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PetDetailsScreen(pet: pet),
                          ),
                        );
                      },
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () {
                              Navigator.pushNamed(
                                context,
                                '/edit-pet',
                                arguments: pet,
                              );
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () => _deletePet(pet),
                          ),
                        ],
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.pushNamed(context, '/add-pet');
          if (result == true) {
            _loadPets(); // Recarrega a lista quando voltar da tela de adicionar
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _deletePet(Pet pet) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar exclusão'),
        content: const Text('Deseja realmente excluir este pet?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await Supabase.instance.client
            .from('pets')
            .delete()
            .match({'id': pet.id});
        
        setState(() {
          _pets.removeWhere((p) => p.id == pet.id);
        });
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao excluir o pet')),
        );
      }
    }
  }
}