package com.chrisbjohnson.fluttercalendarplugin;

public interface PermissionCallback
{
    void granted(int requestCode);
    void denied();
}