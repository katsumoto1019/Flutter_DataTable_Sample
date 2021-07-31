import 'dart:ffi';
import 'dart:io';

import 'package:flutter/material.dart';
import 'dart:convert'; //json.decodeの使用のために追加
import 'package:flutter/services.dart'; // rootBundleの使用のために追加
import 'package:app_tracking_transparency/app_tracking_transparency.dart'; // ATT関連のSDK
import 'package:google_mobile_ads/google_mobile_ads.dart'; // 広告SDK

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // 広告SDKの初期化
  MobileAds.instance.initialize();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  List _items = [];

  // jsonファイルの内容読む
  Future<void> readJson() async {
    //JSONファイルの読み込み
    final String response = await rootBundle.loadString('assets/csvjson.json');
    final data = await json.decode(response);
    //table reload
    setState(() {
      _items = data;
    });
  }

  //------------------------- 広告表示関連のコード--------------------------------//
  static final AdRequest request = AdRequest(
    keywords: <String>['foo', 'bar'],
    contentUrl: 'http://foo.com/bar.html',
    nonPersonalizedAds: true,
  );

  BannerAd? _anchoredBanner;
  bool _loadingAnchoredBanner = false;

  // TODO: 広告 create&load
  Future<void> _createAnchoredBanner(BuildContext context) async {
    final AnchoredAdaptiveBannerAdSize? size =
    await AdSize.getAnchoredAdaptiveBannerAdSize(
      Orientation.portrait,
      MediaQuery.of(context).size.width.truncate(),
    );

    if (size == null) {
      print('Unable to get height of anchored banner.');
      return;
    }

    final BannerAd banner = BannerAd(
      size: size,
      request: request,
      adUnitId: getAdBannerUnitId(),
      listener: BannerAdListener(
        onAdLoaded: (Ad ad) {
          print('$BannerAd loaded.');
          setState(() {
            _anchoredBanner = ad as BannerAd?;
          });
        },
        onAdFailedToLoad: (Ad ad, LoadAdError error) {
          print('$BannerAd failedToLoad: $error');
          ad.dispose();
        },
        onAdOpened: (Ad ad) => print('$BannerAd onAdOpened.'),
        onAdClosed: (Ad ad) => print('$BannerAd onAdClosed.'),
      ),
    );
    return banner.load();
  }
  //------------------------- 広告表示関連のコード--------------------------------//

  //-------------------------ATT関連のコード--------------------------------//
  Future<void> initPlugin() async {
    try {
      final TrackingStatus status = await AppTrackingTransparency.trackingAuthorizationStatus;
      if (status == TrackingStatus.notDetermined) {
          final TrackingStatus status = await AppTrackingTransparency.requestTrackingAuthorization();
      }
    } on PlatformException {

    }
  }
  //-------------------------ATT関連のコード--------------------------------//

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    readJson();

    // ATT権限の要求
    WidgetsBinding.instance!.addPostFrameCallback((_) => initPlugin());
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    _anchoredBanner!.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_loadingAnchoredBanner) {
      _loadingAnchoredBanner = true;
      _createAnchoredBanner(context);
    }
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: Text('DataTable Sample'),
        ),
        body: ListView(
            children: <Widget>[
              DataTable(
                columns: [
                  DataColumn(label: Container(
                    width: 10,
                    child: Text('id', style: TextStyle(fontSize: 8),),
                  )),
                  DataColumn(label: Container(
                    width: 20,
                    child: Text('firstname', style: TextStyle(fontSize: 8),),
                  )),
                  DataColumn(label: Container(
                    width: 20,
                    child: Text('lastname', style: TextStyle(fontSize: 8),),
                  )),
                  DataColumn(label: Container(
                    width: 25,
                    child: Text('favobook', style: TextStyle(fontSize: 8),),
                  )),
                  DataColumn(label: Container(
                    width: 25,
                    child: Text('favofood', style: TextStyle(fontSize: 8),),
                  )),
                ],
                rows: _items.map((data) {
                  return DataRow(cells: [
                    DataCell(Container(
                      width: 10,
                      child: Text(data["id"].toString(), style: TextStyle(fontSize: 8),),
                    )),
                    DataCell(Container(
                      width: 20,
                      child: Text(data["firstname"].toString(), style: TextStyle(fontSize: 8),),
                    )),
                    DataCell(Container(
                      width: 20,
                      child: Text(data["lastname"].toString(), style: TextStyle(fontSize: 8),),
                    )),
                    DataCell(Container(
                      width: 25,
                      child: Text(data["favoritebook"].toString(), style: TextStyle(fontSize: 8),),
                    )),
                    DataCell(Container(
                      width: 25,
                      child: Text(data["favoritefood"].toString(), style: TextStyle(fontSize: 8),),
                    )),
                  ]);
                }).toList(),
              ),
            ]
        ),
        bottomNavigationBar: Container(
          color: Colors.transparent,
          width:  _anchoredBanner !=null ? _anchoredBanner!.size.width.toDouble() : 320.0,
          height: _anchoredBanner !=null ? _anchoredBanner!.size.height.toDouble() : 50.0,
          child: _anchoredBanner !=null ? AdWidget(ad: _anchoredBanner!):Container(),
        ),
      ),
    );
  }
}

// 広告IDの設定
String getAdBannerUnitId(){
  String bannerUnitId = "";
  if(Platform.isAndroid) {
    // Android のとき
    bannerUnitId = "ca-app-pub-3940256099942544/6300978111";
  } else if(Platform.isIOS) {
    // iOSのとき
    bannerUnitId = "ca-app-pub-3940256099942544/2934735716";
  }
  return bannerUnitId;
}
