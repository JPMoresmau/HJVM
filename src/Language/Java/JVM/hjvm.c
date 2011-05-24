#include <jni.h>
#include <stdio.h>
#include <stdlib.h>

#include "hjvm.h"


eventCallback *eventCb;

void event(JNIEnv *env, jobject listener,jint index,jobject event){
	eventCb(index,event);
}

runtime start(char* classpath,eventCallback f){
     jint res;
     JNIEnv *env;
     JavaVM *jvm;
     JavaVMInitArgs vm_args;
     JavaVMOption options[1];
     runtime rt=(runtime)malloc(sizeof(runtime*)) ;

     jclass nativeListener;
     JNINativeMethod methods[] = {{ "nativeEvent", "(ILorg/eclipse/swt/widgets/Event;)V", &event } };

     options[0].optionString =classpath;
     vm_args.version = JNI_VERSION_1_4; //0x00010002;
     vm_args.options = options;
     vm_args.nOptions = 1;
     vm_args.ignoreUnrecognized = JNI_FALSE;
     /* Create the Java VM */
     res = JNI_CreateJavaVM(&jvm, (void**)&env, &vm_args);

	 if (res<0){
		 return NULL;
	 }

	 rt->env=env;
	 rt->jvm=jvm;
	 eventCb=f;

	 nativeListener=findClass(rt,"Language/Java/SWT/NativeListener");
	 (*env)->RegisterNatives(env,nativeListener, methods, 1);


	 return rt;
}


void end(runtime rt){
	 (*rt->jvm)->DestroyJavaVM(rt->jvm);
	 free(rt);
}

jclass findClass(const runtime rt,const char *name){
	return (*rt->env)->FindClass(rt->env, name);
}

jobject newObject(const runtime rt,const jclass cls, const char *signature,const jvalue *args){
	jmethodID mid;
    if (cls == NULL) {
         return NULL;
    }
    mid = (*rt->env)->GetMethodID(rt->env, cls, "<init>",
    		signature);
    if (mid == NULL){
    	return NULL;
    }
    return (*rt->env)->NewObjectA(rt->env,cls,mid,args);
}


jmethodID getMethodID(const runtime rt,const jobject obj,const char *method,const char *signature){
	jclass cls;
	jmethodID mid;
	if (obj==NULL){
		return NULL;
	}
	cls=(*rt->env)->GetObjectClass(rt->env, obj);
	if (cls==NULL){
		return NULL;
	}
	mid = (*rt->env)->GetMethodID(rt->env, cls, method,
										 signature);
	return mid;
}

jint callIntMethod(const runtime rt,const jobject obj,const char *method,const char *signature,const jvalue *args){
	jmethodID mid;
	jint ret;
	mid=getMethodID(rt,obj,method,signature);
	if (mid!=NULL){
		ret= (*rt->env)-> CallIntMethodA (rt->env,obj,mid,args);
	}
	return ret;
}

jboolean callBooleanMethod(const runtime rt,const jobject obj,const char *method,const char *signature,const jvalue *args){
	jmethodID mid;
	jboolean ret;
	mid=getMethodID(rt,obj,method,signature);
	if (mid!=NULL){
		ret= (*rt->env)-> CallBooleanMethodA (rt->env,obj,mid,args);
	}
	return ret;
}


void callVoidMethod(const runtime rt,const jobject obj,const char *method,const char *signature,const jvalue *args){
	jmethodID mid;
	mid=getMethodID(rt,obj,method,signature);
	if (mid!=NULL){
		(*rt->env)-> CallVoidMethodA (rt->env,obj,mid,args);
	}
}

jstring newString(const runtime rt,const jchar *unicode, jsize len){
	return (*rt->env)->NewString(rt->env,unicode,len);
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

