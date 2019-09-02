import 'package:finance_quote/finance_quote.dart';

Future<void> main(List<String> arguments) async {
  final Map<String, Map<String, dynamic>> quoteRaw =
      await FinanceQuote.getRawData(
          quoteProvider: QuoteProvider.yahoo, symbols: <String>['KO', 'GOOG']);

  print('Number of quotes retrieved: ${quoteRaw.keys.length}.');
  print(
      'Number of attributes retrieved for KO: ${quoteRaw['KO'].keys.length}.');
  print(
      'Current market price for KO: ${quoteRaw['GOOG']['regularMarketPrice']}.');
  print(
      'Number of attributes retrieved for GOOG: ${quoteRaw['GOOG'].keys.length}.');
  print(
      'Current market price for KO: ${quoteRaw['GOOG']['regularMarketPrice']}.');

  final Map<String, Map<String, String>> quotePrice =
      await FinanceQuote.getPrice(
          quoteProvider: QuoteProvider.yahoo, symbols: <String>['KO', 'GOOG']);

  print('Number of quotes retrieved: ${quotePrice.keys.length}.');
  print(
      'Number of attributes retrieved for KO: ${quotePrice['KO'].keys.length}.');
  print('Current market price for KO: ${quotePrice['KO']['price']}.');
  print(
      'Number of attributes retrieved for GOOG: ${quotePrice['GOOG'].keys.length}.');
  print('Current market price for KO: ${quotePrice['GOOG']['price']}.');

  final Map<String, Map<String, dynamic>> cryptoQuoteRaw =
      await FinanceQuote.getRawData(
          quoteProvider: QuoteProvider.coincap,
          symbols: <String>['bitcoin', 'ethereum']);

  print('Number of quotes retrieved: ${cryptoQuoteRaw.keys.length}.');
  print(
      'Number of attributes retrieved for bitcoin: ${cryptoQuoteRaw['bitcoin'].keys.length}.');
  print(
      'Current market price for bitcoin: ${cryptoQuoteRaw['bitcoin']['priceUsd']}.');
  print(
      'Number of attributes retrieved for ethereum: ${cryptoQuoteRaw['ethereum'].keys.length}.');
  print(
      'Current market price for ethereum: ${cryptoQuoteRaw['ethereum']['priceUsd']}.');
}
