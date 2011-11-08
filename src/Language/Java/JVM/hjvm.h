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


void freeClass(jclass global);
void freeObject(jobject global);

jclass findClass(const char *name);
jmethodID findMethod(const jclass cls,const char *method,const char *signature);
jmethodID findStaticMethod(const jclass cls,const char *method,const char *signature);
jfieldID findField(const jclass cls,const char *name,const char *signature);
jfieldID findStaticField(const jclass cls,const char *name,const char *signature);

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

jint callStaticIntMethod(const jclass cls,const jmethodID method,const jvalue *args,jchar *error);
void callStaticVoidMethod(const jclass cls,const jmethodID method,const jvalue *args,jchar *error);
jboolean callStaticBooleanMethod(const jclass cls,const jmethodID method,const jvalue *args,jchar *error);
jchar callStaticCharMethod(const jclass cls,const jmethodID method,const jvalue *args,jchar *error);
jshort callStaticShortMethod(const jclass cls,const jmethodID method,const jvalue *args,jchar *error);
jbyte callStaticByteMethod(const jclass cls,const jmethodID method,const jvalue *args,jchar *error);
jlong callStaticLongMethod(const jclass cls,const jmethodID method,const jvalue *args,jchar *error);
jdouble callStaticDoubleMethod(const jclass cls,const jmethodID method,const jvalue *args,jchar *error);
jfloat callStaticFloatMethod(const jclass cls,const jmethodID method,const jvalue *args,jchar *error);
jobject callStaticObjectMethod(const jclass cls,const jmethodID method,const jvalue *args,jchar *error);

jint getStaticIntField(const jclass cls,const jfieldID field,jchar *error);
jboolean getStaticBooleanField(const jclass cls,const jfieldID field,jchar *error);
jchar getStaticCharField(const jclass cls,const jfieldID field,jchar *error);
jshort getStaticShortField(const jclass cls,const jfieldID field,jchar *error);
jbyte getStaticByteField(const jclass cls,const jfieldID field,jchar *error);
jlong getStaticLongField(const jclass cls,const jfieldID field,jchar *error);
jdouble getStaticDoubleField(const jclass cls,const jfieldID field,jchar *error);
jfloat getStaticFloatField(const jclass cls,const jfieldID field,jchar *error);
jobject getStaticObjectField(const jclass cls,const jfieldID field,jchar *error);

#endif
