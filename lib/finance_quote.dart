// Copyright 2019 Ismael Jiménez. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

library finance_quote;

import 'package:finance_quote/src/quote_providers/binance.dart';
import 'package:meta/meta.dart';
import 'package:finance_quote/src/app_logger.dart';
import 'package:finance_quote/src/quote_providers/coincap.dart';
import 'package:finance_quote/src/quote_providers/coinmarketcap.dart';
import 'package:finance_quote/src/quote_providers/morningstarDe.dart';
import 'package:finance_quote/src/quote_providers/morningstarEs.dart';
import 'package:finance_quote/src/quote_providers/yahoo.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';

final Logger logger = Logger(printer: AppLogger('FinanceQuote'));

/// The identifier of the quote provider.
enum QuoteProvider {
  yahoo,
  coincap,
  coinmarketcap,
  morningstarDe,
  morningstarEs,
  binance
}

class FinanceQuote {
  /// Returns a [Map] object containing the raw data retrieved. The map contains a key for each
  /// symbol retrieved and the value is map with the symbol properties. In case no valid quote data
  /// is retrieved, an empty map is returned.
  ///
  /// The `quoteProvider` argument controls where the quote data comes from. This can
  /// be any of the values of [QuoteProvider].
  ///
  /// The `symbols` argument controls which quotes shall be retrieved. This can
  /// be any string identifying a valid symbol for the [QuoteProvider].
  ///
  /// If specified, the `client` provided will be used. This is used for testing purposes.
  static Future<Map<String, Map<String, dynamic>>> getRawData(
      {@required QuoteProvider quoteProvider,
      @required List<String> symbols,
      http.Client client}) async {
    // If client is not provided, use http IO client
    client ??= http.Client();

    // Retrieved market data.
    Map<String, Map<String, dynamic>> retrievedQuoteData =
        <String, Map<String, dynamic>>{};

    if (symbols.isEmpty) {
      return retrievedQuoteData;
    }

    switch (quoteProvider) {
      case QuoteProvider.yahoo:
        {
          retrievedQuoteData = await Yahoo.downloadRaw(symbols, client, logger);
        }
        break;
      case QuoteProvider.morningstarDe:
        {
          retrievedQuoteData =
              await MorningstarDe.downloadRaw(symbols, client, logger);
        }
        break;
      case QuoteProvider.morningstarEs:
        {
          retrievedQuoteData =
              await MorningstarEs.downloadRaw(symbols, client, logger);
        }
        break;
      case QuoteProvider.coinmarketcap:
        {
          retrievedQuoteData =
              await Coinmarketcap.downloadRaw(symbols, client, logger);
        }
        break;
      case QuoteProvider.coincap:
        {
          retrievedQuoteData =
              await Coincap.downloadRaw(symbols, client, logger);
        }
        break;
      case QuoteProvider.binance:
        {
          retrievedQuoteData =
              await Binance.downloadRaw(symbols, client, logger);
        }
        break;
      default:
        {
          logger.e('Unknown Quote Source');
        }
        break;
    }

    return retrievedQuoteData;
  }

  /// Returns a [Map] object containing the price data retrieved. The map contains a key for each
  /// symbol retrieved and the value is map with the symbol properties 'price' and 'currency'.
  /// In case no valid quote data is retrieved, an empty map is returned.
  ///
  /// The `quoteProvider` argument controls where the quote data comes from. This can
  /// be any of the values of [QuoteProvider].
  ///
  /// The `symbols` argument controls which quotes shall be retrieved. This can
  /// be any string identifying a valid symbol for the [QuoteProvider].
  ///
  /// If specified, the `client` provided will be used. This is used for testing purposes.
  static Future<Map<String, Map<String, String>>> getPrice(
      {@required QuoteProvider quoteProvider,
      @required List<String> symbols,
      http.Client client}) async {
    final Map<String, Map<String, String>> quotePrice =
        <String, Map<String, String>>{};

    if (symbols.isEmpty) {
      return quotePrice;
    }

    final Map<String, Map<String, dynamic>> rawQuotes = await getRawData(
        quoteProvider: quoteProvider, symbols: symbols, client: client);

    rawQuotes.forEach((String symbol, Map<String, dynamic> rawQuote) {
      switch (quoteProvider) {
        case QuoteProvider.yahoo:
          {
            quotePrice[symbol] = Yahoo.parsePrice(rawQuote);
          }
          break;
        case QuoteProvider.morningstarDe:
          {
            quotePrice[symbol] = MorningstarDe.parsePrice(rawQuote);
          }
          break;
        case QuoteProvider.morningstarEs:
          {
            quotePrice[symbol] = MorningstarEs.parsePrice(rawQuote);
          }
          break;
        case QuoteProvider.coinmarketcap:
          {
            quotePrice[symbol] = Coinmarketcap.parsePrice(rawQuote);
          }
          break;
        case QuoteProvider.coincap:
          {
            quotePrice[symbol] = Coincap.parsePrice(rawQuote);
          }
          break;
        case QuoteProvider.binance:
          {
            quotePrice[symbol] = Binance.parsePrice(rawQuote);
          }
          break;
        default:
          {
            logger.e('Unknown Quote Source');
          }
          break;
      }
    });
    return quotePrice;
  }
}
