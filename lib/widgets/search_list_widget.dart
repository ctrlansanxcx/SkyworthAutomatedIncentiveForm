import 'package:flutter/material.dart';
import 'package:incentivesystem/model/dealer.dart';

enum SearchType { dealer, branch }

class SearchListWidget extends StatelessWidget {
  final String query;
  final List<Dealer> items;
  final Function(Dealer)? onItemSelected;
  final SearchType type;

  const SearchListWidget({
    super.key,
    required this.query,
    required this.items,
    required this.type,
    this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    final filtered = items.where((item) {
      if (type == SearchType.dealer) {
        return item.dealer.toLowerCase().contains(query.toLowerCase());
      } else {
        return item.branch.toLowerCase().contains(query.toLowerCase());
      }
    }).toList();

    if (filtered.isEmpty) return const SizedBox();

    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(8),
      child: ListView.builder(
        padding: EdgeInsets.zero,
        itemCount: filtered.length,
        itemBuilder: (_, index) {
          final dealer = filtered[index];
          return InkWell(
            onTap: () {
              onItemSelected?.call(dealer);
            },
            onHover: (hovering) {},
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: index != filtered.length - 1
                      ? BorderSide(color: Colors.grey.shade300)
                      : BorderSide.none,
                ),
              ),
              child: Text(
                type == SearchType.dealer ? dealer.dealer : dealer.branch,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ),
          );
        },
      ),
    );
  }
}
