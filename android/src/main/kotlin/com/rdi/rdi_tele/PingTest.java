package com.rdi.rdi_tele;

import static java.text.DateFormat.getDateTimeInstance;

import android.util.Log;

import androidx.collection.ArrayMap;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.text.DateFormat;
import java.util.Date;
import java.util.Map;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

public class PingTest {

    static final String TAG = "MainActivity";

    public static Map<String, Object> runNVT() {
        Map<String, Object> dataNVT = new ArrayMap<>();
        try {
            Runtime runtime = Runtime.getRuntime();
            Process process = runtime.exec("ping -s 1024 -c 10 -w 10 8.8.8.8");
            BufferedReader stdInput =
                    new BufferedReader(new InputStreamReader(process.getInputStream()));

            String s;
            StringBuilder res = new StringBuilder();
            StringBuilder avgRes = new StringBuilder();
            while ((s = stdInput.readLine()) != null) {
                if (s.contains("packets transmitted")) {
                    Log.d(TAG, "runNVT: ping : " + s);
                    res.append(s).append("\n");
                }
                if (s.contains("rtt")) {
                    Log.d(TAG, "runNVT: get avg res : " + s);
                    avgRes.append(s).append("\n");
                }
            }
            stdInput.close();
            process.destroy();
            int percentage = 100 - getPercentage(res.toString());
            Log.d(TAG, "runNVT: get res data from : " + avgRes.toString());
            String resNVTTime = "0";
            if (!avgRes.toString().isEmpty() || !avgRes.toString().isEmpty()) {
//                resNVTTime = avgRes.toString();
                resNVTTime = waitingTime(avgRes.toString());
            }

            DateFormat df = getDateTimeInstance();

            Log.d(TAG, "runNVT: resNVTTime : " + resNVTTime);
            dataNVT.put("percentage", percentage);
            dataNVT.put("resNVT", resNVTTime);
            dataNVT.put("nvtTime", df.format(new Date()));

        } catch (IOException e) {
            e.printStackTrace();
        }

        return dataNVT;
    }

    private static String waitingTime(String avgRes){
        String[] waitingTimeSplit = avgRes.split("=");
        Log.d(TAG, "waitingTime "+waitingTimeSplit[0]);

        String[] value = waitingTimeSplit[1].split("/");

        return waitingTimeSplit[1];
    }

    private static int getPercentage(String ping) {
        Log.d(TAG, "ping "+ping);
        String[] waitingTime = ping.split(",");
        String persentase = waitingTime[2];
        Pattern p = Pattern.compile("\\d+");
        Matcher m = p.matcher(persentase);

        String result = null;
        while (m.find()) {
            System.out.println("ping " + m.group());
            result = m.group();
        }

        return result != null ? Integer.parseInt(result) : 0;
    }
}
