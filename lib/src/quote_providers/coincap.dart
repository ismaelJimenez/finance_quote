// Copyright 2019 Ismael Jiménez. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';

class CoincapApiException implements Exception {
  final int statusCode;
  final String message;

  const CoincapApiException({this.statusCode, this.message});
}

class Coincap {
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
        if (quoteRaw != null && quoteRaw.isNotEmpty) {
          results[symbol] = quoteRaw;
        }
      } on CoincapApiException catch (e) {
        logger.e(
            'CoincapApiException{symbol: $symbol, statusCode: ${e.statusCode}, message: ${e.message}}');
      }
    });

    await Future.wait(futureQuotes);

    return results;
  }

  static Future<Map<String, dynamic>> _getRawQuote(
      String symbol, http.Client client) async {
    final String quoteUrl = 'https://api.coincap.io/v2/assets/' + symbol;
    try {
      final http.Response quoteRes = await client.get(quoteUrl);
      if (quoteRes != null &&
          quoteRes.statusCode == 200 &&
          quoteRes.body != null) {
        return parseRawQuote(quoteRes.body);
      } else {
        throw CoincapApiException(
            statusCode: quoteRes?.statusCode, message: 'Invalid response.');
      }
    } on http.ClientException {
      throw const CoincapApiException(message: 'Connection failed.');
    }
  }

  static Map<String, dynamic> parseRawQuote(String quoteResBody) {
    try {
      return const JsonDecoder().convert(quoteResBody)['data']
          as Map<String, dynamic>;
    } catch (e) {
      throw const CoincapApiException(
          statusCode: 200, message: 'Quote was not parseable.');
    }
  }


  static Map<String, String> parsePrice(Map<String, dynamic> rawQuote) {
    return <String, String>{
      'price': double.parse(rawQuote['priceUsd'] as String).toStringAsFixed(2),
      'currency': 'USD',
    };
  }
}
