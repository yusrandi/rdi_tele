package com.rdi.rdi_tele

import android.Manifest
import android.annotation.SuppressLint
import android.annotation.TargetApi
import android.content.Context
import android.content.Context.TELEPHONY_SERVICE
import android.content.pm.PackageManager
import android.os.Build
import android.provider.Settings
import android.telephony.*
import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

/** RdiTelePlugin */
class RdiTelePlugin: FlutterPlugin, MethodCallHandler {
  /// The MethodChannel that will the communication between Flutter and native Android
  ///
  /// This local reference serves to register the plugin with the Flutter Engine and unregister it
  /// when the Flutter Engine is detached from the Activity
  private lateinit var channel : MethodChannel
  private var context: Context? = null

  override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    context = flutterPluginBinding.applicationContext
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "rdi_tele")
    channel.setMethodCallHandler(this)
  }

  override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {


    when (call.method) {
      "getPlatformVersion" -> result.success("Android ${android.os.Build.VERSION.RELEASE}")
      "getUid" -> result.success(getUuid())
      "getTM" -> result.success(getTM())

      else -> result.notImplemented()
    }
  }

  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
  }

  @SuppressLint("HardwareIds")
  private fun getUuid() : HashMap<String, String>{

    var listItem = mutableListOf<String>()
    var hashMap : HashMap<String, String>
            = HashMap()

    val myDeviceModel = Build.MODEL
    val myDevice = Build.DEVICE
    val myProduct = Build.PRODUCT
    val myBrand = Build.BRAND

    hashMap["myDeviceModel"] = myDeviceModel
    hashMap["myDevice"] = myDevice
    hashMap["myProduct"] = myProduct
    hashMap["myBrand"] = myBrand

    return hashMap
  }

  @TargetApi(Build.VERSION_CODES.Q)
  private fun getTM():HashMap<String, Int>{
    var hashMap : HashMap<String, Int>
            = HashMap()
    val tm: TelephonyManager = context!!.getSystemService(Context.TELEPHONY_SERVICE) as TelephonyManager


    val cellInfoList: List<CellInfo> = tm.allCellInfo
//        Log.e(TAG, "Andro : ${cellInfoList[0]}")

    if (cellInfoList.isEmpty()){
      val signalStrength: SignalStrength? = tm.signalStrength
//            Log.e(TAG, "Andro: getSignalQuality signalStrength $signalStrength")

      val list: List<CellSignalStrength> = signalStrength!!.cellSignalStrengths
      for (i in list.indices) {
        if (list[i] is CellSignalStrengthLte) {
          val cellSignalStrengthLte = list[i] as CellSignalStrengthLte

          hashMap["dbm"] = cellSignalStrengthLte.dbm
          hashMap["cqi"] = cellSignalStrengthLte.cqi
          hashMap["rsrp"] = cellSignalStrengthLte.rsrp
          hashMap["rsrq"] = cellSignalStrengthLte.rsrq
          hashMap["rssnr"] = cellSignalStrengthLte.rssnr
          hashMap["level"] = cellSignalStrengthLte.level
          hashMap["rssi"] = cellSignalStrengthLte.rssi
          hashMap["cellid"] = cellSignalStrengthLte.rssi

        }
      }
    }else{
      val cellInfo : CellInfo = cellInfoList[0]
      if (cellInfo is CellInfoLte){
        val lte : CellInfoLte = cellInfo
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {


          hashMap["dbm"] = lte.cellSignalStrength.dbm
          hashMap["cqi"] = lte.cellSignalStrength.cqi
          hashMap["rsrp"] = lte.cellSignalStrength.rsrp
          hashMap["rsrq"] = lte.cellSignalStrength.rsrq
          hashMap["rssnr"] = lte.cellSignalStrength.rssnr
          hashMap["level"] = lte.cellSignalStrength.level
          hashMap["rssi"] = lte.cellSignalStrength.rssi
          hashMap["cellid"] = lte.cellIdentity.ci


        }
      }
    }

    return hashMap
  }
}
