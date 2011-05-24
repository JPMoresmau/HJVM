#include <jni.h>

#ifndef HJVM_H
#define HJVM_H

typedef void (eventCallback)(jint index,jobject event);

struct runtime {
	JavaVM *jvm;
	JNIEnv *env;
};

int start(char* classpath,eventCallback f);

void end();

jclass findClass(const char *name);

jobject newObject(const jclass cls, const char *signature,const jvalue *args);

jint callIntMethod(const jobject obj,const char *method,const char *signature,const jvalue *args);

void callVoidMethod(const jobject obj,const char *method,const char *signature,const jvalue *args);

jboolean callBooleanMethod(const jobject obj,const char *method,const char *signature,const jvalue *args);

jstring newString(const jchar *unicode, jsize len);

#endif
