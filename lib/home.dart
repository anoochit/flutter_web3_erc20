import 'dart:async';
import 'dart:js_util';

import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web3/utils.dart';
import 'package:flutter_web3_provider/ethereum.dart';
import 'package:flutter_web3_provider/ethers.dart';
import 'ec20arbi.dart';

class HomePage extends StatefulWidget {
  HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? selectedAddress;
  Web3Provider? web3;

  Future? balanceETH;
  Future? balanceToken;

  // ERC20 contract address
  var contractAddress = '0x318aEA2A8b03DBE3B7d13AACF0900323A045c984';

  // change to your another wallet address to test
  var wallet3 = '0x3F0262d74D76E0B46b0289A43541e69428e94EDA';

  Timer? timer;

  @override
  void initState() {
    super.initState();

    // ignore: unnecessary_null_comparison
    if (ethereum != null) {
      loadWalletData();
      if (timer == null) {
        timer = Timer.periodic(Duration(seconds: 5), (Timer t) {
          setState(() {
            loadWalletData();
          });
        });
      }
    }
  }

  @override
  void dispose() {
    timer!.cancel();
    super.dispose();
  }

  loadWalletData() {
    web3 = Web3Provider(ethereum);
    balanceETH = promiseToFuture(web3!.getBalance(ethereum.selectedAddress));
    var contract = Contract(contractAddress, erc20Abi, web3);
    balanceToken = promiseToFuture(callMethod(contract, "balanceOf", [ethereum.selectedAddress]));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          children: [
            (selectedAddress != null)
                ? Text('Wallet Address = $selectedAddress')
                : ElevatedButton(
                    child: Text("Connect to Wallet"),
                    onPressed: () async {
                      // connect wallet
                      print('> connect to wallet');
                      var accounts = await promiseToFuture(ethereum.request(RequestParams(method: 'eth_requestAccounts')));
                      print(accounts);
                      setState(() {
                        selectedAddress = ethereum.selectedAddress;
                        print('> selected address = $selectedAddress');
                      });
                    },
                  ),
            (selectedAddress != null)
                ? FutureBuilder(
                    future: balanceETH,
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        var balanceBigInt = BigInt.parse(snapshot.data.toString());
                        var balance = toDecimal(balanceBigInt, 18);
                        return Text('ETH Balance $balance');
                      }

                      return Container();
                    },
                  )
                : Container(),
            (selectedAddress != null)
                ? FutureBuilder(
                    future: balanceToken,
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        var balanceBigInt = BigInt.parse(snapshot.data.toString());
                        var balance = toDecimal(balanceBigInt, 18);
                        return Text('MYK Balance $balance');
                      }
                      return Container();
                    },
                  )
                : Container(),
            (selectedAddress != null)
                ? ElevatedButton(
                    child: Text("Tranfer 1.0 MYK to Wallet 3"),
                    onPressed: () async {
                      // transfer to wallet2
                      var contract = Contract(contractAddress, erc20Abi, web3);
                      var contractSigner = contract.connect(web3!.getSigner());

                      try {
                        var res = await promiseToFuture(
                          callMethod(
                            contractSigner,
                            "transfer",
                            [
                              wallet3,
                              "0x" + BigInt.parse(toBase(Decimal.parse("1.0"), 18).toString()).toRadixString(16),
                            ],
                          ),
                        );

                        print("Transferred: ${res.toString()}");
                      } catch (e) {
                        print('exception : ${e.toString()}');
                      }
                    },
                  )
                : Container(),
          ],
        ),
      ),
    );
  }
}
