import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shop/providers/cart.dart';

import 'package:http/http.dart' as http;

class Order {
  final String id;
  final double total;
  final List<CartItem> products;
  final DateTime date;

  Order({
    this.id,
    this.total,
    this.products,
    this.date,
  });
}

class Orders with ChangeNotifier {
  final String _baseUrl = 'https://flutter-cod3r-3f1ac.firebaseio.com/orders';

  List<Order> _items = [];

  List<Order> get items {
    return [..._items];
  }

  int get itemsCount {
    return _items.length;
  }

  Future<void> addOrder(Cart cart) async {
    final date = DateTime.now();
    final response = await http.post("$_baseUrl.json",
        body: json.encode({
          'total': cart.totalAmount,
          'date': date.toIso8601String(),
          'products': cart.items.values
              .map((cartItem) => {
                    'id': cartItem.id,
                    'productId': cartItem.productId,
                    'title': cartItem.title,
                    'quantity': cartItem.quantity,
                    'price': cartItem.price,
                  })
              .toList()
        }));

    _items.insert(
        0,
        Order(
          id: json.decode(response.body)['name'],
          total: cart.totalAmount,
          date: date,
          products: cart.items.values.toList(),
        ));

    notifyListeners();
  }

  Future<void> loadOrders() async {
    List<Order> loadedItens = [];
    // se não informar o await o retorno do método http.get será um Future
    // e não um response, por isso deve-se informar o await
    // e informando o await temos um objeto do tipo Response
    final response = await http.get("$_baseUrl.json");
    Map<String, dynamic> data = json.decode(response.body);

    // print(data);

    if (data != null) {
      data.forEach((orderId, orderData) {
        loadedItens.add(Order(
            id: orderId,
            total: orderData['total'],
            date: DateTime.parse(orderData['date']),
            products: (orderData['products'] as List<dynamic>).map((item) {
              return CartItem(
                id: item['id'],
                productId: item['productId'],
                title: item['title'],
                quantity: item['quantity'],
                price: item['price'],
              );
            }).toList()));
      });
      notifyListeners();
    }

    _items = loadedItens.reversed.toList();

    // Foi necessário forçar esse retorno pois esse método (loadProducts)
    // estava sendo usado na product_overview_screen, e ele precisava do retorno
    // para funcionar corretamente.
    return Future.value();
  }
}
