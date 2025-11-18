import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/color_utils.dart';
import '../../services/prompt_repository.dart';
import '../../domain/prompt.dart';
import '../../l10n/l10n_extensions.dart';

class AdminPromptsPage extends StatefulWidget {
  const AdminPromptsPage({super.key});

  @override
  State<AdminPromptsPage> createState() => _AdminPromptsPageState();
}

class _AdminPromptsPageState extends State<AdminPromptsPage> {
  final PromptRepository _promptRepository = PromptRepository();
  List<Prompt> _prompts = [];
  bool _isLoading = true;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _checkAdminStatus();
  }

  Future<void> _checkAdminStatus() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      setState(() {
        _isLoading = false;
        _isAdmin = false;
      });
      return;
    }

    try {
      final response = await Supabase.instance.client
          .from('users')
          .select('is_admin')
          .eq('id', userId)
          .single();

      final isAdmin = response['is_admin'] as bool? ?? false;

      setState(() {
        _isAdmin = isAdmin;
        _isLoading = false;
      });

      if (isAdmin) {
        await _loadPrompts();
      }
    } catch (e) {
      debugPrint('Error checking admin status: $e');
      setState(() {
        _isLoading = false;
        _isAdmin = false;
      });
    }
  }

  Future<void> _loadPrompts() async {
    try {
      await _promptRepository.init();
      final prompts = await _promptRepository.getAllPrompts();
      setState(() {
        _prompts = prompts;
      });
    } catch (e) {
      debugPrint('Error loading prompts: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.literal(
              es: 'Error al cargar los prompts',
              en: 'Error loading prompts',
            )),
            backgroundColor: AppColors.redAccent,
          ),
        );
      }
    }
  }

  void _showEditDialog(Prompt prompt) {
    final TextEditingController templateController =
        TextEditingController(text: prompt.template);
    final TextEditingController descriptionController =
        TextEditingController(text: prompt.description ?? '');

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: AppColors.darkBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 800, maxHeight: 700),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: adjustOpacity(AppColors.tealAccent, 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.edit,
                      color: AppColors.tealAccent,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.l10n.literal(
                            es: 'Editar Prompt',
                            en: 'Edit Prompt',
                          ),
                          style: GoogleFonts.poppins(
                            color: AppColors.whiteText,
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          prompt.key,
                          style: GoogleFonts.poppins(
                            color: AppColors.white60,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.white70),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                context.l10n.literal(
                  es: 'Descripción',
                  en: 'Description',
                ),
                style: GoogleFonts.poppins(
                  color: AppColors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: descriptionController,
                style: GoogleFonts.poppins(color: AppColors.whiteText),
                decoration: InputDecoration(
                  hintText: context.l10n.literal(
                    es: 'Descripción del prompt',
                    en: 'Prompt description',
                  ),
                  hintStyle: GoogleFonts.poppins(color: AppColors.white38),
                  filled: true,
                  fillColor: adjustOpacity(AppColors.whiteText, 0.05),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                context.l10n.literal(
                  es: 'Template',
                  en: 'Template',
                ),
                style: GoogleFonts.poppins(
                  color: AppColors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: TextField(
                  controller: templateController,
                  maxLines: null,
                  expands: true,
                  style: GoogleFonts.sourceCodePro(
                    color: AppColors.whiteText,
                    fontSize: 13,
                  ),
                  decoration: InputDecoration(
                    hintText: context.l10n.literal(
                      es: 'Template del prompt...',
                      en: 'Prompt template...',
                    ),
                    hintStyle:
                        GoogleFonts.sourceCodePro(color: AppColors.white38),
                    filled: true,
                    fillColor: adjustOpacity(AppColors.whiteText, 0.05),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      context.l10n.literal(es: 'Cancelar', en: 'Cancel'),
                      style: GoogleFonts.poppins(color: AppColors.white60),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () async {
                      await _savePrompt(
                        prompt.key,
                        templateController.text,
                      );
                      if (mounted) Navigator.of(context).pop();
                    },
                    icon: const Icon(Icons.save),
                    label: Text(
                      context.l10n.literal(es: 'Guardar', en: 'Save'),
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.tealAccent,
                      foregroundColor: AppColors.darkBackground,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _savePrompt(String key, String template) async {
    try {
      await _promptRepository.updatePrompt(key, template);
      await _loadPrompts();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.literal(
              es: 'Prompt actualizado correctamente',
              en: 'Prompt updated successfully',
            )),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error saving prompt: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.literal(
              es: 'Error al guardar el prompt',
              en: 'Error saving prompt',
            )),
            backgroundColor: AppColors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.darkBackground,
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.tealAccent),
        ),
      );
    }

    if (!_isAdmin) {
      return Scaffold(
        backgroundColor: AppColors.darkBackground,
        appBar: AppBar(
          backgroundColor: AppColors.darkSecondary,
          title: Text(
            context.l10n.literal(
              es: 'Acceso Denegado',
              en: 'Access Denied',
            ),
            style: GoogleFonts.poppins(color: AppColors.whiteText),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.lock_outline,
                color: AppColors.redAccent,
                size: 64,
              ),
              const SizedBox(height: 24),
              Text(
                context.l10n.literal(
                  es: 'No tienes permisos de administrador',
                  en: 'You do not have administrator permissions',
                ),
                style: GoogleFonts.poppins(
                  color: AppColors.white70,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: AppColors.darkSecondary,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: adjustOpacity(AppColors.tealAccent, 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.admin_panel_settings,
                color: AppColors.tealAccent,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              context.l10n.literal(
                es: 'Administrar Prompts',
                en: 'Manage Prompts',
              ),
              style: GoogleFonts.poppins(
                color: AppColors.whiteText,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.tealAccent),
            onPressed: _loadPrompts,
            tooltip: context.l10n.literal(
              es: 'Refrescar',
              en: 'Refresh',
            ),
          ),
        ],
      ),
      body: _prompts.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.inbox_outlined,
                    color: AppColors.white38,
                    size: 64,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    context.l10n.literal(
                      es: 'No hay prompts disponibles',
                      en: 'No prompts available',
                    ),
                    style: GoogleFonts.poppins(
                      color: AppColors.white60,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _prompts.length,
              itemBuilder: (context, index) {
                final prompt = _prompts[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.darkSecondary,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: adjustOpacity(AppColors.tealAccent, 0.2),
                    ),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _showEditDialog(prompt),
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: adjustOpacity(
                                      AppColors.tealAccent,
                                      0.15,
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.code,
                                    color: AppColors.tealAccent,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        prompt.key,
                                        style: GoogleFonts.poppins(
                                          color: AppColors.whiteText,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      if (prompt.description != null)
                                        Text(
                                          prompt.description!,
                                          style: GoogleFonts.poppins(
                                            color: AppColors.white60,
                                            fontSize: 13,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                const Icon(
                                  Icons.edit,
                                  color: AppColors.white38,
                                  size: 20,
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color:
                                    adjustOpacity(AppColors.whiteText, 0.05),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                prompt.template.length > 200
                                    ? '${prompt.template.substring(0, 200)}...'
                                    : prompt.template,
                                style: GoogleFonts.sourceCodePro(
                                  color: AppColors.white70,
                                  fontSize: 12,
                                  height: 1.5,
                                ),
                                maxLines: 4,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${context.l10n.literal(es: 'Actualizado', en: 'Updated')}: ${_formatDate(prompt.updatedAt)}',
                              style: GoogleFonts.poppins(
                                color: AppColors.white38,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
