import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:nchat_mobile/common/wallet/erc20.dart';

class EvmTokenSwapScreen extends StatefulWidget {
  final String? fromSymbol;
  final double fromBalance;
  final String? fromContract; // null => native ETH

  const EvmTokenSwapScreen({
    Key? key,
    this.fromSymbol,
    required this.fromBalance,
    this.fromContract,
  }) : super(key: key);

  @override
  State<EvmTokenSwapScreen> createState() => _EvmTokenSwapScreenState();
}

// Token card data model
class TokenCardData {
  final String mint;
  final String symbol;
  final int decimals;
  final bool isSelectable;
  final double balance;

  TokenCardData({
    required this.mint,
    required this.symbol,
    required this.decimals,
    required this.isSelectable,
    this.balance = 0.0,
  });

  TokenCardData copyWith({
    String? mint,
    String? symbol,
    int? decimals,
    bool? isSelectable,
    double? balance,
  }) {
    return TokenCardData(
      mint: mint ?? this.mint,
      symbol: symbol ?? this.symbol,
      decimals: decimals ?? this.decimals,
      isSelectable: isSelectable ?? this.isSelectable,
      balance: balance ?? this.balance,
    );
  }
}

class _EvmTokenSwapScreenState extends State<EvmTokenSwapScreen> {
  final _amountController = TextEditingController();
  Timer? _debounceTimer;

  static const String _ethSymbol = 'ETH';
  static const String _nknSymbol = 'NKN';

  // Top and Bottom cards - can be swapped
  late TokenCardData _topCard;
  late TokenCardData _bottomCard;

  bool _loadingBalance = false;
  bool _balancesReady = false; // gate quotes until initial balances are fetched

  @override
  void initState() {
    super.initState();

    final initialFromSymbol = (widget.fromSymbol ?? _ethSymbol).toUpperCase();
    final initialFromIsEth = initialFromSymbol == _ethSymbol;

    _topCard = TokenCardData(
      mint: initialFromIsEth ? _ethSymbol : Erc20Nkn.SMART_CONTRACT_ADDRESS,
      symbol: initialFromIsEth ? _ethSymbol : _nknSymbol,
      decimals: 18,
      isSelectable: true,
      balance: widget.fromBalance,
    );

    _bottomCard = TokenCardData(
      mint: initialFromIsEth ? Erc20Nkn.SMART_CONTRACT_ADDRESS : _ethSymbol,
      symbol: initialFromIsEth ? _nknSymbol : _ethSymbol,
      decimals: 18,
      isSelectable: true,
      balance: 0.0,
    );

    // In MVP stub, we consider balances ready (we already pass fromBalance in)
    _balancesReady = true;
  }

  bool _loadingQuote = false;
  bool _swapping = false;

  int _slippageBps = 50; // placeholder
  double _balancePercentage = 0.0; // 0-100%

