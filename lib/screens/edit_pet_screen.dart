import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../models/pet.dart';

class EditPetScreen extends StatefulWidget {
  const EditPetScreen({super.key});

  @override
  State<EditPetScreen> createState() => _EditPetScreenState();
}

class _EditPetScreenState extends State<EditPetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _racaController = TextEditingController();
  final _idadeController = TextEditingController();
  String _selectedTipo = 'Cachorro';
  File? _imageFile;
  String? _currentImageUrl;
  bool _isLoading = false;
  late Pet _pet;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _pet = ModalRoute.of(context)!.settings.arguments as Pet;
    _initializeFields();
  }

  void _initializeFields() {
    _nomeController.text = _pet.nome;
    _racaController.text = _pet.raca;
    _idadeController.text = _pet.idade.toString();
    _selectedTipo = _pet.tipo;
    _currentImageUrl = _pet.imageUrl;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Pet'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    shape: BoxShape.circle,
                  ),
                  child: _buildImageWidget(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nomeController,
                decoration: const InputDecoration(
                  labelText: 'Nome do Pet',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira o nome do pet';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedTipo,
                decoration: const InputDecoration(
                  labelText: 'Tipo',
                ),
                items: ['Cachorro', 'Gato'].map((String tipo) {
                  return DropdownMenuItem(
                    value: tipo,
                    child: Text(tipo),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedTipo = newValue!;
                  });
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _racaController,
                decoration: const InputDecoration(
                  labelText: 'Raça',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira a raça do pet';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _idadeController,
                decoration: const InputDecoration(
                  labelText: 'Idade',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira a idade do pet';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Por favor, insira um número válido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _submitForm,
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Salvar Alterações'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageWidget() {
    if (_imageFile != null) {
      return ClipOval(
        child: Image.file(
          _imageFile!,
          fit: BoxFit.cover,
        ),
      );
    } else if (_currentImageUrl != null) {
      return ClipOval(
        child: Image.network(
          _currentImageUrl!,
          fit: BoxFit.cover,
        ),
      );
    }
    return const Icon(Icons.add_a_photo, size: 50);
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image != null) {
      setState(() {
        _imageFile = File(image.path);
      });
    }
  }

Future<void> _submitForm() async {
  if (_formKey.currentState!.validate()) {
    setState(() => _isLoading = true);
    
    try {
      String? imageUrl = _currentImageUrl;

      if (_imageFile != null) {
        final bytes = await _imageFile!.readAsBytes();
        final fileExt = _imageFile!.path.split('.').last;
        final fileName = '${DateTime.now().toIso8601String()}.$fileExt';

        final response = await Supabase.instance.client.storage
            .from('pet-images')
            .uploadBinary(fileName, bytes);

        if (response.isNotEmpty) { 
          imageUrl = Supabase.instance.client.storage
              .from('pet-images')
              .getPublicUrl(fileName);
          print('Imagem salva com sucesso: $imageUrl');
        } else {
          print('Erro ao fazer upload da imagem.');
        }
      }

      final petUpdateData = {
        'nome': _nomeController.text,
        'tipo': _selectedTipo,
        'raca': _racaController.text,
        'idade': int.parse(_idadeController.text),
      };

      if (imageUrl != null) {
        petUpdateData['image_url'] = imageUrl;
      }

      final updateResponse = await Supabase.instance.client
          .from('pets')
          .update(petUpdateData)
          .match({'id': _pet.id})
          .select();

      if (updateResponse != null) {
        print('Resposta do Supabase: $updateResponse');
      } else {
        print('Erro: Resposta do Supabase é nula. Verifique se o ID do pet está correto.');
      }

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      print('Erro ao atualizar o pet: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao atualizar o pet')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }
}

  @override
  void dispose() {
    _nomeController.dispose();
    _racaController.dispose();
    _idadeController.dispose();
    super.dispose();
  }
}