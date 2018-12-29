package com.armap.armap.dialog;

import android.app.Dialog;
import android.content.Context;
import android.content.DialogInterface;
import android.os.Bundle;
import android.text.TextUtils;
import android.util.DisplayMetrics;
import android.view.KeyEvent;
import android.view.View;
import android.view.WindowManager;
import android.widget.TextView;

import com.armap.armap.R;


/**
 * Created by Administrator on 2018/10/30 0030.
 */

public class PermissionDialog
        extends Dialog
{
    private TextView cancel_setting_tv;
    private TextView setting_tv;
    private TextView content_tv;

    private String contentMsg;
    private String leftBtnContent;
    private String rightBtnContent;
    private boolean leftBtn;
    private boolean rightBtn;

    public PermissionDialog(Context context, String contentMsg, boolean leftBtn, boolean rightBtn, String leftBtnContent,
                            String rightBtnContent)
    {
        super(context, R.style.permission_dialog_style);
        this.contentMsg = contentMsg;
        this.leftBtn = leftBtn;
        this.rightBtn = rightBtn;
        this.leftBtnContent = leftBtnContent;
        this.rightBtnContent = rightBtnContent;
        setContentView(R.layout.layout_permission_dialog);
        setCanceledOnTouchOutside(false);
        DisplayMetrics displayMetrics = new DisplayMetrics();
        WindowManager.LayoutParams params = getWindow().getAttributes();
        getWindow().getWindowManager().getDefaultDisplay().getMetrics(displayMetrics);
        params.width = (int)(displayMetrics.widthPixels * 0.65);
        getWindow().setAttributes(params);
        initView();
    }

    @Override
    protected void onCreate(Bundle savedInstanceState)
    {
        super.onCreate(savedInstanceState);
    }

    public void initView()
    {
        cancel_setting_tv = (TextView)findViewById(R.id.cancel_setting_tv);
        setting_tv = (TextView)findViewById(R.id.setting_tv);
        content_tv = (TextView)findViewById(R.id.content_tv);

        if (!TextUtils.isEmpty(contentMsg))
        {
            content_tv.setText(contentMsg);
        }
        if (!TextUtils.isEmpty(leftBtnContent))
        {
            cancel_setting_tv.setText(leftBtnContent);
        }
        if (!TextUtils.isEmpty(rightBtnContent))
        {
            setting_tv.setText(rightBtnContent);
        }
        if (leftBtn)
        {
            cancel_setting_tv.setVisibility(View.VISIBLE);
        }
        else
        {
            cancel_setting_tv.setVisibility(View.INVISIBLE);
        }
        if (rightBtn)
        {
            setting_tv.setVisibility(View.VISIBLE);
        }
        else
        {
            setting_tv.setVisibility(View.INVISIBLE);
        }
        setOnKeyListener(new OnKeyListener()
        {
            @Override
            public boolean onKey(DialogInterface dialog, int keyCode, KeyEvent event)
            {
                if (keyCode == KeyEvent.KEYCODE_BACK)
                {
                    return true;
                }
                return false;
            }
        });
    }

    public void setOnCancelSettingListener(final CommonListener listener)
    {
        cancel_setting_tv.setOnClickListener(new View.OnClickListener()
        {
            @Override
            public void onClick(View v)
            {
                listener.response(true);
                dismiss();
            }
        });
    }

    public void setOnSettingListener(View.OnClickListener listener)
    {
        setting_tv.setOnClickListener(listener);
    }

    public interface CommonListener<T>{
        void response(T t);
    }
}
