package com.rdi.rdi_tele

import android.annotation.SuppressLint
import android.annotation.TargetApi
import android.content.Context
import android.os.Build
import android.telephony.*
import android.util.ArrayMap
import android.util.Log
import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.io.BufferedReader
import java.io.IOException
import java.io.InputStreamReader
import java.text.DateFormat
import java.util.*
import java.util.regex.Pattern


//
/** RdiTelePlugin */
class RdiTelePlugin: FlutterPlugin, MethodCallHandler {
  /// The MethodChannel that will the communication between Flutter and native Android
  ///
  /// This local reference serves to register the plugin with the Flutter Engine and unregister it
  /// when the Flutter Engine is detached from the Activity
  private lateinit var channel : MethodChannel
  private var context: Context? = null

  companion object{
    const val TAG = "RDI:Testing"
  }


  override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    context = flutterPluginBinding.applicationContext
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "rdi_tele")
    channel.setMethodCallHandler(this)
  }

  override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: MethodChannel.Result) {
    when (call.method) {
      "getPlatformVersion" -> result.success("Android ${Build.VERSION.RELEASE}")
      "getUid" -> result.success(getUuid())
      "getTM" -> result.success(getTM())
      "getPing" -> result.success(PingTest.runNVT())

      else -> result.notImplemented()
    }
  }

  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
  }

  @SuppressLint("HardwareIds")
  private fun getUuid() : HashMap<String, String>{

    var hashMap : HashMap<String, String>
            = HashMap()

    val myDeviceModel = Build.MODEL
    val myDevice = Build.DEVICE
    val myProduct = Build.PRODUCT
    val myBrand = Build.BRAND
    val myVersionRelease = Build.VERSION.RELEASE

    hashMap["myDeviceModel"] = myDeviceModel
    hashMap["myDevice"] = myDevice
    hashMap["myProduct"] = myProduct
    hashMap["myBrand"] = myBrand
    hashMap["myVersionRelease"] = myVersionRelease

    return hashMap
  }

//  @SuppressLint("HardwareIds")
  @TargetApi(Build.VERSION_CODES.R)
  private fun getTM():HashMap<String, Int>{
    var hashMap : HashMap<String, Int>
            = HashMap()

            // CHECK PERMISSIONS FIRST
    if (context == null ||
        androidx.core.app.ActivityCompat.checkSelfPermission(
            context!!,
            android.Manifest.permission.ACCESS_FINE_LOCATION
        ) != android.content.pm.PackageManager.PERMISSION_GRANTED ||
        androidx.core.app.ActivityCompat.checkSelfPermission(
            context!!,
            android.Manifest.permission.READ_PHONE_STATE
        ) != android.content.pm.PackageManager.PERMISSION_GRANTED
    ) {
        Log.e(TAG, "Permission not granted!")
        return hashMap // return empty
    }


    try {
        val tm: TelephonyManager = context!!.getSystemService(Context.TELEPHONY_SERVICE) as TelephonyManager
        val cellInfoList = tm.allCellInfo

        if (cellInfoList.isEmpty()) {
            Log.e(TAG, "No cell info available")
            return hashMap
        }

        val primaryCellInfo = cellInfoList[0]
        val signalStrength = primaryCellInfo.cellSignalStrength

        // Initialize with default values
        var dbm = -1
        var cqi = -1
        var rsrp = -1
        var rsrq = -1
        var rssnr = -1
        var level = -1
        var rssi = -1
        var cellId = -1
        var ta = -1

        // Handle different network types
        when (signalStrength) {
            is CellSignalStrengthLte -> {
                dbm = signalStrength.dbm
                cqi = signalStrength.cqi
                rsrp = signalStrength.rsrp
                rsrq = signalStrength.rsrq
                rssnr = signalStrength.rssnr
                level = signalStrength.level
                rssi = signalStrength.rssi
                ta = signalStrength.timingAdvance

                // Get cell identity for LTE
                val cellIdentity = primaryCellInfo.cellIdentity as? CellIdentityLte
                cellId = cellIdentity?.ci ?: -1
            }
            is CellSignalStrengthNr -> {
                dbm = signalStrength.dbm

                // CQI might not be available in all Android versions for NR
                // cqi = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                //     signalStrength.cqi
                // } else {
                //     -1
                // }

                rsrp = signalStrength.ssRsrp
                rsrq = signalStrength.ssRsrq
                rssnr = signalStrength.ssSinr
                level = signalStrength.level

                // NR doesn't have rssi and timingAdvance in the same way
                rssi = -1 // Not available in NR
                ta = -1 // Not available in NR

                // Get cell identity for NR
                val cellIdentity = primaryCellInfo.cellIdentity as? CellIdentityNr
                cellId = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                    cellIdentity?.nci?.toInt() ?: -1
                } else {
                    -1
                }
            }
            is CellSignalStrengthWcdma -> {
                dbm = signalStrength.dbm
                level = signalStrength.level
                // WCDMA specific parameters
                rsrp = -1
                rsrq = -1
                rssnr = -1
                rssi = -1
                ta = -1

                val cellIdentity = primaryCellInfo.cellIdentity as? CellIdentityWcdma
                cellId = cellIdentity?.cid ?: -1
            }
            is CellSignalStrengthGsm -> {
                dbm = signalStrength.dbm
                level = signalStrength.level
                // GSM specific parameters
                rsrp = -1
                rsrq = -1
                rssnr = -1
                rssi = -1
                ta = -1

                val cellIdentity = primaryCellInfo.cellIdentity as? CellIdentityGsm
                cellId = cellIdentity?.cid ?: -1
            }
            else -> {
                Log.w(TAG, "Unsupported network type: ${signalStrength.javaClass.simpleName}")
                // Fallback to basic signal strength
                dbm = signalStrength.dbm
                level = signalStrength.level
            }
        }

        // Populate the hashmap
        hashMap["dbm"] = dbm
        hashMap["cqi"] = cqi
        hashMap["rsrp"] = rsrp
        hashMap["rsrq"] = rsrq
        hashMap["rssnr"] = rssnr
        hashMap["level"] = level
        hashMap["rssi"] = rssi
        hashMap["cellid"] = cellId
        hashMap["ta"] = ta

    } catch (e: Exception) {
        Log.e(TAG, "Error getting telephony metrics: ${e.message}", e)
    }


