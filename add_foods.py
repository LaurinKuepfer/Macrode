import re

file_path = 'c:/Project/Macrode/Macrode/Models/StarterDatabase.swift'
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

new_en = """
        StarterFood(name: "Mango", calories: 60, protein: 0.8, carbs: 15.0, fat: 0.4, category: "Fruits"),
        StarterFood(name: "Peach", calories: 39, protein: 0.9, carbs: 9.5, fat: 0.3, category: "Fruits"),
        StarterFood(name: "Grapes", calories: 69, protein: 0.7, carbs: 18.1, fat: 0.2, category: "Fruits"),
        StarterFood(name: "Pineapple", calories: 50, protein: 0.5, carbs: 13.1, fat: 0.1, category: "Fruits"),
        StarterFood(name: "Kiwi", calories: 61, protein: 1.1, carbs: 14.7, fat: 0.5, category: "Fruits"),
        StarterFood(name: "Melon", calories: 34, protein: 0.8, carbs: 8.2, fat: 0.2, category: "Fruits"),
        StarterFood(name: "Lettuce", calories: 15, protein: 1.4, carbs: 2.9, fat: 0.2, category: "Vegetables"),
        StarterFood(name: "Cauliflower", calories: 25, protein: 1.9, carbs: 5.0, fat: 0.3, category: "Vegetables"),
        StarterFood(name: "Zucchini", calories: 17, protein: 1.2, carbs: 3.1, fat: 0.3, category: "Vegetables"),
        StarterFood(name: "Eggplant", calories: 25, protein: 1.0, carbs: 5.9, fat: 0.2, category: "Vegetables"),
        StarterFood(name: "Mushroom", calories: 22, protein: 3.1, carbs: 3.3, fat: 0.3, category: "Vegetables"),
        StarterFood(name: "Green Beans", calories: 31, protein: 1.8, carbs: 7.0, fat: 0.2, category: "Vegetables"),
        StarterFood(name: "Asparagus", calories: 20, protein: 2.2, carbs: 3.9, fat: 0.1, category: "Vegetables"),
        StarterFood(name: "Cabbage", calories: 25, protein: 1.3, carbs: 5.8, fat: 0.1, category: "Vegetables"),
        StarterFood(name: "Pork (Raw)", calories: 242, protein: 27.0, carbs: 0.0, fat: 14.0, category: "Meat"),
        StarterFood(name: "Lamb (Raw)", calories: 294, protein: 25.0, carbs: 0.0, fat: 21.0, category: "Meat"),
        StarterFood(name: "Cod (Raw)", calories: 82, protein: 18.0, carbs: 0.0, fat: 0.7, category: "Meat"),
        StarterFood(name: "Tilapia (Raw)", calories: 96, protein: 20.0, carbs: 0.0, fat: 1.7, category: "Meat"),
        StarterFood(name: "Mackerel (Raw)", calories: 205, protein: 19.0, carbs: 0.0, fat: 14.0, category: "Meat"),
        StarterFood(name: "Pasta (Dry)", calories: 371, protein: 13.0, carbs: 74.0, fat: 1.5, category: "Carbs"),
        StarterFood(name: "Couscous (Dry)", calories: 376, protein: 12.8, carbs: 77.4, fat: 0.6, category: "Carbs"),
        StarterFood(name: "Cream", calories: 345, protein: 2.0, carbs: 2.8, fat: 37.0, category: "Dairy & Fats"),
        StarterFood(name: "Cream Cheese", calories: 342, protein: 5.9, carbs: 4.1, fat: 34.0, category: "Dairy & Fats"),
        StarterFood(name: "Cashews", calories: 553, protein: 18.2, carbs: 30.2, fat: 43.8, category: "Dairy & Fats"),
        StarterFood(name: "Peanuts", calories: 567, protein: 25.8, carbs: 16.1, fat: 49.2, category: "Dairy & Fats"),
        StarterFood(name: "Sunflower Seeds", calories: 584, protein: 20.8, carbs: 20.0, fat: 51.5, category: "Dairy & Fats"),
        StarterFood(name: "Coconut Oil", calories: 862, protein: 0.0, carbs: 0.0, fat: 100.0, category: "Dairy & Fats"),
        StarterFood(name: "Vegetable Oil", calories: 884, protein: 0.0, carbs: 0.0, fat: 100.0, category: "Dairy & Fats")"""

