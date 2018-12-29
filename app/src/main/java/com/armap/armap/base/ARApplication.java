package com.armap.armap.base;

import android.app.Application;

import com.armap.armap.constant.SDKConstant;
import com.baidu.ar.bean.DuMixARConfig;
import com.baidu.ar.util.Res;
import com.baidu.mapapi.CoordType;
import com.baidu.mapapi.SDKInitializer;

public class ARApplication
        extends Application
{
    private static ARApplication application;


    @Override
    public void onCreate()
    {
        super.onCreate();
        application = this;
        //在使用SDK各组件之前初始化context信息，传入ApplicationContext
        SDKInitializer.initialize(this);
        //自4.3.0起，百度地图SDK所有接口均支持百度坐标和国测局坐标，用此方法设置您使用的坐标类型.
        //包括BD09LL和GCJ02两种坐标，默认是BD09LL坐标。
        SDKInitializer.setCoordType(CoordType.BD09LL);

        // 设置获取资源的上下文Context
        Res.addResource(this);
        // 设置App Id
        DuMixARConfig.setAppId(SDKConstant.AR_APP_ID);
        // 设置API Key
        DuMixARConfig.setAPIKey(SDKConstant.AR_API_KEY);
        // 设置Secret Key
        DuMixARConfig.setSecretKey(SDKConstant.AR_SECRET_KEY);
    }

    public static ARApplication newInstance()
    {
        return application;
    }
}
