import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AjoutAvisForm extends StatefulWidget {
  final String restaurantId;
  const AjoutAvisForm({super.key, required this.restaurantId});

  @override
  State<AjoutAvisForm> createState() => _AjoutAvisFormState();
}

class _AjoutAvisFormState extends State<AjoutAvisForm> {
  final _formKey = GlobalKey<FormBuilderState>();
  final SupabaseClient supabase = Supabase.instance.client;
  bool _isLoading = false;

  Future<void> _submitForm() async {
    if (_formKey.currentState?.saveAndValidate() ?? false) {
      final formData = _formKey.currentState!.value;

      setState(() {
        _isLoading = true;
      });

      try {
        // Récupérer l'ID de l'utilisateur connecté
        final userId = supabase.auth.currentUser?.id;
        if (userId == null) {
          throw Exception('Utilisateur non connecté');
        }

        // Insérer l'avis dans la table 'avis' de Supabase
        await supabase.from('avis').insert({
          'id_resto': widget.restaurantId,
          'id_user': userId,
          'note': formData['Note'],
          'comment': formData['Commentaire'],
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Avis ajouté avec succès!')),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur: ${e.toString()}')),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajouter un avis'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: FormBuilder(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FormBuilderDropdown(
                  name: 'Note',
                  decoration: const InputDecoration(
                    labelText: 'Note',
                    border: OutlineInputBorder(),
                  ),
                  items: List.generate(5, (index) => index + 1)
                      .map((note) => DropdownMenuItem(
                    value: note,
                    child: Text('$note'),
                  ))
                      .toList(),
                  validator: FormBuilderValidators.compose([
                    FormBuilderValidators.required(),
                  ]),
                ),
                const SizedBox(height: 20),
                FormBuilderTextField(
                  name: 'Commentaire',
                  decoration: const InputDecoration(
                    labelText: 'Commentaire',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 5,
                  validator: FormBuilderValidators.compose([
                    FormBuilderValidators.required(),
                    FormBuilderValidators.maxLength(500),
                  ]),
                ),
                const SizedBox(height: 30),
                if (_isLoading)
                  const CircularProgressIndicator()
                else
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.brown.shade800,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    onPressed: _submitForm,
                    child: const Text('Ajouter l\'avis'),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}