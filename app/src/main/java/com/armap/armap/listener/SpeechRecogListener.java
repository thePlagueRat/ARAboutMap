/*
 * Copyright (C) 2018 Baidu, Inc. All Rights Reserved.
 */
package com.armap.armap.listener;

/**
 * 语音识别回调接口
 */
public interface SpeechRecogListener {
    void onSpeechRecog(int status, String result);
}
