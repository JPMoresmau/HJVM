{-# LANGUAGE FlexibleInstances, MultiParamTypeClasses #-}

module Language.Java.SWT.SWT where

import Language.Java.JVM.API
import Language.Java.JVM.Types

import Control.Monad
import Control.Monad.State
import Foreign.C

type SWTT a= StateT (CallbackMapRef,JClassPtr) (StateT JRuntimePtr IO) a

instance WithJava (StateT (CallbackMapRef,JClassPtr) (StateT JRuntimePtr IO)) where
        withJavaRT f = do
                rt<-lift $ get
                r<-liftIO $ f rt
                return r

withSWT :: String -> SWTT a -> IO (a)
withSWT options f=do
        withJava options (do
                listenerCls<-findClass "Language/Java/SWT/NativeListener" 
                liftIO $ putStrLn ("listenerCls:"++(show listenerCls)) 
                cmr<-registerCallBackMethod "Language/Java/SWT/NativeListener" "nativeEvent" "org/eclipse/swt/widgets/Event"
                evalStateT f (cmr,listenerCls)
                )

addSWTCallBack :: JObjectPtr -> CLong -> Callback -> SWTT ()
addSWTCallBack widget eventid cb=do   
        (cmr,listenerCls)<-get
        index<-liftIO $ addCallBack cmr cb
        listener<-lift $ newObject listenerCls "(I)V" [JInt index]
        liftIO $ putStrLn ("listener:"++(show listener))
        lift $ voidMethod widget "addListener" "(ILorg/eclipse/swt/widgets/Listener;)V" [JInt eventid,JObj listener]
        

displayLoop :: JObjectPtr -> JObjectPtr -> SWTT()
displayLoop display shell= 
       do
               shellIsDisposed<-lift $ booleanMethod shell "isDisposed" "()Z" []
               when (not shellIsDisposed) (do 
                        displayDispatch<-lift $ booleanMethod display "readAndDispatch" "()Z" []
                        when (not displayDispatch) (
                                lift $ voidMethod display "sleep" "()V" []
                             )
                        displayLoop display shell
                   )


push :: CLong
push = 8

selection :: CLong
selection = 13