// Copyright 2019 Ismael Jiménez. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';

class Binance {
  static Future<Map<String, Map<String, dynamic>>> downloadRaw(
      List<String> symbols, http.Client client, Logger logger) async {
    final Map<String, Map<String, dynamic>> retrieved =
        <String, Map<String, dynamic>>{};

    for (String symbol in symbols) {
      try {
        final http.Response response = await client.get(
            'https://api.binance.com/api/v3/ticker/price?symbol=' + symbol);

        if (response != null && response.statusCode == 200) {
          final Map<String, dynamic> quoteData = const JsonDecoder()
              .convert(response.body) as Map<String, dynamic>;

          if (quoteData.isNotEmpty && !quoteData.containsKey('code')) {
            retrieved[symbol] = quoteData;
          }
        } else {
          logger.e('Failed to download Binance quote data for: ' + symbol);
        }
      } catch (e) {
        logger.e(
            'Exception caught while parsing downloaded Binance quote data for: ' +
                symbol);
      }
    }

    return retrieved;
  }

  static Map<String, String> parsePrice(Map<String, dynamic> rawQuote) {
    return <String, String>{
      'price': double.parse(rawQuote['price'] as String).toStringAsFixed(5),
      'currency': (rawQuote['symbol'] as String).contains('USDT')
          ? 'USD'
          : (rawQuote['symbol'] as String).substring(3),
    };
  }
}