new_de = """
        StarterFood(name: "Mango", calories: 60, protein: 0.8, carbs: 15.0, fat: 0.4, category: "Fruits"),
        StarterFood(name: "Pfirsich", calories: 39, protein: 0.9, carbs: 9.5, fat: 0.3, category: "Fruits"),
        StarterFood(name: "Weintrauben", calories: 69, protein: 0.7, carbs: 18.1, fat: 0.2, category: "Fruits"),
        StarterFood(name: "Ananas", calories: 50, protein: 0.5, carbs: 13.1, fat: 0.1, category: "Fruits"),
        StarterFood(name: "Kiwi", calories: 61, protein: 1.1, carbs: 14.7, fat: 0.5, category: "Fruits"),
        StarterFood(name: "Melone", calories: 34, protein: 0.8, carbs: 8.2, fat: 0.2, category: "Fruits"),
        StarterFood(name: "Kopfsalat", calories: 15, protein: 1.4, carbs: 2.9, fat: 0.2, category: "Vegetables"),
        StarterFood(name: "Blumenkohl", calories: 25, protein: 1.9, carbs: 5.0, fat: 0.3, category: "Vegetables"),
        StarterFood(name: "Zucchini", calories: 17, protein: 1.2, carbs: 3.1, fat: 0.3, category: "Vegetables"),
        StarterFood(name: "Aubergine", calories: 25, protein: 1.0, carbs: 5.9, fat: 0.2, category: "Vegetables"),
        StarterFood(name: "Champignons", calories: 22, protein: 3.1, carbs: 3.3, fat: 0.3, category: "Vegetables"),
        StarterFood(name: "Grüne Bohnen", calories: 31, protein: 1.8, carbs: 7.0, fat: 0.2, category: "Vegetables"),
        StarterFood(name: "Spargel", calories: 20, protein: 2.2, carbs: 3.9, fat: 0.1, category: "Vegetables"),
        StarterFood(name: "Kohl", calories: 25, protein: 1.3, carbs: 5.8, fat: 0.1, category: "Vegetables"),
        StarterFood(name: "Schweinefleisch (Roh)", calories: 242, protein: 27.0, carbs: 0.0, fat: 14.0, category: "Meat"),
        StarterFood(name: "Lamm (Roh)", calories: 294, protein: 25.0, carbs: 0.0, fat: 21.0, category: "Meat"),
        StarterFood(name: "Kabeljau (Roh)", calories: 82, protein: 18.0, carbs: 0.0, fat: 0.7, category: "Meat"),
        StarterFood(name: "Tilapia (Roh)", calories: 96, protein: 20.0, carbs: 0.0, fat: 1.7, category: "Meat"),
        StarterFood(name: "Makrele (Roh)", calories: 205, protein: 19.0, carbs: 0.0, fat: 14.0, category: "Meat"),
        StarterFood(name: "Nudeln (Trocken)", calories: 371, protein: 13.0, carbs: 74.0, fat: 1.5, category: "Carbs"),
        StarterFood(name: "Couscous (Trocken)", calories: 376, protein: 12.8, carbs: 77.4, fat: 0.6, category: "Carbs"),
        StarterFood(name: "Sahne", calories: 345, protein: 2.0, carbs: 2.8, fat: 37.0, category: "Dairy & Fats"),
        StarterFood(name: "Frischkäse", calories: 342, protein: 5.9, carbs: 4.1, fat: 34.0, category: "Dairy & Fats"),
        StarterFood(name: "Cashewkerne", calories: 553, protein: 18.2, carbs: 30.2, fat: 43.8, category: "Dairy & Fats"),
        StarterFood(name: "Erdnüsse", calories: 567, protein: 25.8, carbs: 16.1, fat: 49.2, category: "Dairy & Fats"),
        StarterFood(name: "Sonnenblumenkerne", calories: 584, protein: 20.8, carbs: 20.0, fat: 51.5, category: "Dairy & Fats"),
        StarterFood(name: "Kokosöl", calories: 862, protein: 0.0, carbs: 0.0, fat: 100.0, category: "Dairy & Fats"),
        StarterFood(name: "Pflanzenöl", calories: 884, protein: 0.0, carbs: 0.0, fat: 100.0, category: "Dairy & Fats")"""

