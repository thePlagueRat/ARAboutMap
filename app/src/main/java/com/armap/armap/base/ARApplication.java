package com.armap.armap.base;

import android.app.Application;

public class ARApplication
        extends Application
{
    private static ARApplication application;

    @Override
    public void onCreate()
    {
        super.onCreate();
        application = this;
    }

    public static ARApplication newInstance()
    {
        return application;
    }
}
