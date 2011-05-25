#include <jni.h>

#ifndef HJVM_H
#define HJVM_H

typedef void (*eventCallback)(JNIEnv *env, jobject listener,jint index,jobject event);

struct runtime_  {
	JavaVM *jvm;
	JNIEnv *env;
} ;

typedef struct runtime_ *runtime;

runtime start(char* classpath);

void end(runtime rt);

jclass findClass(const runtime rt,const char *name);

void registerCallback(const runtime rt,const char *clsName,const char *methodName,const char *eventClsName,eventCallback f);

jobject newObject(const runtime rt,const jclass cls, const char *signature,const jvalue *args);

jint callIntMethod(const runtime rt,const jobject obj,const char *method,const char *signature,const jvalue *args);

void callVoidMethod(const runtime rt,const jobject obj,const char *method,const char *signature,const jvalue *args);

jboolean callBooleanMethod(const runtime rt,const jobject obj,const char *method,const char *signature,const jvalue *args);

jstring newString(const runtime rt,const jchar *unicode, jsize len);

#endif
