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

jmethodID findMethod(const jclass cls,const char *method,const char *signature);

void registerCallback(const char *clsName,const char *methodName,const char *eventClsName,eventCallback f);

jobject newObject(const jclass cls, const jmethodID method,const jvalue *args,jchar *error);

jstring newString(const jchar *unicode, jsize len,jchar *error);

jint callIntMethod(const jobject obj,const jmethodID method,const jvalue *args,jchar *error);

void callVoidMethod(const jobject obj,const jmethodID method,const jvalue *args,jchar *error);

jboolean callBooleanMethod(const jobject obj,const jmethodID method,const jvalue *args,jchar *error);

jchar callCharMethod(const jobject obj,const jmethodID method,const jvalue *args,jchar *error);

jshort callShortMethod(const jobject obj,const jmethodID method,const jvalue *args,jchar *error);

jbyte callByteMethod(const jobject obj,const jmethodID method,const jvalue *args,jchar *error);

jlong callLongMethod(const jobject obj,const jmethodID method,const jvalue *args,jchar *error);

jdouble callDoubleMethod(const jobject obj,const jmethodID method,const jvalue *args,jchar *error);

jfloat callFloatMethod(const jobject obj,const jmethodID method,const jvalue *args,jchar *error);

jobject callObjectMethod(const jobject obj,const jmethodID method,const jvalue *args,jchar *error);


#endif
