import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants.dart';
import '../models/cube_solve.dart';

/// Responsável por ler e gravar, no SharedPreferences, os tempos do
/// CubeTimer e a imagem de fundo (em base64) escolhida pelo usuário.
class CubeSolvesRepository {
  Future<List<CubeSolve>> loadSolves() async {
    final prefs = await SharedPreferences.getInstance();
    final String? solvesJson = prefs.getString(PrefsKeys.cubeSolves);
    if (solvesJson == null) return [];

    final List<dynamic> decoded = jsonDecode(solvesJson);
    return decoded.map((json) => CubeSolve.fromJson(json)).toList();
  }

  Future<void> _saveAll(List<CubeSolve> solves) async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = jsonEncode(solves.map((s) => s.toJson()).toList());
    await prefs.setString(PrefsKeys.cubeSolves, encoded);
  }

  Future<void> addSolve(CubeSolve solve) async {
    final solves = await loadSolves();
    solves.add(solve);
    await _saveAll(solves);
  }

  Future<void> updatePenalty(String id, int penalty) async {
    final solves = await loadSolves();
    final index = solves.indexWhere((s) => s.id == id);
    if (index != -1) {
      final old = solves[index];
      solves[index] = CubeSolve(
        id: old.id,
        time: old.time,
        date: old.date,
        penalty: penalty,
      );
      await _saveAll(solves);
    }
  }

  Future<void> deleteSolve(String id) async {
    final solves = await loadSolves();
    solves.removeWhere((s) => s.id == id);
    await _saveAll(solves);
  }

  // --- Persistência da Imagem de Fundo do Cube Timer ---
  //
  // Guardamos a imagem já codificada em base64 (não um caminho de
  // arquivo): um "path" não existe no navegador (não há sistema de
  // arquivos) e também pode deixar de existir no celular/desktop se o
  // cache do seletor de arquivos for limpo. Guardando os bytes em si,
  // a imagem funciona da mesma forma em qualquer plataforma.

  Future<void> saveBackgroundImageBase64(String base64Image) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(PrefsKeys.cubeTimerBgImage, base64Image);
  }

  Future<String?> getBackgroundImageBase64() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(PrefsKeys.cubeTimerBgImage);
  }

  // --- Persistência da opção "Inspeção de 15s" ---

  Future<void> saveInspectionEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(PrefsKeys.cubeTimerInspectionEnabled, enabled);
  }

  Future<bool> getInspectionEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(PrefsKeys.cubeTimerInspectionEnabled) ?? false;
  }
}
