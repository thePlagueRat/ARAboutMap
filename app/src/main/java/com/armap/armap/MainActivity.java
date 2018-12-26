package com.armap.armap;

import android.support.v7.app.AppCompatActivity;
import android.os.Bundle;
import android.view.View;
import android.widget.ImageView;
import android.widget.Toast;
import android.widget.ZoomControls;

import com.baidu.location.BDLocation;
import com.baidu.location.BDLocationListener;
import com.baidu.location.LocationClient;
import com.baidu.location.LocationClientOption;
import com.baidu.mapapi.map.BaiduMap;
import com.baidu.mapapi.map.BitmapDescriptor;
import com.baidu.mapapi.map.BitmapDescriptorFactory;
import com.baidu.mapapi.map.MapStatus;
import com.baidu.mapapi.map.MapStatusUpdateFactory;
import com.baidu.mapapi.map.MapView;
import com.baidu.mapapi.map.Marker;
import com.baidu.mapapi.map.MarkerOptions;
import com.baidu.mapapi.map.MyLocationConfiguration;
import com.baidu.mapapi.map.MyLocationData;
import com.baidu.mapapi.model.LatLng;

public class MainActivity
        extends AppCompatActivity
{
    private MapView mMapView;
    BaiduMap mBaiduMap;
    double mCurrentLat;
    double mCurrentLon;
    double mCurrentAccracy;
    MyLocationData locData;
    float mCurrentDirection;
    boolean isFirstLoc = true;

    // 初始化全局 bitmap 信息，不用时及时 recycle
    private Marker mMarkerA;//定义环球中心marker
    private BitmapDescriptor bdA = BitmapDescriptorFactory.fromResource(R.drawable.location_world);//设置环球中心图标


    @Override
    protected void onCreate(Bundle savedInstanceState)
    {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        mMapView = findViewById(R.id.bmapView);
        // 隐藏logo
        View child = mMapView.getChildAt(1);
        if (child != null && (child instanceof ImageView || child instanceof ZoomControls))
        {
            child.setVisibility(View.INVISIBLE);
        }

        mBaiduMap = mMapView.getMap();
        mBaiduMap.setMyLocationEnabled(true);
        LocationClient mLocClient = new LocationClient(this);
        mLocClient.registerLocationListener(new MyLocationListenner());
        LocationClientOption option = new LocationClientOption();
        option.setOpenGps(true); // 打开gps
        option.setCoorType("bd09ll"); // 设置坐标类型
        option.setScanSpan(1000);
        mLocClient.setLocOption(option);
        mLocClient.start();


        // 设置定位图层的配置（定位模式，是否允许方向信息，用户自定义定位图标）

        BitmapDescriptor mCurrentMarker = BitmapDescriptorFactory.fromResource(R.drawable.icon_geo);
        MyLocationConfiguration.LocationMode mCurrentMode = MyLocationConfiguration.LocationMode.NORMAL;
        MyLocationConfiguration config = new MyLocationConfiguration(mCurrentMode, true, mCurrentMarker);
        mBaiduMap.setMyLocationConfiguration(config);

        // 当不需要定位图层时关闭定位图层
        markGlobalCenter();

        setListener();
    }

    public void markGlobalCenter()
    {
        LatLng locationll = new LatLng(30.574935, 104.070742);
        MarkerOptions ooA = new MarkerOptions().position(locationll).icon(bdA).zIndex(0).draggable(true);
        mMarkerA = (Marker)mBaiduMap.addOverlay(ooA);
    }

    public void setListener()
    {
        mBaiduMap.setOnMarkerClickListener(new BaiduMap.OnMarkerClickListener()
        {
            @Override
            public boolean onMarkerClick(Marker marker)
            {
                if (marker == mMarkerA)
                {
                    Toast.makeText(MainActivity.this, "环球中心", Toast.LENGTH_SHORT).show();
                }
                return false;
            }
        });
    }

    /**
     * 定位SDK监听函数
     */
    public class MyLocationListenner
            implements BDLocationListener
    {

        @Override
        public void onReceiveLocation(BDLocation location)
        {
            // map view 销毁后不在处理新接收的位置
            if (location == null || mMapView == null)
            {
                return;
            }
            mCurrentLat = location.getLatitude();
            mCurrentLon = location.getLongitude();
            mCurrentAccracy = location.getRadius();
            locData = new MyLocationData.Builder().accuracy(location.getRadius())
                                                  // 此处设置开发者获取到的方向信息，顺时针0-360
                                                  .direction(mCurrentDirection).latitude(location.getLatitude())
                                                  .longitude(location.getLongitude()).build();
            mBaiduMap.setMyLocationData(locData);
            if (isFirstLoc)
            {
                isFirstLoc = false;
                LatLng ll = new LatLng(location.getLatitude(), location.getLongitude());
                MapStatus.Builder builder = new MapStatus.Builder();
                builder.target(ll).zoom(18.0f);
                mBaiduMap.animateMapStatus(MapStatusUpdateFactory.newMapStatus(builder.build()));
            }
        }

        public void onReceivePoi(BDLocation poiLocation)
        {
        }
    }

    @Override
    protected void onDestroy()
    {
        super.onDestroy();
        mMapView.onDestroy();
        bdA.recycle();
    }
}
