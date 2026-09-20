import 'package:flutter/material.dart';
import 'cube_timer/cube_timer_screen.dart';
import 'matter/matter_screen.dart';
import 'settings_screen.dart';
import 'tasks/tasks_screen.dart';

/// Tela principal do aplicativo NerdNote.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  static const List<Widget> _pages = [
    TasksScreen(),
    MatterScreen(),
    CubeTimerScreen(),
    SettingsScreen(),
  ];

  static const List<NavigationItem> _navigationItems = [
    NavigationItem(
      icon: Icons.task_alt_rounded,
      label: 'Tarefas',
    ),
    NavigationItem(
      icon: Icons.school_rounded,
      label: 'Matérias',
    ),
    NavigationItem(
      icon: Icons.view_in_ar_rounded,
      label: 'CubeTimer',
    ),
    NavigationItem(
      icon: Icons.settings_rounded,
      label: 'Ajustes',
    ),
  ];

  void _onItemTapped(int index) {
    if (_selectedIndex == index) return;

    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'NerdNote',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: colorScheme.surfaceContainerLow,
        elevation: 0,
      ),

      // IndexedStack mantém todas as páginas instanciadas (montadas) o
      // tempo todo, apenas trocando qual delas fica visível. Antes,
      // cada troca de aba destruía e recriava a página (AnimatedSwitcher
      // + KeyedSubtree), o que fazia o CubeTimerScreen perder o estado:
      // a imagem de fundo sumia e reaparecia com um "pisca" de ~1s
      // porque o widget inteiro era refeito do zero. Com IndexedStack,
      // a página do CubeTimer é criada uma única vez e só fica
      // escondida/mostrada, preservando a imagem e o cronômetro.
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),

      bottomNavigationBar: _buildAnimatedNavigationBar(
        context,
        colorScheme,
      ),
    );
  }

  Widget _buildAnimatedNavigationBar(
      BuildContext context,
      ColorScheme colorScheme,
      ) {
    return SafeArea(
      minimum: const EdgeInsets.only(
        left: 12,
        right: 12,
        bottom: 10,
        top: 8,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 6,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(26),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 18,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(
            _navigationItems.length,
                (index) {
              final item = _navigationItems[index];
              final isSelected = _selectedIndex == index;

              return Expanded(
                child: _AnimatedNavigationItem(
                  item: item,
                  isSelected: isSelected,
                  colorScheme: colorScheme,
                  onTap: () => _onItemTapped(index),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Modelo de cada item da navegação.
class NavigationItem {
  final IconData icon;
  final String label;

  const NavigationItem({
    required this.icon,
    required this.label,
  });
}

/// Item animado da barra de navegação.
class _AnimatedNavigationItem extends StatelessWidget {
  final NavigationItem item;
  final bool isSelected;
  final ColorScheme colorScheme;
  final VoidCallback onTap;

  const _AnimatedNavigationItem({
    required this.item,
    required this.isSelected,
    required this.colorScheme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final selectedColor = colorScheme.primary;
    final unselectedColor = colorScheme.onSurfaceVariant;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        margin: const EdgeInsets.symmetric(horizontal: 3),
        padding: const EdgeInsets.symmetric(
          horizontal: 4,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? selectedColor.withValues(alpha: 0.14)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedScale(
              scale: isSelected ? 1.12 : 1.0,
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutBack,
              child: Icon(
                item.icon,
                size: 24,
                color: isSelected
                    ? selectedColor
                    : unselectedColor,
              ),
            ),

            const SizedBox(height: 4),

            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              style: TextStyle(
                fontSize: isSelected ? 12 : 11,
                fontWeight: isSelected
                    ? FontWeight.bold
                    : FontWeight.w500,
                color: isSelected
                    ? selectedColor
                    : unselectedColor,
              ),
              child: Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),

            const SizedBox(height: 4),

            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              width: isSelected ? 20 : 0,
              height: 3,
              decoration: BoxDecoration(
                color: selectedColor,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ],
        ),
      ),
    );
  }
}