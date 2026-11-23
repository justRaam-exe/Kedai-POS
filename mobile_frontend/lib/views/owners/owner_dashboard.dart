import '../shared/inventory_app.dart';

class OwnerDashboard extends StatelessWidget {
  const OwnerDashboard({super.key});

  @override
  Widget build(BuildContext context) => const InventoryApp(isOwner: true);
}