  @override
  void dispose() {
    _amountController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _debouncedGetQuote() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 800), () {
      _getQuote();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Swap',
          style: TextStyle(fontFamily: 'Nasalization'),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildInputCard(),
              const SizedBox(height: 16),
              Center(
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.swap_vert, color: Colors.white),
                    onPressed: _swapDirection,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _buildOutputCard(),
              const SizedBox(height: 24),
              _buildSlippageSettings(),
              const SizedBox(height: 24),
              if (_loadingQuote)
                const Center(child: CircularProgressIndicator())
              else
                _buildQuoteDetails(_topCard, _bottomCard),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _swapping ? null : _executeSwap,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey,
                ),
                child: _swapping
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'SWAP',
                        style: TextStyle(
                          fontFamily: 'Nasalization',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _getQuote() async {
    // Do not fetch quotes while balances are still loading
    if (_loadingBalance || !_balancesReady) return;
    if (_amountController.text.isEmpty) return;

    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) return;

    // Prevent same token swap
    if (_topCard.mint == _bottomCard.mint) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot swap the same token'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _loadingQuote = true;
    });

    // Stub quote simulation
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    setState(() {
      _loadingQuote = false;
    });
  }

  Future<void> _executeSwap() async {
    setState(() => _swapping = true);
    try {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Swap execution not implemented yet'),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e, st) {
      // Log all errors to debug output
      print('[Swap][EXCEPTION] $e');
      print(st);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Swap failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _swapping = false);
      }
    }
  }

  void _swapDirection() {
    // Simply swap the top and bottom cards
    setState(() {
      final temp = _topCard;
      _topCard = _bottomCard;
      _bottomCard = temp;

      // Clear amount and quote when swapping
      _amountController.clear();
      _balancePercentage = 0.0;
    });
  }

  Widget _buildToggleButton(String symbol, int index, bool isTopCard) {
    final currentCard = isTopCard ? _topCard : _bottomCard;
    final isSelected = currentCard.symbol == symbol;

    final token = (symbol == _ethSymbol)
        ? {
            'mint': _ethSymbol,
            'symbol': _ethSymbol,
            'decimals': 18,
          }
        : {
            'mint': Erc20Nkn.SMART_CONTRACT_ADDRESS,
            'symbol': _nknSymbol,
            'decimals': 18,
          };

    return GestureDetector(
      onTap: () {
        if (!isSelected) {
          setState(() {
            if (isTopCard) {
              _topCard = _topCard.copyWith(
                mint: token['mint'] as String,
                symbol: token['symbol'] as String,
                decimals: token['decimals'] as int,
              );
            } else {
              _bottomCard = _bottomCard.copyWith(
                mint: token['mint'] as String,
                symbol: token['symbol'] as String,
                decimals: token['decimals'] as int,
              );
            }
          });

          // Refresh quote if amount is entered
          if (_amountController.text.isNotEmpty) {
            _getQuote();
          }
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color:
              isSelected ? Theme.of(context).primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          symbol,
          style: TextStyle(
            fontFamily: 'Nasalization',
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : Colors.grey.shade600,
          ),
        ),
      ),
    );
  }

  Widget _buildInputCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Sell',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                Row(
                  children: [
                    // Toggle button for selectable tokens
                    if (_topCard.isSelectable)
                      Container(
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildToggleButton(_ethSymbol, 0, true),
                            _buildToggleButton(_nknSymbol, 1, true),
                          ],
                        ),
                      ),
                    // Balance display
                    if (_loadingBalance)
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else if (_topCard.balance > 0) ...[
                      Text(
                        () {
                          final dec = _topCard.decimals > 6 ? 4 : 2;
                          final pattern =
                              '#,##0.' + List.filled(dec, '0').join();
                          final fmt = NumberFormat(pattern);
                          return 'Balance: ${fmt.format(_topCard.balance)}';
                        }(),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: () {
                          final maxSellable = _topCard.balance;
                          final pctRaw = _topCard.balance > 0 ? 100.0 : 0.0;
                          final pctClamped = pctRaw.clamp(0, 100);
                          final pctRounded =
                              double.parse(pctClamped.toStringAsFixed(3));
                          setState(() {
                            _balancePercentage = pctRounded;
                            _amountController.text = maxSellable
                                .toStringAsFixed(_topCard.decimals > 6 ? 4 : 6);
                          });
                          _getQuote();
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text(
                          'MAX',
                          style: TextStyle(
                              fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _amountController,
                    decoration: InputDecoration(
                      hintText: '0.00',
                      border: InputBorder.none,
                      hintStyle: TextStyle(
                        fontSize: 32,
                        color: Colors.grey.shade400,
                      ),
                    ),
                    style: const TextStyle(
                      fontFamily: 'Nasalization',
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (val) {
                      // Update slider when typing
                      if (_topCard.balance > 0) {
                        final amount = double.tryParse(val) ?? 0;
                        final pctRaw = (amount / _topCard.balance * 100);
                        final pctClamped = pctRaw.clamp(0, 100);
                        final pctRounded =
                            double.parse(pctClamped.toStringAsFixed(3));
                        setState(() {
                          _balancePercentage = pctRounded;
                        });
                      }
                      // Debounce and get quote
                      _debouncedGetQuote();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withAlpha(26),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _topCard.symbol,
                    style: const TextStyle(
                      fontFamily: 'Nasalization',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            // Balance percentage slider - always visible on top card
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: Colors.blue,
                      inactiveTrackColor: Colors.grey.shade300,
                      thumbColor: Colors.blue,
                      overlayColor: Colors.blue.withAlpha(51),
                      trackHeight: 4,
                    ),
                    child: Slider(
                      value: _balancePercentage,
                      min: 0,
                      max: 100,
                      divisions: 100,
                      onChanged: _topCard.balance > 0
                          ? (value) {
                              // Round value to 3 decimal places first and clamp
                              final roundedValue =
                                  double.parse(value.toStringAsFixed(3))
                                      .clamp(0, 100);
                              double targetAmount =
                                  (_topCard.balance * roundedValue / 100);
                              _balancePercentage = roundedValue.toDouble();

                              setState(() {
                                _amountController.text =
                                    targetAmount.toStringAsFixed(
                                        _topCard.decimals > 6 ? 4 : 2);
                              });
                            }
                          : null,
                      onChangeEnd: _topCard.balance > 0
                          ? (value) {
                              _getQuote();
                            }
                          : null,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 45,
                  child: Text(
                    '${_balancePercentage.toInt()}%',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _topCard.balance > 0 ? null : Colors.grey.shade700,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _percentageChip(25),
                _percentageChip(50),
                _percentageChip(75),
                _percentageChip(100),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOutputCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Buy',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                // Toggle button for SOL/USDC only if selectable
                if (_bottomCard.isSelectable)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildToggleButton(_ethSymbol, 0, false),
                        _buildToggleButton(_nknSymbol, 1, false),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '0.00',
                    style: TextStyle(
                      fontFamily: 'Nasalization',
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade400,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withAlpha(26),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _bottomCard.symbol,
                    style: const TextStyle(
                      fontFamily: 'Nasalization',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _percentageChip(int percentage) {
    final isSelected = _balancePercentage.toInt() == percentage;
    final hasBalance = _topCard.balance > 0;

    return InkWell(
      onTap: hasBalance
          ? () {
              setState(() {
                _balancePercentage = percentage.toDouble();
                final amount = (_topCard.balance * percentage / 100);
                _amountController.text =
                    amount.toStringAsFixed(_topCard.decimals > 6 ? 4 : 2);
              });
              // Immediate quote for percentage chips (user action complete)
              if (_balancesReady && !_loadingBalance) {
                _getQuote();
              }
            }
          : null,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected && hasBalance ? Colors.blue : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          '$percentage%',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : Colors.grey.shade800,
          ),
        ),
      ),
    );
  }

  Widget _buildSlippageSettings() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Slippage Tolerance',
              style: TextStyle(
                fontFamily: 'Nasalization',
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _slippageChip(50, '0.5%'),
                const SizedBox(width: 8),
                _slippageChip(100, '1%'),
                const SizedBox(width: 8),
                _slippageChip(300, '3%'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _slippageChip(int bps, String label) {
    final isSelected = _slippageBps == bps;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() => _slippageBps = bps);
          if (_balancesReady && !_loadingBalance) {
            _getQuote();
          }
        }
      },
    );
  }

  Widget _buildQuoteDetails(TokenCardData fromCard, TokenCardData toCard) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildDetailRow('Rate', 'Quote not implemented'),
            const Divider(),
            _buildDetailRow('Price Impact', '--'),
            const Divider(),
            _buildDetailRow('Route', '--'),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
