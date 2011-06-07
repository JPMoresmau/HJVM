#include <jni.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "hjvm.h"


/*eventCallback *eventCb;

void event(JNIEnv *env, jobject listener,jint index,jobject event){
	eventCb(index,event);
}*/

JavaVM *getJVM(){
	JavaVM *jvm;
	jsize vmnb;
	JNI_GetCreatedJavaVMs(&jvm,1,&vmnb);
	return jvm;
}

JNIEnv* getEnv(JavaVM *jvm){
	JNIEnv *env;
	(*jvm)->AttachCurrentThread(jvm,(void**)&env,NULL);
	return env;
}

jint start(char* classpath){
     jint res;
     JNIEnv *env;
     JavaVM *jvm;
     JavaVMInitArgs vm_args;
     JavaVMOption options[1];
     jsize vmnb;
     //runtime rt=(runtime)malloc(sizeof(runtime*));
     //jclass nativeListener;
     res = JNI_GetCreatedJavaVMs(&jvm,1,&vmnb);
     if (res<0){
    	 return res;
     }
     if (vmnb<1){

		 options[0].optionString =classpath;
		 vm_args.version = JNI_VERSION_1_4; //0x00010002;
		 vm_args.options = options;
		 vm_args.nOptions = 1;
		 vm_args.ignoreUnrecognized = JNI_TRUE;
		 /* Create the Java VM */
		 return JNI_CreateJavaVM(&jvm, (void**)&env, &vm_args);
     }
//	 if (res<0){
//		 return NULL;
//	 }
	// rt->env=env;
	// rt->jvm=jvm;
	// eventCb=f;

	// nativeListener=findClass(rt,"Language/Java/SWT/NativeListener");
	// (*env)->RegisterNatives(env,nativeListener, methods, 1);


	 return 0;
}

void registerCallback(const char *clsName,const char *methodName,const char *eventClsName,eventCallback f){
	int length=3+(strlen(eventClsName))+3;
	char *signature;
	jclass cls;
	JNINativeMethod methods[1] ;
	JNINativeMethod* m=malloc(sizeof(JNINativeMethod));
	char *methodcpy=(char *)malloc(sizeof(char) * (strlen(methodName)+1));
	JNIEnv *env=getEnv(getJVM());
	cls=findClass(clsName);

	methodcpy=
	strcpy(methodcpy,methodName);

	signature = (char *)malloc(sizeof(char) * (length+1));
	strcpy(signature,"(IL");
	strcat(signature,eventClsName);
	strcat(signature,";)V");

	m->name= methodcpy;
	m->signature= signature;
	m->fnPtr= f;
	methods[0]=*m;

	(*env)->RegisterNatives(env, cls,methods,1);

	free(m);
	free(methodcpy);
	free(signature);
}

void end(){
	JavaVM* jvm=getJVM();
	(*jvm)->DestroyJavaVM(jvm);
//	free(rt->env);
//	free(rt);
}

jclass findClass(const char *name){
	JNIEnv *env=getEnv(getJVM());
	return (*env)->FindClass(env, name);
}

jmethodID findMethod(const jclass cls,const char *method,const char *signature){
	JNIEnv *env=getEnv(getJVM());
	jmethodID mid;
	mid=(*env)->GetMethodID(env, cls, method,
			 signature);
	(*env)->ExceptionClear(env);
	return mid;
}

void handleException(JNIEnv *env,jchar *error){
	jclass cls;
	jmethodID mid;
	jvalue args[0];
	jobject msgO;
	jthrowable exc = (*env)->ExceptionOccurred(env);
	jboolean isCopy;
	const jchar* msg;
	if (exc) {
		cls=findClass("java/lang/Throwable");
		mid=findMethod(cls,"getLocalizedMessage","()Ljava/lang/String;");
		msgO=(*env)->CallObjectMethodA (env,exc,mid,args);
		msg=(*env)->GetStringChars(env,msgO,&isCopy);
		while(*msg != 0) {
			*error++ = *msg++;
		}
		*error =0;
		(*env)->ExceptionClear(env);
	} else {
		*error=0;
	}
}

jobject newObject(const jclass cls, const jmethodID method,const jvalue *args,jchar *error){
	JNIEnv *env=getEnv(getJVM());
	jobject jo;
    if (cls == NULL || method== NULL) {
         return NULL;
    }
    jo=(*env)->NewObjectA(env,cls,method,args);
    handleException(env,error);
    return jo;
}


/*jmethodID getMethodID(JNIEnv *env,const jobject obj,const char *method,const char *signature){
	jclass cls;
	jmethodID mid;
	if (obj==NULL){
		return NULL;
	}
	cls=(*env)->GetObjectClass(env, obj);
	if (cls==NULL){
		return NULL;
	}
	mid = (*env)->GetMethodID(env, cls, method,
										 signature);
	return mid;
}*/

