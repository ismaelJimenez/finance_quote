// Copyright 2019 Ismael Jiménez. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';

class YahooApiException implements Exception {
  final int statusCode;
  final String message;

  const YahooApiException({this.statusCode, this.message});
}

class Yahoo {
  static Future<Map<String, Map<String, dynamic>>> downloadRaw(
      List<String> symbols, http.Client client, Logger logger) async {
    final Map<String, Map<String, dynamic>> results =
        <String, Map<String, dynamic>>{};

    try {
      final Map<String, dynamic> quoteRaw = await _getRawQuote(symbols, client);

      // Search in the answer obtained the data corresponding to the symbols.
      // If requested symbol data is found add it to [portfolioQuotePrices].
      for (String symbol in symbols) {
        for (dynamic marketData in quoteRaw['result']) {
          if (marketData['symbol'] == symbol) {
            // ignore: avoid_as
            results[symbol] = marketData as Map<String, dynamic>;
          }
        }
      }
    } on YahooApiException catch (e) {
      logger.e(
          'YahooApiException{symbols: ${symbols.join(',')}, statusCode: ${e.statusCode}, message: ${e.message}}');
    }

    for (String symbol in symbols) {
      if (!results.containsKey(symbol)) {
        logger.e('YahooApi: Symbol $symbol not found.');
      }
    }

    return results;
  }

  static Future<Map<String, dynamic>> _getRawQuote(
      List<String> symbols, http.Client client) async {
    final String symbolList = symbols.join(',');

    final String quoteUrl =
        'https://query1.finance.yahoo.com/v7/finance/quote?symbols=' +
            symbolList;
    try {
      final http.Response quoteRes = await client.get(quoteUrl);
      if (quoteRes != null &&
          quoteRes.statusCode == 200 &&
          quoteRes.body != null) {
        return parseRawQuote(quoteRes.body);
      } else {
        throw YahooApiException(
            statusCode: quoteRes?.statusCode, message: 'Invalid response.');
      }
    } on http.ClientException {
      throw const YahooApiException(message: 'Connection failed.');
    }
  }

  static Map<String, dynamic> parseRawQuote(String quoteResBody) {
    try {
      return const JsonDecoder().convert(quoteResBody)['quoteResponse']
          as Map<String, dynamic>;
    } catch (e) {
      throw const YahooApiException(
          statusCode: 200, message: 'Quote was not parseable.');
    }
  }

  static Map<String, String> parsePrice(Map<String, dynamic> rawQuote) {
    return <String, String>{
      'price': (rawQuote['regularMarketPrice'] as double).toStringAsFixed(2),
      'currency': (rawQuote['currency'] as String).toUpperCase(),
    };
  }
}