//  val cellInfoList: List<CellInfo> = tm.allCellInfo
//        Log.e(TAG, "Andro : $cellInfoList")
//
//    if (cellInfoList.isEmpty()){
//      val signalStrength: SignalStrength? = tm.signalStrength
////            Log.e(TAG, "Andro: getSignalQuality signalStrength $signalStrength")
//
//      val list: List<CellSignalStrength> = signalStrength!!.cellSignalStrengths
//      for (i in list.indices) {
//        if (list[i] is CellSignalStrengthLte) {
//          val cellSignalStrengthLte = list[i] as CellSignalStrengthLte
//
//          hashMap["dbm"] = cellSignalStrengthLte.dbm
//          hashMap["cqi"] = cellSignalStrengthLte.cqi
//          hashMap["rsrp"] = cellSignalStrengthLte.rsrp
//          hashMap["rsrq"] = cellSignalStrengthLte.rsrq
//          hashMap["rssnr"] = cellSignalStrengthLte.rssnr
//          hashMap["level"] = cellSignalStrengthLte.level
//          hashMap["rssi"] = cellSignalStrengthLte.rssi
//          hashMap["cellid"] = cellSignalStrengthLte.rssi
//          hashMap["ta"] = cellSignalStrengthLte.timingAdvance
//
//
//        }
//
//      }
//    }else{
//      val cellInfo : CellInfo = cellInfoList[0]
//      if (cellInfo is CellInfoLte){
//
//        val lte : CellInfoLte = cellInfo
//        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
//
//          hashMap["dbm"] = lte.cellSignalStrength.dbm
//          hashMap["cqi"] = lte.cellSignalStrength.cqi
//          hashMap["rsrp"] = lte.cellSignalStrength.rsrp
//          hashMap["rsrq"] = lte.cellSignalStrength.rsrq
//          hashMap["rssnr"] = lte.cellSignalStrength.rssnr
//          hashMap["level"] = lte.cellSignalStrength.level
//          hashMap["rssi"] = lte.cellSignalStrength.rssi
//          hashMap["cellid"] = lte.cellIdentity.ci
//          hashMap["ta"] = lte.cellSignalStrength.timingAdvance
//
//
//          val longCid = lte.cellIdentity.ci
//
//          val cellidHex = DecToHex(longCid)
//          val eNBHex = cellidHex!!.substring(0, cellidHex.length - 2)
//
//
//          val eNB = HexToDec(eNBHex)
//
//          Log.d(TAG,"cellidHex $cellidHex")
//          Log.d(TAG,"eNBHex $eNBHex")
//          Log.d(TAG, "eNB $eNB")
//
//        }
//      }
//      if (cellInfo is CellInfoGsm){
//        val gsm : CellInfoGsm = cellInfo
//        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
//
//          hashMap["dbm"] = gsm.cellSignalStrength.dbm
//          hashMap["cqi"] = gsm.cellSignalStrength.cqi
//          hashMap["rsrp"] = gsm.cellSignalStrength.rsrp
//          hashMap["rsrq"] = gsm.cellSignalStrength.rsrq
//          hashMap["rssnr"] = gsm.cellSignalStrength.rssnr
//          hashMap["level"] = gsm.cellSignalStrength.level
//          hashMap["rssi"] = gsm.cellSignalStrength.rssi
//          hashMap["cellid"] = gsm.cellIdentity.ci
//
//
//        }
//      }
//    }


    return hashMap
  }


  // Decimal -> hexadecimal
  fun DecToHex(dec: Int): String? {
    return String.format("%x", dec)
  }

  // hex -> decimal
  fun HexToDec(hex: String): Int {
    return hex.toInt(16)
  }

  @TargetApi(Build.VERSION_CODES.KITKAT)
  private fun getPing() : Map<String, Any>{
    val dataNVT: MutableMap<String, Any> = ArrayMap()
    try {
      val runtime = Runtime.getRuntime()
      val process = runtime.exec("ping -s 1024 -c 10 -w 10 8.8.8.8")
      val stdInput = BufferedReader(InputStreamReader(process.inputStream))
      var s: String
      val res = StringBuilder()
      val avgRes = StringBuilder()


      while (stdInput.readLine() != null){
        s = stdInput.readLine()
        if (s.contains("packets transmitted")) {
          Log.d(TAG, "runNVT: ping : $s")
          res.append(s).append("\n")
        }
        if (s.contains("rtt")) {
          Log.d(TAG, "runNVT: get avg res : $s")
          avgRes.append(s).append("\n")
//          pingResult = s;
        }
      }
//      while (stdInput.readLine().also { s = it } != null) {
//
//      }
      stdInput.close()
      process.destroy()
      val percentage: Int = 100 - getPercentage(res.toString())
      Log.d(TAG, "runNVT: get res data from : $avgRes")
      var resNVTTime = "0"
      if (!avgRes.toString().isEmpty() || !avgRes.toString().isEmpty()) {
        resNVTTime = avgRes.toString()
                        resNVTTime = waitingTime(avgRes.toString());
      }
      val df = DateFormat.getDateTimeInstance()
      Log.d(TAG, "runNVT: resNVTTime : $resNVTTime")
      dataNVT["percentage"] = percentage
      dataNVT["resNVT"] = resNVTTime
      dataNVT["nvtTime"] = df.format(Date())

//      pingResult = resNVTTime
    } catch (e: IOException) {
      e.printStackTrace()
//      pingResult = e.printStackTrace().toString()
    }

//    Log.d(TAG, "pingResult : $pingResult")

    return dataNVT

  }

  private fun waitingTime(avgRes: String): String {
    val waitingTimeSplit = avgRes.split("=").toTypedArray()
    Log.d(TAG, "waitingTime " + waitingTimeSplit[0])
    val value = waitingTimeSplit[1].split("/").toTypedArray()
    return value[1]
  }

  private fun getPercentage(ping: String): Int {
    Log.d(TAG, "ping $ping")
    val waitingTime = ping.split(",").toTypedArray()
    val persentase = waitingTime[2]
    val p = Pattern.compile("\\d+")
    val m = p.matcher(persentase)
    var result: String? = null
    while (m.find()) {
      println("ping " + m.group())
      result = m.group()
    }
    return result?.toInt() ?: 0
  }
}
