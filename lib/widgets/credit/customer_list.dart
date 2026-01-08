import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:simple_pos/models/customer.dart';
import 'package:simple_pos/utils/constants.dart';

class CustomerList extends StatelessWidget {
  final List<Customer> customers;

  const CustomerList({super.key, required this.customers});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: customers.length,
      itemBuilder: (context, index) {
        final customer = customers[index];
        return CustomerListItem(customer: customer);
      },
    );
  }
}

class CustomerListItem extends StatelessWidget {
  final Customer customer;

  const CustomerListItem({super.key, required this.customer});

  @override
  Widget build(BuildContext context) {
    final double creditUtilization = customer.creditLimit > 0
        ? (customer.currentBalance / customer.creditLimit) * 100
        : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppBorderRadius.md),
          boxShadow: AppShadows.card),
      child: ExpansionTile(
        title: _buildCustomerHeader(creditUtilization),
        subtitle: _buildCreditInfo(creditUtilization),
        children: [_buildCustomerDetails()],
      ),
    );
  }

  Widget _buildCustomerHeader(double creditUtilization) {
    return Row(
      children: [
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(customer.name,
                style:
                    const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
            if (customer.phone != null) ...[
              const SizedBox(height: 2),
              Text(customer.phone!,
                  style:
                      const TextStyle(fontSize: 12, color: AppColors.textSecondary))
            ],
          ]),
        ),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('₱${customer.currentBalance.toStringAsFixed(2)}',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: customer.currentBalance > 0
                      ? AppColors.warning
                      : AppColors.success)),
          Text('Limit: ₱${customer.creditLimit.toStringAsFixed(2)}',
              style: const TextStyle(
                  fontSize: 10, color: AppColors.textSecondary)),
        ]),
      ],
    );
  }

  Widget _buildCreditInfo(double creditUtilization) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SizedBox(height: 8),
      if (customer.creditLimit > 0) ...[
        Row(children: [
          Expanded(
              child: LinearProgressIndicator(
                  value: creditUtilization / 100,
                  backgroundColor: AppColors.background,
                  valueColor:
                      AlwaysStoppedAnimation<Color>(creditUtilization > 80
                          ? AppColors.error
                          : creditUtilization > 60
                              ? AppColors.warning
                              : AppColors.success))),
          const SizedBox(width: AppSpacing.sm),
          Text('${creditUtilization.toStringAsFixed(0)}%',
              style:
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        ]),
        const SizedBox(height: 4),
      ],
      Text('Available: ₱${customer.availableCredit.toStringAsFixed(2)}',
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
    ]);
  }

  Widget _buildCustomerDetails() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: const BoxDecoration(
          color: AppColors.background,
          border: Border(top: BorderSide(color: AppColors.border))),
      child: Column(
        children: [
          Row(children: [
            Expanded(
                child: ElevatedButton.icon(
                    onPressed: customer.currentBalance > 0
                        ? () => _showPaymentDialog(customer)
                        : null,
                    icon: const Icon(Icons.payment),
                    label: const Text('Payment'),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success))),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
                child: OutlinedButton.icon(
                    onPressed: () => _showCustomerHistory(customer),
                    icon: const Icon(Icons.history),
                    label: const Text('History'))),
          ]),
          const SizedBox(height: AppSpacing.sm),
          if (customer.address != null)
            Row(children: [
              const Icon(Icons.location_on_outlined,
                  size: 16, color: AppColors.textSecondary),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                  child: Text(customer.address!,
                      style: const TextStyle(fontSize: 12)))
            ]),
          const SizedBox(height: AppSpacing.sm),
          Row(children: [
            const Icon(Icons.calendar_today_outlined,
                size: 16, color: AppColors.textSecondary),
            const SizedBox(width: AppSpacing.xs),
            Text(
                'Since: ${DateFormat('MMM dd, yyyy').format(customer.createdAt)}',
                style: const TextStyle(fontSize: 12))
          ]),
          const SizedBox(height: AppSpacing.sm),
          Row(children: [
            const Icon(Icons.credit_card_outlined,
                size: 16, color: AppColors.textSecondary),
            const SizedBox(width: AppSpacing.xs),
            Text('Credit Limit: ₱${customer.creditLimit.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 12))
          ]),
        ],
      ),
    );
  }

  void _showPaymentDialog(Customer customer) {
    // Implementation would go here
  }

  void _showCustomerHistory(Customer customer) {
    // Implementation would go here
  }
}
