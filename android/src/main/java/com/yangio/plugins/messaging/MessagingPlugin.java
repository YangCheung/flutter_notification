// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package com.yangio.plugins.messaging;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.os.Bundle;
import android.util.Log;

import com.umeng.message.PushAgent;
import com.umeng.message.UTrack;

import org.json.JSONException;
import org.json.JSONObject;

import androidx.localbroadcastmanager.content.LocalBroadcastManager;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry.NewIntentListener;
import io.flutter.plugin.common.PluginRegistry.Registrar;

import java.util.HashMap;
import java.util.Iterator;
import java.util.Map;

/**
 * MessagingPlugin
 */
public class MessagingPlugin extends BroadcastReceiver
        implements MethodCallHandler, NewIntentListener {
    private final Registrar registrar;
    private final MethodChannel channel;

    private static final String PUSH_TOKEN_ACTION_VALUE = "PUSH_TOKEN_ACTION_VALUE";

    private static final String TAG = "MessagingPlugin";

    private String deviceToken;
    private String pendingAlias;

    public static void registerWith(Registrar registrar) {
        final MethodChannel channel = new MethodChannel(registrar.messenger(), "com.yangio.plugin/messaging");
        final MessagingPlugin plugin = new MessagingPlugin(registrar, channel);
        registrar.addNewIntentListener(plugin);
        channel.setMethodCallHandler(plugin);
    }

    private MessagingPlugin(Registrar registrar, MethodChannel channel) {
        this.registrar = registrar;
        this.channel = channel;

        deviceToken = PushAgent.getInstance(registrar.context()).getRegistrationId();
        if (deviceToken == null || deviceToken.isEmpty()) {
            IntentFilter intentFilter = new IntentFilter();
            intentFilter.addAction(PUSH_TOKEN_ACTION_VALUE);
            LocalBroadcastManager manager = LocalBroadcastManager.getInstance(registrar.context());
            manager.registerReceiver(this, intentFilter);
        }
    }

    @Override
    public void onReceive(Context context, Intent intent) {
        String action = intent.getAction();
        if (PUSH_TOKEN_ACTION_VALUE.equals(action)) {
            if (intent.getExtras() != null) {
                deviceToken = intent.getExtras().getString("token");
                Log.d(TAG, "receive device token " + deviceToken);
                if (pendingAlias != null) {
                    Log.d(TAG, "set pending alias " + pendingAlias);
                    setAlias(pendingAlias);
                    pendingAlias = null;
                }
            }
        }
    }

    private void setAlias(String alias) {
        if (deviceToken != null) {
            PushAgent.getInstance(registrar.context()).setAlias(alias, "uid", new UTrack.ICallBack() {
                @Override
                public void onMessage(boolean isSuccess, String message) {
                    Log.d(TAG, "setAlias isSuccess " + isSuccess + "; message = " + message);
                }
            });
        } else {
            Log.d(TAG, "deviceToken token is null, set pending alias " + pendingAlias);
            pendingAlias = alias;
        }
    }

    @Override
    public void onMethodCall(final MethodCall call, final Result result) {
        if ("configure".equals(call.method)) {
            if (registrar.activity() != null) {
                sendMessageFromIntent("onLaunch", registrar.activity().getIntent());
            }
            result.success(null);
        } else if ("setAlias".equals(call.method)) {
            if (call.arguments instanceof String) {
                setAlias((String) call.arguments);
            }
            result.success(null);
        } else if ("removeAlias".equals(call.method)) {
            if (call.arguments instanceof String) {
                String alias = (String) call.arguments;
                PushAgent.getInstance(registrar.context()).deleteAlias(alias, "uid", new UTrack.ICallBack() {
                    @Override
                    public void onMessage(boolean isSuccess, String message) {
                    }
                });
            }
            result.success(null);
        } else {
            result.notImplemented();
        }
    }

    @Override
    public boolean onNewIntent(Intent intent) {
        boolean res = sendMessageFromIntent("onResume", intent);
        if (res && registrar.activity() != null) {
            registrar.activity().setIntent(intent);
        }
        return res;
    }

    /**
     * @return true if intent contained a message to send.
     */
    private boolean sendMessageFromIntent(String method, Intent intent) {
        Bundle extras = intent.getExtras();
        if (extras == null) {
            return false;
        }

        Map<String, Object> dataMap = new HashMap<>();
        for (String key : extras.keySet()) {
            Object extra = extras.get(key);
            if (extra != null) {
                if (extra instanceof String && key.equals("extra")) {
                    try {
                        JSONObject jsonObject = new JSONObject((String) extra);
                        Iterator<String> keys = jsonObject.keys();
                        Map<String, Object> jsonMap = new HashMap<>();
                        while (keys.hasNext()) {
                            String jsonKey = keys.next();
                            jsonMap.put(jsonKey, jsonObject.get(jsonKey));
                        }
                        dataMap.put(key, jsonMap);
                    } catch (JSONException e) {
                        Log.e(TAG, e.toString());
                    }

                } else {
                    dataMap.put(key, extra);
                }
            }
        }

        channel.invokeMethod(method, dataMap);
        return true;
    }
}