new_es = """
        StarterFood(name: "Mango", calories: 60, protein: 0.8, carbs: 15.0, fat: 0.4, category: "Fruits"),
        StarterFood(name: "Melocotón", calories: 39, protein: 0.9, carbs: 9.5, fat: 0.3, category: "Fruits"),
        StarterFood(name: "Uvas", calories: 69, protein: 0.7, carbs: 18.1, fat: 0.2, category: "Fruits"),
        StarterFood(name: "Piña", calories: 50, protein: 0.5, carbs: 13.1, fat: 0.1, category: "Fruits"),
        StarterFood(name: "Kiwi", calories: 61, protein: 1.1, carbs: 14.7, fat: 0.5, category: "Fruits"),
        StarterFood(name: "Melón", calories: 34, protein: 0.8, carbs: 8.2, fat: 0.2, category: "Fruits"),
        StarterFood(name: "Lechuga", calories: 15, protein: 1.4, carbs: 2.9, fat: 0.2, category: "Vegetables"),
        StarterFood(name: "Coliflor", calories: 25, protein: 1.9, carbs: 5.0, fat: 0.3, category: "Vegetables"),
        StarterFood(name: "Calabacín", calories: 17, protein: 1.2, carbs: 3.1, fat: 0.3, category: "Vegetables"),
        StarterFood(name: "Berenjena", calories: 25, protein: 1.0, carbs: 5.9, fat: 0.2, category: "Vegetables"),
        StarterFood(name: "Champiñones", calories: 22, protein: 3.1, carbs: 3.3, fat: 0.3, category: "Vegetables"),
        StarterFood(name: "Judías Verdes", calories: 31, protein: 1.8, carbs: 7.0, fat: 0.2, category: "Vegetables"),
        StarterFood(name: "Espárragos", calories: 20, protein: 2.2, carbs: 3.9, fat: 0.1, category: "Vegetables"),
        StarterFood(name: "Col", calories: 25, protein: 1.3, carbs: 5.8, fat: 0.1, category: "Vegetables"),
        StarterFood(name: "Cerdo (Crudo)", calories: 242, protein: 27.0, carbs: 0.0, fat: 14.0, category: "Meat"),
        StarterFood(name: "Cordero (Crudo)", calories: 294, protein: 25.0, carbs: 0.0, fat: 21.0, category: "Meat"),
        StarterFood(name: "Bacalao (Crudo)", calories: 82, protein: 18.0, carbs: 0.0, fat: 0.7, category: "Meat"),
        StarterFood(name: "Tilapia (Crudo)", calories: 96, protein: 20.0, carbs: 0.0, fat: 1.7, category: "Meat"),
        StarterFood(name: "Caballa (Crudo)", calories: 205, protein: 19.0, carbs: 0.0, fat: 14.0, category: "Meat"),
        StarterFood(name: "Pasta (Seca)", calories: 371, protein: 13.0, carbs: 74.0, fat: 1.5, category: "Carbs"),
        StarterFood(name: "Cuscús (Seco)", calories: 376, protein: 12.8, carbs: 77.4, fat: 0.6, category: "Carbs"),
        StarterFood(name: "Nata", calories: 345, protein: 2.0, carbs: 2.8, fat: 37.0, category: "Dairy & Fats"),
        StarterFood(name: "Queso Crema", calories: 342, protein: 5.9, carbs: 4.1, fat: 34.0, category: "Dairy & Fats"),
        StarterFood(name: "Anacardos", calories: 553, protein: 18.2, carbs: 30.2, fat: 43.8, category: "Dairy & Fats"),
        StarterFood(name: "Cacahuetes", calories: 567, protein: 25.8, carbs: 16.1, fat: 49.2, category: "Dairy & Fats"),
        StarterFood(name: "Semillas de Girasol", calories: 584, protein: 20.8, carbs: 20.0, fat: 51.5, category: "Dairy & Fats"),
        StarterFood(name: "Aceite de Coco", calories: 862, protein: 0.0, carbs: 0.0, fat: 100.0, category: "Dairy & Fats"),
        StarterFood(name: "Aceite Vegetal", calories: 884, protein: 0.0, carbs: 0.0, fat: 100.0, category: "Dairy & Fats")"""

