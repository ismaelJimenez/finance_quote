// Copyright 2019 Ismael Jiménez. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';

class BinanceApiException implements Exception {
  final int statusCode;
  final String message;

  const BinanceApiException({this.statusCode, this.message});
}

class Binance {
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
        if (quoteRaw != null && quoteRaw.isNotEmpty && !quoteRaw.containsKey('code')) {
          results[symbol] = quoteRaw;
        }
      } on BinanceApiException catch (e) {
        print(
            'FinanceQuote BinanceApiException{symbol: $symbol, statusCode: ${e.statusCode}, message: ${e.message}}');
      }
    });

    await Future.wait(futureQuotes);

    return results;
  }

  static Future<Map<String, dynamic>> _getRawQuote(
      String symbol, http.Client client) async {
    final String quoteUrl =
        'https://api.binance.com/api/v3/ticker/price?symbol=' + symbol;
    try {
      final http.Response quoteRes = await client.get(quoteUrl);
      if (quoteRes != null &&
          quoteRes.statusCode == 200 &&
          quoteRes.body != null) {
        return parseRawQuote(quoteRes.body);
      } else {
        throw BinanceApiException(
            statusCode: quoteRes?.statusCode, message: 'Invalid response.');
      }
    } on http.ClientException {
      throw const BinanceApiException(message: 'Connection failed.');
    }
  }

  static Map<String, dynamic> parseRawQuote(String quoteResBody) {
    try {
      return const JsonDecoder().convert(quoteResBody) as Map<String, dynamic>;
    } catch (e) {
      throw const BinanceApiException(
          statusCode: 200, message: 'Quote was not parseable.');
    }
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
