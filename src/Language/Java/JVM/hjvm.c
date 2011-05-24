#include <jni.h>
#include "hjvm.h"

JNIEnv *env;
JavaVM *jvm;
eventCallback *eventCb;

void event(JNIEnv *env, jobject listener,jint index,jobject event){
	eventCb(index,event);
}

int start(char* classpath,eventCallback f){
     jint res;
     
     JavaVMInitArgs vm_args;
     JavaVMOption options[1];

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
		 return res;
	 }
	 eventCb=f;

	 nativeListener=findClass("Language/Java/SWT/NativeListener");
	 (*env)->RegisterNatives(env,nativeListener, methods, 1);

	 return 0;
}



void end(){
	 (*jvm)->DestroyJavaVM(jvm);
}

jclass findClass(const char *name){
	return (*env)->FindClass(env, name);
}

jobject newObject(const jclass cls, const char *signature,const jvalue *args){
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


jmethodID getMethodID(const jobject obj,const char *method,const char *signature){
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

jint callIntMethod(const jobject obj,const char *method,const char *signature,const jvalue *args){
	jmethodID mid;
	jint ret;
	mid=getMethodID(obj,method,signature);
	if (mid!=NULL){
		ret= (*env)-> CallIntMethodA (env,obj,mid,args);
	}
	return ret;
}

jboolean callBooleanMethod(const jobject obj,const char *method,const char *signature,const jvalue *args){
	jmethodID mid;
	jboolean ret;
	mid=getMethodID(obj,method,signature);
	if (mid!=NULL){
		ret= (*env)-> CallBooleanMethodA (env,obj,mid,args);
	}
	return ret;
}


void callVoidMethod(const jobject obj,const char *method,const char *signature,const jvalue *args){
	jmethodID mid;
	mid=getMethodID(obj,method,signature);
	if (mid!=NULL){
		(*env)-> CallVoidMethodA (env,obj,mid,args);
	}
}

jstring newString(const jchar *unicode, jsize len){
	return (*env)->NewString(env,unicode,len);
}

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
          
}