new_fr = """
        StarterFood(name: "Mangue", calories: 60, protein: 0.8, carbs: 15.0, fat: 0.4, category: "Fruits"),
        StarterFood(name: "Pêche", calories: 39, protein: 0.9, carbs: 9.5, fat: 0.3, category: "Fruits"),
        StarterFood(name: "Raisins", calories: 69, protein: 0.7, carbs: 18.1, fat: 0.2, category: "Fruits"),
        StarterFood(name: "Ananas", calories: 50, protein: 0.5, carbs: 13.1, fat: 0.1, category: "Fruits"),
        StarterFood(name: "Kiwi", calories: 61, protein: 1.1, carbs: 14.7, fat: 0.5, category: "Fruits"),
        StarterFood(name: "Melon", calories: 34, protein: 0.8, carbs: 8.2, fat: 0.2, category: "Fruits"),
        StarterFood(name: "Laitue", calories: 15, protein: 1.4, carbs: 2.9, fat: 0.2, category: "Vegetables"),
        StarterFood(name: "Chou-fleur", calories: 25, protein: 1.9, carbs: 5.0, fat: 0.3, category: "Vegetables"),
        StarterFood(name: "Courgette", calories: 17, protein: 1.2, carbs: 3.1, fat: 0.3, category: "Vegetables"),
        StarterFood(name: "Aubergine", calories: 25, protein: 1.0, carbs: 5.9, fat: 0.2, category: "Vegetables"),
        StarterFood(name: "Champignons", calories: 22, protein: 3.1, carbs: 3.3, fat: 0.3, category: "Vegetables"),
        StarterFood(name: "Haricots Verts", calories: 31, protein: 1.8, carbs: 7.0, fat: 0.2, category: "Vegetables"),
        StarterFood(name: "Asperges", calories: 20, protein: 2.2, carbs: 3.9, fat: 0.1, category: "Vegetables"),
        StarterFood(name: "Chou", calories: 25, protein: 1.3, carbs: 5.8, fat: 0.1, category: "Vegetables"),
        StarterFood(name: "Porc (Cru)", calories: 242, protein: 27.0, carbs: 0.0, fat: 14.0, category: "Meat"),
        StarterFood(name: "Agneau (Cru)", calories: 294, protein: 25.0, carbs: 0.0, fat: 21.0, category: "Meat"),
        StarterFood(name: "Cabillaud (Cru)", calories: 82, protein: 18.0, carbs: 0.0, fat: 0.7, category: "Meat"),
        StarterFood(name: "Tilapia (Cru)", calories: 96, protein: 20.0, carbs: 0.0, fat: 1.7, category: "Meat"),
        StarterFood(name: "Maquereau (Cru)", calories: 205, protein: 19.0, carbs: 0.0, fat: 14.0, category: "Meat"),
        StarterFood(name: "Pâtes (Sèches)", calories: 371, protein: 13.0, carbs: 74.0, fat: 1.5, category: "Carbs"),
        StarterFood(name: "Couscous (Sec)", calories: 376, protein: 12.8, carbs: 77.4, fat: 0.6, category: "Carbs"),
        StarterFood(name: "Crème", calories: 345, protein: 2.0, carbs: 2.8, fat: 37.0, category: "Dairy & Fats"),
        StarterFood(name: "Fromage à Tartiner", calories: 342, protein: 5.9, carbs: 4.1, fat: 34.0, category: "Dairy & Fats"),
        StarterFood(name: "Noix de Cajou", calories: 553, protein: 18.2, carbs: 30.2, fat: 43.8, category: "Dairy & Fats"),
        StarterFood(name: "Cacahuètes", calories: 567, protein: 25.8, carbs: 16.1, fat: 49.2, category: "Dairy & Fats"),
        StarterFood(name: "Graines de Tournesol", calories: 584, protein: 20.8, carbs: 20.0, fat: 51.5, category: "Dairy & Fats"),
        StarterFood(name: "Huile de Coco", calories: 862, protein: 0.0, carbs: 0.0, fat: 100.0, category: "Dairy & Fats"),
        StarterFood(name: "Huile Végétale", calories: 884, protein: 0.0, carbs: 0.0, fat: 100.0, category: "Dairy & Fats")"""


content = re.sub(r'(private static let foodsEN: \[StarterFood\] = \[[\s\S]*?)(    \])', lambda m: m.group(1) + ",\n" + new_en + "\n" + m.group(2), content, count=1)
content = re.sub(r'(private static let foodsDE: \[StarterFood\] = \[[\s\S]*?)(    \])', lambda m: m.group(1) + ",\n" + new_de + "\n" + m.group(2), content, count=1)
content = re.sub(r'(private static let foodsES: \[StarterFood\] = \[[\s\S]*?)(    \])', lambda m: m.group(1) + ",\n" + new_es + "\n" + m.group(2), content, count=1)
content = re.sub(r'(private static let foodsFR: \[StarterFood\] = \[[\s\S]*?)(    \])', lambda m: m.group(1) + ",\n" + new_fr + "\n" + m.group(2), content, count=1)

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)
