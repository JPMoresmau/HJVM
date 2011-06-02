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
	return (*env)->GetMethodID(env, cls, method,
			 signature);
}

jobject newObject(const jclass cls, const char *signature,const jvalue *args){
	JNIEnv *env=getEnv(getJVM());
	jmethodID mid;
    if (cls == NULL) {
         return NULL;
    }
    mid = (*env)->GetMethodID(env, cls, "<init>",
    		signature);
    if (mid == NULL){
    	return NULL;
    }
    return (*env)->NewObjectA(env,cls,mid,args);
}


jmethodID getMethodID(JNIEnv *env,const jobject obj,const char *method,const char *signature){
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
}

jint callIntMethod(const jobject obj,const jmethodID method,const jvalue *args){
	JNIEnv *env=getEnv(getJVM());
	return(*env)-> CallIntMethodA (env,obj,method,args);
}

jchar callCharMethod(const jobject obj,const jmethodID method,const jvalue *args){
	JNIEnv *env=getEnv(getJVM());
	return (*env)-> CallCharMethodA (env,obj,method,args);
}

jshort callShortMethod(const jobject obj,const jmethodID method,const jvalue *args){
	JNIEnv *env=getEnv(getJVM());
	jmethodID mid;
	return (*env)-> CallShortMethodA (env,obj,method,args);
}

jbyte callByteMethod(const jobject obj,const jmethodID method,const jvalue *args){
	JNIEnv *env=getEnv(getJVM());
	jmethodID mid;
	return (*env)-> CallByteMethodA (env,obj,method,args);
}

jlong callLongMethod(const jobject obj,const jmethodID method,const jvalue *args){
	JNIEnv *env=getEnv(getJVM());
	return (*env)-> CallLongMethodA (env,obj,method,args);
}

jfloat callFloatMethod(const jobject obj,const jmethodID method,const jvalue *args){
	JNIEnv *env=getEnv(getJVM());
	return (*env)-> CallFloatMethodA (env,obj,method,args);
}

jdouble callDoubleMethod(const jobject obj,const jmethodID method,const jvalue *args){
	JNIEnv *env=getEnv(getJVM());
	return (*env)-> CallDoubleMethodA (env,obj,method,args);
}

jboolean callBooleanMethod(const jobject obj,const jmethodID method,const jvalue *args){
	JNIEnv *env=getEnv(getJVM());
	return (*env)-> CallBooleanMethodA (env,obj,method,args);
}


void callVoidMethod(const jobject obj,const jmethodID method,const jvalue *args){
	JNIEnv *env=getEnv(getJVM());
	(*env)-> CallVoidMethodA (env,obj,method,args);
}

jstring newString(const jchar *unicode, jsize len){
	JNIEnv *env=getEnv(getJVM());
	return (*env)->NewString(env,unicode,len);
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

