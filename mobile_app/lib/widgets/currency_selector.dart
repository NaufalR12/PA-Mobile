import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/currency_provider.dart';
import '../models/currency.dart';

class CurrencySelector extends StatelessWidget {
  const CurrencySelector({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<CurrencyProvider>(
      builder: (context, currencyProvider, child) {
        return PopupMenuButton<String>(
          icon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                currencyProvider.selectedCurrency.code,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Icon(Icons.arrow_drop_down),
            ],
          ),
          onSelected: (String currencyCode) {
            currencyProvider.setCurrency(currencyCode);
          },
          itemBuilder: (BuildContext context) {
            return availableCurrencies.map((Currency currency) {
              return PopupMenuItem<String>(
                value: currency.code,
                child: Row(
                  children: [
                    Text(currency.symbol),
                    SizedBox(width: 8),
                    Text(currency.name),
                  ],
                ),
              );
            }).toList();
          },
        );
      },
    );
  }
}