jint callIntMethod(const jobject obj,const jmethodID method,const jvalue *args,jchar *error){
	JNIEnv *env=getEnv(getJVM());
	jint ret=(*env)-> CallIntMethodA (env,obj,method,args);
	handleException(env,error);
	return ret;
}

jchar callCharMethod(const jobject obj,const jmethodID method,const jvalue *args,jchar *error){
	JNIEnv *env=getEnv(getJVM());
	jchar ret=(*env)-> CallCharMethodA (env,obj,method,args);
	handleException(env,error);
	return ret;
}

jshort callShortMethod(const jobject obj,const jmethodID method,const jvalue *args,jchar *error){
	JNIEnv *env=getEnv(getJVM());
	jmethodID mid;
	jshort ret=(*env)-> CallShortMethodA (env,obj,method,args);
	handleException(env,error);
	return ret;
}

jbyte callByteMethod(const jobject obj,const jmethodID method,const jvalue *args,jchar *error){
	JNIEnv *env=getEnv(getJVM());
	jmethodID mid;
	jbyte ret=(*env)-> CallByteMethodA (env,obj,method,args);
	handleException(env,error);
	return ret;
}

jlong callLongMethod(const jobject obj,const jmethodID method,const jvalue *args,jchar *error){
	JNIEnv *env=getEnv(getJVM());
	jlong ret=(*env)-> CallLongMethodA (env,obj,method,args);
	handleException(env,error);
	return ret;
}

jfloat callFloatMethod(const jobject obj,const jmethodID method,const jvalue *args,jchar *error){
	JNIEnv *env=getEnv(getJVM());
	jfloat ret=(*env)-> CallFloatMethodA (env,obj,method,args);
	handleException(env,error);
	return ret;
}

jdouble callDoubleMethod(const jobject obj,const jmethodID method,const jvalue *args,jchar *error){
	JNIEnv *env=getEnv(getJVM());
	jdouble ret=(*env)-> CallDoubleMethodA (env,obj,method,args);
	handleException(env,error);
	return ret;
}

jboolean callBooleanMethod(const jobject obj,const jmethodID method,const jvalue *args,jchar *error){
	JNIEnv *env=getEnv(getJVM());
	jboolean ret=(*env)-> CallBooleanMethodA (env,obj,method,args);
	handleException(env,error);
	return ret;
}

void callVoidMethod(const jobject obj,const jmethodID method,const jvalue *args,jchar *error){
	JNIEnv *env=getEnv(getJVM());
	(*env)-> CallVoidMethodA (env,obj,method,args);
	handleException(env,error);
}

jobject callObjectMethod(const jobject obj,const jmethodID method,const jvalue *args,jchar *error){
	JNIEnv *env=getEnv(getJVM());
	jobject ret=(*env)-> CallObjectMethodA (env,obj,method,args);
	handleException(env,error);
	return ret;
}

jstring newString(const jchar *unicode, jsize len,jchar *error){
	JNIEnv *env=getEnv(getJVM());
	jstring ret=(*env)->NewString(env,unicode,len);
	handleException(env,error);
	return ret;
}

/*
int test(int jvmid){
	 jclass cls;
     jmethodID mid;
     jstring jstr;
     jclass stringClass;
     jobjectArray args;
  
     cls = (*env)->FindClass(env, "Prog");
     if (cls == NULL) {
         return -1;
     }
 
     mid = (*env)->GetStaticMethodID(env, cls, "main",
                                     "([Ljava/lang/String;)V");
     if (mid == NULL) {
         return -2;
     }
     jstr = (*env)->NewStringUTF(env, "from C and Haskell!");
     if (jstr == NULL) {
        return -3;
     }
     stringClass = (*env)->FindClass(env, "java/lang/String");
     args = (*env)->NewObjectArray(env, 1, stringClass, jstr);
     if (args == NULL) {
         return -4;
     }
     (*env)->CallStaticVoidMethod(env, cls, mid, args);
	 return 0;
}

long create(){
	jclass cls;
	jmethodID mid;
	jobject obj;
	jint i;
	cls = (*env)->FindClass(env, "Prog");
    if (cls == NULL) {
         return -1;
    }
    mid = (*env)->GetMethodID(env, cls, "<init>",
                                     "()V");
    if (mid == NULL){
    	return -2;
    }               
    obj = (*env)->NewObject(env,cls,mid);
    mid = (*env)->GetMethodID(env, cls, "getMethod",
                                     "()I");
    if (mid == NULL){
    	return -3;
    }           
    i = (*env)-> CallIntMethod (env,obj,mid);
   	return i;
          
}*/

