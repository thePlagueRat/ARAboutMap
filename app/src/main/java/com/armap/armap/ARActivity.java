package com.armap.armap;

import android.Manifest;
import android.app.Activity;
import android.content.Context;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.net.Uri;
import android.os.AsyncTask;
import android.os.Build;
import android.os.Bundle;
import android.os.Environment;
import android.os.Handler;
import android.os.Message;
import android.os.PersistableBundle;
import android.support.annotation.Nullable;
import android.support.v4.app.FragmentActivity;
import android.support.v4.app.FragmentManager;
import android.support.v4.app.FragmentTransaction;
import android.widget.Toast;

import com.armap.armap.utils.AssetsCopyToSdcard;
import com.baidu.ar.ARFragment;
import com.baidu.ar.constants.ARConfigKey;
import com.baidu.ar.external.ARCallbackClient;

import org.json.JSONException;
import org.json.JSONObject;

import java.lang.ref.WeakReference;
import java.util.ArrayList;
import java.util.List;

public class ARActivity
        extends FragmentActivity
{

    private boolean mIsDenyAllPermission = false;

    // 权限请求相关
    private static final String[] ALL_PERMISSIONS = new String[]{Manifest.permission.WRITE_EXTERNAL_STORAGE,};

    private Intent intent;
    private ARFragment mARFragment;
    public static final String ASSETS_CASE_FOLDER = "ardebug";
    private FragmentTransaction fragmentTransaction = getSupportFragmentManager().beginTransaction();
    public static final String DEFAULT_PATH = Environment.getExternalStorageDirectory().toString() + "/" + ASSETS_CASE_FOLDER;
    private static final int REQUEST_CODE_ASK_ALL_PERMISSIONS = 154;
    private Handler handler=new Handler(){
        @Override
        public void handleMessage(Message msg)
        {
            super.handleMessage(msg);
            showAr();
        }
    };

    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.ar_activity);
        if (findViewById(R.id.bdar_id_fragment_container) != null) {
            requestAllPermissions(REQUEST_CODE_ASK_ALL_PERMISSIONS);
        }
    }




    @Override
    protected void onResume()
    {
        super.onResume();
    }

    @Override
    protected void onStart()
    {
        super.onStart();

    }

    /**
     * 请求权限
     *
     * @param requestCode
     */
    private void requestAllPermissions(int requestCode)
    {
        try
        {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M)
            {
                List<String> permissionsList = getRequestPermissions(this);
                if (permissionsList.size() == 0)
                {
                    Toast.makeText(this, "正在拷贝资源", Toast.LENGTH_SHORT).show();
                    new CopyFileTask(intent, this).execute();
                    return;
                }
                if (!mIsDenyAllPermission)
                {
                    requestPermissions(permissionsList.toArray(new String[permissionsList.size()]), requestCode);
                }
            }
            else
            {
                Toast.makeText(this, "正在拷贝资源", Toast.LENGTH_SHORT).show();
                new CopyFileTask(intent, this).execute();
            }
        }
        catch (Exception e)
        {
            e.printStackTrace();
        }
    }

    private static List<String> getRequestPermissions(Activity activity)
    {
        List<String> permissionsList = new ArrayList();
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M)
        {
            for (String permission : ALL_PERMISSIONS)
            {
                if (activity.checkSelfPermission(permission) != PackageManager.PERMISSION_GRANTED)
                {
                    permissionsList.add(permission);
                }
            }
        }
        return permissionsList;
    }

    public static class CopyFileTask
            extends AsyncTask
    {
        private final Intent intent;
        private final WeakReference<Activity> contextRef;

        public CopyFileTask(Intent intent, Activity context)
        {
            this.intent = intent;
            this.contextRef = new WeakReference<>(context);
        }

        @Override
        protected Object doInBackground(Object[] objects)
        {
            Context context = contextRef.get();
            if (context != null)
            {
                AssetsCopyToSdcard assetsCopyTOSDcard = new AssetsCopyToSdcard(context);
                assetsCopyTOSDcard.assetToSD(ASSETS_CASE_FOLDER, DEFAULT_PATH);
            }
            return null;
        }

        @Override
        protected void onPostExecute(Object o)
        {
            if (contextRef.get() != null)
            {
                Toast.makeText(contextRef.get(), "拷贝完成", Toast.LENGTH_SHORT).show();
//                ((ARActivity)contextRef.get()).showAr();
                ((ARActivity)contextRef.get()).handler.postDelayed(new Runnable()
                {
                    @Override
                    public void run()
                    {
                        ((ARActivity)contextRef.get()).showAr();
                    }
                },1000);
            }
        }
    }

    @Override
    public void onRequestPermissionsResult(int requestCode, String[] permissions, int[] grantResults)
    {
        if (requestCode == REQUEST_CODE_ASK_ALL_PERMISSIONS)
        {
            mIsDenyAllPermission = false;
            for (int i = 0; i < permissions.length; i++)
            {
                if (i >= grantResults.length || grantResults[i] == PackageManager.PERMISSION_DENIED)
                {
                    mIsDenyAllPermission = true;
                    break;
                }
            }
            Toast.makeText(this, "正在拷贝资源", Toast.LENGTH_SHORT).show();
            new CopyFileTask(intent, this).execute();
            if (mIsDenyAllPermission)
            {
                //                finish();
            }
        }

    }

    public void showAr()
    {
        Bundle data = new Bundle();
        JSONObject jsonObj = new JSONObject();
        try
        {
            jsonObj.put(ARConfigKey.AR_TYPE, "6");
            // 当加载云端AR内容时，需传入AR内容平台生成的ar_key
            jsonObj.put(ARConfigKey.AR_KEY, "");
            // 当加载本地AR内容时，需传入ar_path
            jsonObj.put(ARConfigKey.AR_PATH, null);
        }
        catch (JSONException e)
        {
            e.printStackTrace();
        }
        data.putString(ARConfigKey.AR_VALUE, jsonObj.toString());
        mARFragment = new ARFragment();
        mARFragment.setArguments(data);
        mARFragment.setARCallbackClient(new ARCallbackClient() {
            // 分享接口
            @Override
            public void share(String title, String content, String shareUrl, String resUrl, int type) {
                // type = 1 视频，type = 2 图片
                Intent shareIntent = new Intent();
                shareIntent.setAction(Intent.ACTION_SEND);
                shareIntent.putExtra(Intent.EXTRA_TEXT, content);
                shareIntent.putExtra(Intent.EXTRA_TITLE, title);
                shareIntent.setType("text/plain");
                // 设置分享列表的标题，并且每次都显示分享列表
                try {
                    startActivity(Intent.createChooser(shareIntent, "分享到"));
                } catch (Exception e) {
                    e.printStackTrace();
                }
            }

            // 透传url接口：当AR Case中需要传出url时通过该接口传出url
            @Override
            public void openUrl(String url) {
                Intent intent = new Intent();
                intent.setAction("android.intent.action.VIEW");
                Uri contentUrl = Uri.parse(url);
                intent.setData(contentUrl);
                try {
                    startActivity(intent);
                } catch (Exception e) {
                    e.printStackTrace();
                }
            }

            // AR黑名单回调接口：当手机不支持AR时，通过该接口传入退化H5页面的url
            @Override
            public void nonsupport(String url) {
                Intent intent = new Intent();
                intent.setAction("android.intent.action.VIEW");
                Uri contentUrl = Uri.parse(url);
                intent.setData(contentUrl);
                try {
                    ARActivity.this.finish();
                    startActivity(intent);
                } catch (Exception e) {
                    e.printStackTrace();
                }
            }
        });
        // 将trackArFragment设置到布局上
        fragmentTransaction.replace(R.id.bdar_id_fragment_container, mARFragment);
        fragmentTransaction.commitAllowingStateLoss();
    }
}
