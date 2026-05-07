import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:nchat_mobile/common/locator.dart';
import 'package:nchat_mobile/cctp_settings/services/wallet_service.dart';
import 'package:nchat_mobile/common/wallet/erc20.dart';
import 'package:nchat_mobile/evm_screens/evm_token_swap_screen.dart';
import 'package:nchat_mobile/storages/wallet.dart';

class EvmTokenDashboardScreen extends StatefulWidget {
  const EvmTokenDashboardScreen({Key? key}) : super(key: key);

  @override
  State<EvmTokenDashboardScreen> createState() =>
      _EvmTokenDashboardScreenState();
}

class _EvmTokenDashboardScreenState extends State<EvmTokenDashboardScreen> {
  final _ethClient = EthErc20Client();
  final NumberFormat _amtFmt = NumberFormat('#,##0.0000');

  bool _loading = true;
  String? _error;

  String _evmAddress = '';
  String _nknMainnetAddress = '';
  double _ethBalance = 0.0;
  double _nknBalance = 0.0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _ethClient.close();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final wallet = await walletCommon.getDefault();
      if (wallet == null || wallet.address.isEmpty) {
        throw Exception('No wallet found');
      }

      final nknMainnetAddress = wallet.address;

      final storage = WalletStorage();
      final mnemonic = await storage.getMnemonic(wallet.address);
      if (mnemonic == null || !WalletService.validateMnemonic(mnemonic)) {
        throw Exception(
          'Missing or invalid seed phrase in secure storage. Please re-import or regenerate your seed phrase.',
        );
      }

      final derived = WalletService(mnemonic: mnemonic);
      final address = await derived.getEthereumAddress();

      final ethAmount = await _ethClient.getBalanceEth(address: address);
      final nknAmount = await _ethClient.getBalanceNkn(address: address);

      if (!mounted) return;
      setState(() {
        _evmAddress = address;
        _nknMainnetAddress = nknMainnetAddress;
        _ethBalance = (ethAmount?.ether as double?) ?? 0.0;
        _nknBalance = (nknAmount?.ether as double?) ?? 0.0;
        _loading = false;
      });
    } catch (e, st) {
      debugPrint('EVM Dashboard load failed: $e');
      debugPrintStack(stackTrace: st);
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _refresh() async {
    await _load();
  }

  Widget _buildError(String message) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          message,
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: _refresh,
          child: const Text('Retry'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'EVM Portfolio',
          style: TextStyle(fontFamily: 'Nasalization'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loading ? null : _refresh,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
            : _error != null
                ? _buildError(_error!)
                : RefreshIndicator(
                    onRefresh: _refresh,
                    child: Column(
                      children: [
                        _buildBalanceHeader(),
                        const SizedBox(height: 8),
                        Expanded(child: _buildTokenList()),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildBalanceHeader() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [Colors.purple.shade900, Colors.deepPurple.shade800]
              : [Colors.purple.shade400, Colors.deepPurple.shade500],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Total Balance',
            style: TextStyle(
              fontFamily: 'Nasalization',
              color: Colors.white70,
              fontSize: 14,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${_amtFmt.format(_ethBalance)} ETH',
            style: const TextStyle(
              fontFamily: 'Nasalization',
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildCopyRow(
            label: 'NKN',
            value: _nknMainnetAddress,
          ),
          const SizedBox(height: 8),
          _buildCopyRow(
            label: 'EVM',
            value: _evmAddress,
          ),
        ],
      ),
    );
  }

  Widget _buildCopyRow({required String label, required String value}) {
    return Row(
      children: [
        Text(
          '$label: ',
          style: const TextStyle(
            fontFamily: 'Nasalization',
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
        Expanded(
          child: SelectableText(
            value,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
              color: Colors.white70,
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.copy, size: 18, color: Colors.white),
          tooltip: 'Copy $label address',
          onPressed: value.isEmpty
              ? null
              : () async {
                  await Clipboard.setData(ClipboardData(text: value));
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('$label address copied')),
                  );
                },
        ),
      ],
    );
  }

  Widget _buildTokenList() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: const CircleAvatar(child: Icon(Icons.currency_bitcoin)),
            title: const Text(
              'Ethereum',
              style: TextStyle(
                fontFamily: 'Nasalization',
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: const Text('Native Token'),
            trailing: Text(
              '${_amtFmt.format(_ethBalance)} ETH',
              style: const TextStyle(
                fontFamily: 'Nasalization',
                fontWeight: FontWeight.bold,
              ),
            ),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => EvmTokenSwapScreen(
                    fromSymbol: 'ETH',
                    fromBalance: _ethBalance,
                    fromContract: null,
                  ),
                ),
              );
            },
          ),
        ),
        Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.transparent,
              backgroundImage: const AssetImage('assets/nknnetwork_2.png'),
            ),
            title: const Text(
              'NKN',
              style: TextStyle(
                fontFamily: 'Nasalization',
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              'ERC-20 @ ${Erc20Nkn.SMART_CONTRACT_ADDRESS}',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
            trailing: Text(
              '${_amtFmt.format(_nknBalance)} NKN',
              style: const TextStyle(
                fontFamily: 'Nasalization',
                fontWeight: FontWeight.bold,
              ),
            ),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => EvmTokenSwapScreen(
                    fromSymbol: 'NKN',
                    fromBalance: _nknBalance,
                    fromContract: Erc20Nkn.SMART_CONTRACT_ADDRESS,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
