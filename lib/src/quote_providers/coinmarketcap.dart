// Copyright 2019 Ismael Jiménez. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';

class CoinmarketcapApiException implements Exception {
  final int statusCode;
  final String message;

  const CoinmarketcapApiException({this.statusCode, this.message});
}

class Coinmarketcap {
  static Future<Map<String, Map<String, dynamic>>> downloadRaw(
      List<String> symbols, http.Client client, Logger logger) async {
    int _start = 1;
    const int _searchStep = 49;
    const int _numberOfCoins = 100;
    List<String> _symbolsRetrieved;
    final Map<String, Map<String, dynamic>> results =
        <String, Map<String, dynamic>>{};

    do {
      try {
        _symbolsRetrieved = <String>[];

        final Map<String, dynamic> quoteRaw =
            await _getRawQuote(_start, _searchStep, client);

        // Search in the answer obtained the data corresponding to the symbols.
        // If requested symbol data is found add it to [portfolioQuotePrices].
        for (String symbol in symbols) {
          for (dynamic marketData in quoteRaw.values) {
            if (marketData['symbol'] == symbol) {
              // ignore: avoid_as
              results[symbol] = marketData as Map<String, dynamic>;
              _symbolsRetrieved.add(symbol);
            }
          }
        }
      } on CoinmarketcapApiException catch (e) {
        logger.e(
            'CoinmarketcapApiException{start: $_start, searchstep: $_searchStep, statusCode: ${e.statusCode}, message: ${e.message}}');
      }
      _start += _searchStep + 1;

      _symbolsRetrieved.forEach(symbols.remove);
    } while ((_start + _searchStep <= _numberOfCoins) && symbols.isNotEmpty);

    for (String symbol in symbols) {
      logger.e('CoinmarketcapApi: Symbol $symbol not found.');
    }

    return results;
  }

  static Future<Map<String, dynamic>> _getRawQuote(
      int _start, int _searchStep, http.Client client) async {
    final String quoteUrl =
        'https://api.coinmarketcap.com/v2/ticker/?start=$_start&limit=${_start + _searchStep}';
    try {
      final http.Response quoteRes = await client.get(quoteUrl);
      if (quoteRes != null &&
          quoteRes.statusCode == 200 &&
          quoteRes.body != null) {
        return parseRawQuote(quoteRes.body);
      } else {
        throw CoinmarketcapApiException(
            statusCode: quoteRes?.statusCode, message: 'Invalid response.');
      }
    } on http.ClientException {
      throw const CoinmarketcapApiException(message: 'Connection failed.');
    }
  }

  static Map<String, dynamic> parseRawQuote(String quoteResBody) {
    try {
      return const JsonDecoder().convert(quoteResBody)['data']
          as Map<String, dynamic>;
    } catch (e) {
      throw const CoinmarketcapApiException(
          statusCode: 200, message: 'Quote was not parseable.');
    }
  }

  static Map<String, String> parsePrice(Map<String, dynamic> rawQuote) {
    return <String, String>{
      'price':
          (rawQuote['quotes']['USD']['price'] as double).toStringAsFixed(2),
      'currency': (rawQuote['quotes'].keys.toList()[0] as String).toUpperCase(),
    };
  }
}
