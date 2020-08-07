import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shop/exceptions/http_exception.dart';
import 'package:shop/providers/product.dart';
import 'package:shop/utils/constantes.dart';

class Products with ChangeNotifier {
  // O Firebase tem uma regra, onde deve-se colocar no final da URL
  // qqcoisa.json
  final String _baseUrl = '${Constantes.BASE_API_URL}/products';

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
    final response = await http.get("$_baseUrl.json");
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
      "$_baseUrl.json",
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

  Future<void> updateProduct(Product product) async {
    if (product == null || product.id == null) {
      return;
    }

    final index = _items.indexWhere((prod) => prod.id == product.id);

    if (index >= 0) {
      await http.patch(
        "$_baseUrl/${product.id}.json",
        body: json.encode({
          'title': product.title,
          'description': product.description,
          'price': product.price,
          'imageUrl': product.imageUrl,
        }),
      );
      _items[index] = product;

      notifyListeners();
    }
  }

  Future<void> deleteProduct(String id) async {
    final index = _items.indexWhere((prod) => prod.id == id);
    if (index >= 0) {
      final product = _items[index];

      _items.remove(product);
      notifyListeners();

      final response = await http.delete("$_baseUrl/${product.id}.json");

      if (response.statusCode >= 400) {
        _items.insert(index, product);
        notifyListeners();

        throw HttpException('Ocorreu um erro na exclusão do produto.');
      }
    }
  }
}
