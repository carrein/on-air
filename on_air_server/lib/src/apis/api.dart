import 'package:on_air_server/src/generated/protocol.dart';
import 'package:serverpod/serverpod.dart';

class RecipeEndpoint extends Endpoint {
  Future<Recipe> generateRecipe(Session session, String ingredients) async {
    final recipe = Recipe(
      author: 'Gemini',
      text:
          'Quick Pasta\n1. Boil 200 g pasta 8 min.\n2. Heat 2 tbsp oil, add $ingredients.\n3. Drain pasta, toss with veg, season, serve hot.',
      date: DateTime.now(),
      ingredients: ingredients,
    );
    return await Recipe.db.insertRow(session, recipe);
  }

  Future<List<Recipe>> getRecipes(Session session) async {
    // Get all the recipes from the database, sorted by date.
    return Recipe.db.find(
      session,
      orderBy: (t) => t.date,
      orderDescending: true,
    );
  }
}
