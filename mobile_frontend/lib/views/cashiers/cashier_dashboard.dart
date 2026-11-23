import '../shared/inventory_app.dart';

class CashierDashboard extends StatelessWidget {
  const CashierDashboard({super.key});

  @override
  Widget build(BuildContext context) => const InventoryApp(isOwner: false);
}
