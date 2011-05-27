{-# LANGUAGE ForeignFunctionInterface, EmptyDataDecls, FlexibleContexts #-}
module Language.Java.JVM.API where

import Language.Java.JVM.Types

import Control.Monad
import Control.Monad.State
import qualified Data.Map as Map

import Foreign.C
import Foreign.Ptr
import Foreign.Marshal.Array
import Control.Concurrent.MVar


foreign import ccall safe "start" f_start ::CString -> IO (JRuntimePtr)
foreign import ccall safe "end" f_end :: JRuntimePtr -> IO ()
--foreign import ccall "test" test ::CInt -> IO (CInt)

foreign import ccall safe "findClass" f_findClass :: JRuntimePtr -> CString -> IO (JClassPtr)
foreign import ccall safe "newObject" f_newObject :: JRuntimePtr -> JClassPtr -> CString -> JValuePtr -> IO (JObjectPtr)
foreign import ccall safe "callIntMethod" f_callIntMethod :: JRuntimePtr -> JObjectPtr -> CString -> CString -> JValuePtr -> IO (CLong)
foreign import ccall safe "callVoidMethod" f_callVoidMethod :: JRuntimePtr -> JObjectPtr -> CString -> CString -> JValuePtr -> IO ()
foreign import ccall safe "callBooleanMethod" f_callBooleanMethod :: JRuntimePtr ->  JObjectPtr -> CString -> CString -> JValuePtr -> IO (CUChar)
foreign import ccall safe "newString" f_newString :: JRuntimePtr ->  CWString -> CLong -> IO (JObjectPtr)

foreign import ccall safe "registerCallback" f_registerCallback :: JRuntimePtr -> CString -> CString -> CString -> FunPtr CallbackInternal -> IO()

foreign import ccall "wrapper" wrap :: CallbackInternal -> IO (FunPtr CallbackInternal)

withJava :: String ->  JavaT a -> IO (a)
withJava options  f= do
      ret<-withCString options (\s->f_start s)
      when (ret == nullPtr) (ioError $ userError "could not start JVM")
      (a,rt)<-runStateT f ret
      f_end rt
      return a

--withJavaRT :: (JRuntimePtr -> IO (a)) -> JavaT a 
--withJavaRT f=do
--        rt<-get
--        r<-liftIO $ f rt
--        return r

registerCallBackMethod:: (WithJava m)=> String -> String -> String -> m (CallbackMapRef)
registerCallBackMethod cls method eventCls =do
        ior<-liftIO $ newMVar Map.empty
        withJavaRT
                (\rt->do
                        eventW<-liftIO $ wrap (event rt ior)
                        withCString cls
                                (\clsn->withCString method
                                        (\methodn->withCString eventCls
                                                (\eventClsn->f_registerCallback rt clsn methodn eventClsn eventW))))
        return ior

addCallBack :: CallbackMapRef  -> Callback  -> IO(CLong)
addCallBack cmr cb=do
        modifyMVar cmr (\m-> do
                let index=fromIntegral $ Map.size m
                return (Map.insert index cb m,index))

findClass :: (WithJava m)=>String -> m JClassPtr 
findClass name=withJavaRT (\rt->withCString name (\s->f_findClass rt s))

newObject :: (WithJava m)=>JClassPtr -> String -> [JValue] -> m (JObjectPtr) 
newObject cls signature args=withJavaRT 
        (\rt->withCString signature 
                (\s->withArray args
                        (\arr->f_newObject rt cls s arr)))

event :: JRuntimePtr -> CallbackMapRef -> CallbackInternal
event st mvar _ _ index eventObj=do
        putStrLn "event"
        putStrLn ("listenerEvt:"++(show index))
        withMVar mvar (\m->do
                let handler=Map.lookup index m
                case handler of
                        Nothing-> return ()
                        Just h->evalStateT (h eventObj) st
                )
        
          
voidMethod :: (WithJava m )=>JObjectPtr -> String -> String -> [JValue] -> m ()  
voidMethod obj method signature args=  
        withJavaRT (\rt->
                withCString method
                        (\m->withCString signature
                                (\s->withArray args (\arr->f_callVoidMethod rt obj m s arr))))         

booleanMethod :: (WithJava m)=>JObjectPtr -> String -> String -> [JValue] -> m (Bool)   
booleanMethod obj method signature args= do
        ret<- withJavaRT (\rt->
                withCString method
                        (\m->withCString signature
                                (\s->withArray args (\arr->f_callBooleanMethod rt obj m s arr))))    
        return (ret/=0)
        
toJString :: (WithJava m)=>String -> m (JObjectPtr) 
toJString s=  withJavaRT (\rt->withCWString s (\cs->f_newString rt cs (fromIntegral $ length s)))
