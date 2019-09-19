// Copyright 2019 Ismael Jiménez. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:intl/intl.dart';
import 'package:html/parser.dart' show parse;
import 'package:html/dom.dart';

class MorningstarEsApiException implements Exception {
  final int statusCode;
  final String message;

  const MorningstarEsApiException({this.statusCode, this.message});
}

class MorningstarEs {
  static Future<Map<String, Map<String, dynamic>>> downloadRaw(
      List<String> symbols, http.Client client, Logger logger) async {
    final Map<String, Map<String, dynamic>> results =
        <String, Map<String, dynamic>>{};

    // We are running the fetch of each price in parallel with Future.wait.
    // Here, we catch FinanceQuoteProviderApiExceptions so that one API exception
    // doesn't stop the whole fetch.
    final Iterable<Future<void>> futureQuotes =
        symbols.map<Future<void>>((String symbol) async {
      try {
        final Map<String, dynamic> quoteRaw =
            await _getRawQuote(symbol, client);
        if (quoteRaw.isNotEmpty) {
          results[symbol] = quoteRaw;
        }
      } on MorningstarEsApiException catch (e) {
        print(
            'FinanceQuote MorningstarEsApiException{symbol: $symbol, statusCode: ${e.statusCode}, message: ${e.message}}');
      }
    });

    await Future.wait(futureQuotes);

    return results;
  }

  static Future<Map<String, dynamic>> _getRawQuote(
      String symbol, http.Client client) async {
    final String quoteUrl =
        'http://tools.morningstar.es/es/stockreport/default.aspx?id=' + symbol;
    try {
      final http.Response quoteRes = await client.get(quoteUrl);
      if (quoteRes != null &&
          quoteRes.statusCode == 200 &&
          quoteRes.body != null) {
        return parseRawQuote(quoteRes.body);
      } else {
        throw MorningstarEsApiException(
            statusCode: quoteRes.statusCode, message: 'Invalid response.');
      }
    } on http.ClientException {
      throw const MorningstarEsApiException(message: 'Connection failed.');
    }
  }

  static Map<String, String> parseRawQuote(String quoteResBody) {
    final NumberFormat f = NumberFormat.decimalPattern('es_ES');

    try {
      final Document document = parse(quoteResBody);

      final double price = f
          .parse((document.querySelector('.price').nodes[0] as Text).data)
          .toDouble();

      final String currency =
          (document.querySelector('.priceInformation').nodes[4] as Text)
              .data
              .split(' | ')[1]
              .split('\n')[0]
              .trim();

      return <String, String>{
        'price': price.toStringAsFixed(2),
        'currency': currency.toUpperCase(),
      };
    } catch (e) {
      throw const MorningstarEsApiException(
          statusCode: 200, message: 'Quote was not parseable.');
    }
  }

  static Map<String, String> parsePrice(Map<String, dynamic> rawQuote) {
    return <String, String>{
      'price': rawQuote['price'] as String,
      'currency': rawQuote['currency'] as String,
    };
  }
}
