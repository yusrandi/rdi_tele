class CitModel {
  String cqi;
  String signalQuality;
  String signalStrength;
  String rssnr;
  String upload;
  String download;
  String jitter;
  String rtPing;
  String latPos;
  String lngPos;
  String networkType;
  String networkOperator;
  String uuid;
  String cellid;
  String brand;
  String device;
  String model;
  String address;
  String data;

  CitModel({
    required this.cqi,
    required this.signalQuality,
    required this.signalStrength,
    required this.rssnr,
    required this.upload,
    required this.download,
    required this.jitter,
    required this.rtPing,
    required this.latPos,
    required this.lngPos,
    required this.networkType,
    required this.networkOperator,
    required this.uuid,
    required this.cellid,
    required this.brand,
    required this.device,
    required this.model,
    required this.address,
    required this.data,
  });
}
