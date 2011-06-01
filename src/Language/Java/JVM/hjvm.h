#include <jni.h>

#ifndef HJVM_H
#define HJVM_H

typedef void (*eventCallback)(JNIEnv *env, jobject listener,jint index,jobject event);

/*struct runtime_  {
	JavaVM *jvm;
	JNIEnv *env;
} ;*/

//typedef struct runtime_ *runtime;

jint start(char* classpath);

void end();

jclass findClass(const char *name);

void registerCallback(const char *clsName,const char *methodName,const char *eventClsName,eventCallback f);

jobject newObject(const jclass cls, const char *signature,const jvalue *args);

jint callIntMethod(const jobject obj,const char *method,const char *signature,const jvalue *args);

void callVoidMethod(const jobject obj,const char *method,const char *signature,const jvalue *args);

jboolean callBooleanMethod(const jobject obj,const char *method,const char *signature,const jvalue *args);

jstring newString(const jchar *unicode, jsize len);

#endif
