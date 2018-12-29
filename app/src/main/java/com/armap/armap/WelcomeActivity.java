package com.armap.armap;

import android.Manifest;
import android.content.Intent;
import android.net.Uri;
import android.os.Bundle;
import android.os.SystemClock;
import android.provider.Settings;
import android.support.annotation.Nullable;
import android.support.v7.app.AppCompatActivity;
import android.text.TextUtils;
import android.util.Log;
import android.view.View;
import android.webkit.PermissionRequest;

import com.armap.armap.constant.SDKConstant;
import com.armap.armap.dialog.PermissionDialog;
import com.armap.armap.utils.Util;
import com.tbruyelle.rxpermissions2.RxPermissions;
import com.tencent.connect.common.Constants;
import com.tencent.tauth.IUiListener;
import com.tencent.tauth.Tencent;
import com.tencent.tauth.UiError;

import org.json.JSONObject;

public class WelcomeActivity
        extends AppCompatActivity
{
    private Tencent mTencent;


    @Override
    protected void onCreate(@Nullable Bundle savedInstanceState)
    {
        super.onCreate(savedInstanceState);
        // Tencent类是SDK的主要实现类，开发者可通过Tencent类访问腾讯开放的OpenAPI。
        // 其中APP_ID是分配给第三方应用的appid，类型为String。
        mTencent = Tencent.createInstance(SDKConstant.QQ_LOGIN_ID, this.getApplicationContext());
        // 1.4版本:此处需新增参数，传入应用程序的全局context，可通过activity的getApplicationContext方法获取
        // 初始化视图
        requestPermission();
    }

    IUiListener loginListener = new BaseUiListener()
    {
        @Override
        protected void doComplete(JSONObject values)
        {
            Log.d("SDKQQAgentPref", "AuthorSwitch_SDK:" + SystemClock.elapsedRealtime());

        }
    };


    private class BaseUiListener
            implements IUiListener
    {

        @Override
        public void onComplete(Object response)
        {
            if (null == response)
            {
                return;
            }
            JSONObject jsonResponse = (JSONObject)response;
            if (null != jsonResponse && jsonResponse.length() == 0)
            {
                Util.showResultDialog(WelcomeActivity.this, "返回为空", "登录失败");
                return;
            }
            Util.showResultDialog(WelcomeActivity.this, response.toString(), "登录成功");
            doComplete((JSONObject)response);
        }

        protected void doComplete(JSONObject values)
        {

        }

        @Override
        public void onError(UiError e)
        {
            Util.toastMessage(WelcomeActivity.this, "onError: " + e.errorDetail);
            Util.dismissDialog();
        }

        @Override
        public void onCancel()
        {
            Util.toastMessage(WelcomeActivity.this, "onCancel: ");
            Util.dismissDialog();
        }
    }

    public void requestPermission()
    {
        RxPermissions rxPermissions = new RxPermissions(this);
        rxPermissions.requestEachCombined(Manifest.permission.READ_EXTERNAL_STORAGE,
                                          Manifest.permission.READ_PHONE_STATE, Manifest.permission.CAMERA,
                                          Manifest.permission.ACCESS_COARSE_LOCATION, Manifest.permission.ACCESS_FINE_LOCATION)
                     .subscribe(permission ->
                                { // will emit 1 Permission object
                                    if (permission.granted)
                                    {
                                        // All permissions are granted !
                                        //继续流程
                                        mTencent.logout(this);

                                        if (!mTencent.isSessionValid())
                                        {
                                            mTencent.login(this, "", loginListener);
                                        }
                                    }
                                    else if (permission.shouldShowRequestPermissionRationale)
                                    {
                                        // At least one denied permission without ask never again
                                        showPermissionDialog(null, getString(R.string.phone_storage_permission_warn), "知道了", "0");
                                    }
                                    else
                                    {
                                        // At least one denied permission with ask never again
                                        // Need to go to the settings
                                        showPermissionDialog(null, getString(R.string.phone_storage_permission_warn_again), "去设置",
                                                             "1");
                                    }
                                });
    }

    public void showPermissionDialog(final PermissionRequest request, String content, String rightBtnContent, final String type)
    {
        final PermissionDialog dialog = new PermissionDialog(this, content, false, true, null, rightBtnContent);
        dialog.setOnSettingListener(new View.OnClickListener()
        {
            @Override
            public void onClick(View v)
            {
                if ("0".equals(type))
                {
                    requestPermission();
                }
                else
                {
                    Uri packageURI = Uri.parse("package:" + "com.yztv.work");
                    Intent intent = new Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, packageURI);
                    startActivity(intent);
                    finish();
                }
                dialog.dismiss();
            }
        });
        dialog.show();
    }

    @Override
    protected void onActivityResult(int requestCode, int resultCode, Intent data)
    {
        if (requestCode == Constants.REQUEST_LOGIN || requestCode == Constants.REQUEST_APPBAR)
        {
            //            Tencent.onActivityResultData(requestCode, resultCode, data, loginListener);
            startActivity(new Intent(WelcomeActivity.this, MainActivity.class));
            finish();
        }

        super.onActivityResult(requestCode, resultCode, data);
    }
}

