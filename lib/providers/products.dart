import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shop/providers/product.dart';

class Products with ChangeNotifier {
  // O Firebase tem uma regra, onde deve-se colocar no final da URL
  // qqcoisa.json
  final String _url =
      'https://flutter-cod3r-3f1ac.firebaseio.com/products.json';

  List<Product> _items = [];

  List<Product> get items => [..._items];

  List<Product> get favoriteItems {
    return _items.where((prod) => prod.isFavorite).toList();
  }

  int get itemsCount {
    return _items.length;
  }

  Future<void> loadProducts() async {
    // se não informar o await o retorno do método http.get será um Future
    // e não um response, por isso deve-se informar o await
    // e informando o await temos um objeto do tipo Response
    final response = await http.get(_url);
    Map<String, dynamic> data = json.decode(response.body);

    _items.clear();

    print('\n\n\n\nTST');
    print(data);

    if (data != null) {
      data.forEach((productId, productData) {
        _items.add(
          Product(
            id: productId,
            title: productData['title'],
            description: productData['description'],
            price: productData['price'],
            imageUrl: productData['imageUrl'],
            isFavorite: productData['isFavorite'],
          ),
        );
      });
      notifyListeners();
    }

    // Foi necessário forçar esse retorno pois esse método (loadProducts)
    // estava sendo usado na product_overview_screen, e ele precisava do retorno
    // para funcionar corretamente.
    return Future.value();
  }

  // Uma função async, SEMPRE deverá retornar um Future
  Future<void> addProduct(Product newProduct) async {
    // uma instrução marcada como await espera o retorno de sua execução,
    // ai esse retorno pode ser atribuida a uma variável
    final response = await http.post(
      _url,
      //  json.encode: transforma um map em json
      body: json.encode({
        'title': newProduct.title,
        'description': newProduct.description,
        'price': newProduct.price,
        'imageUrl': newProduct.imageUrl,
        'isFavorite': newProduct.isFavorite
      }),
    );

    _items.add(
      Product(
        //id: Random().nextDouble().toString(),
        id: json.decode(response.body)['name'],
        title: newProduct.title,
        description: newProduct.description,
        price: newProduct.price,
        imageUrl: newProduct.imageUrl,
      ),
    );

    notifyListeners();
  }

  void updateProduct(Product product) {
    if (product == null || product.id == null) {
      return;
    }

    final index = _items.indexWhere((prod) => prod.id == product.id);

    if (index >= 0) {
      _items[index] = product;

      notifyListeners();
    }
  }

  void deleteProduct(String id) {
    final index = _items.indexWhere((prod) => prod.id == id);
    if (index >= 0) {
      _items.removeWhere((product) => product.id == id);

      notifyListeners();
    }
  }
}
