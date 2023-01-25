import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:rdi_tele/configs/api.dart';
import 'package:rdi_tele/models/cit_model.dart';

class UserServcies {
  static UserServcies instance = UserServcies();

  Future<String> passDataCit(CitModel model) async {
    // print(
    // '[BackgroundFetch] model ${model.networkOperator}, ${model.networkType}');
    var response = await http.post(Uri.parse(Api().citPostDataUrl), body: {
      "cqi": model.cqi.toString(),
      "signal_quality": model.signalQuality.toString(),
      "signal_strength": model.signalStrength.toString(),
      "rssnr": model.rssnr.toString(),
      "jitter": model.jitter.toString(),
      "upload": model.upload.toString(),
      "download": model.download.toString(),
      "rt_ping": model.rtPing.toString(),
      "lat": model.latPos.toString(),
      "lng": model.lngPos.toString(),
      "network_type": model.networkType.toString(),
      "network_operator": model.networkOperator.toString(),
      'uuid': model.uuid,
      'cellid': model.cellid,
      'dev_name': model.brand,
      'dev_type': model.device,
      'dev_model': model.model,
      'address': model.address,
      'data_connect': model.data,
    });

    print('[BackgroundFetch] response ${response.body}');

    var data = json.decode(response.body);
    print(data['meta']['code']);
    // var data = json.decode(response.body);
    // print(data);

    return data['meta']['code'].toString();
  }
}
