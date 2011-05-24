{-# LANGUAGE ForeignFunctionInterface, EmptyDataDecls #-}
module Language.Java.JVM.API where

import Language.Java.JVM.Types

import Control.Monad
import Control.Monad.State
import qualified Data.Map as Map

import Foreign.C
import Foreign.Ptr
import Foreign.Marshal.Alloc
import Foreign.Marshal.Array
import Foreign.Storable
import Control.Concurrent.MVar


foreign import ccall safe "start" f_start ::CString -> FunPtr (CLong ->JObjectPtr -> IO()) -> IO (JRuntimePtr)
foreign import ccall safe "end" f_end :: JRuntimePtr -> IO ()
--foreign import ccall "test" test ::CInt -> IO (CInt)

foreign import ccall safe "findClass" f_findClass :: JRuntimePtr -> CString -> IO (JClassPtr)
foreign import ccall safe "newObject" f_newObject :: JRuntimePtr -> JClassPtr -> CString -> JValuePtr -> IO (JObjectPtr)
foreign import ccall safe "callIntMethod" f_callIntMethod :: JRuntimePtr -> JObjectPtr -> CString -> CString -> JValuePtr -> IO (CLong)
foreign import ccall safe "callVoidMethod" f_callVoidMethod :: JRuntimePtr -> JObjectPtr -> CString -> CString -> JValuePtr -> IO ()
foreign import ccall safe "callBooleanMethod" f_callBooleanMethod :: JRuntimePtr ->  JObjectPtr -> CString -> CString -> JValuePtr -> IO (CUChar)
foreign import ccall safe "newString" f_newString :: JRuntimePtr ->  CWString -> CLong -> IO (JObjectPtr)

foreign import ccall "wrapper" wrap :: (CLong -> JObjectPtr -> IO()) -> IO (FunPtr (CLong -> JObjectPtr -> IO()))

withJava :: String -> (CLong -> JObjectPtr -> IO()) -> JavaT a -> IO (a)
withJava options event f= do
      eventW<-wrap event
      ret<-withCString options (\s->f_start s eventW)
      when (ret == nullPtr) (error "could not start JVM")
      (a,rt)<-runStateT f ret
      f_end rt
      return a

withJavaRT :: (JRuntimePtr -> IO (a)) -> JavaT a
withJavaRT f=do
        rt<-get
        r<-liftIO $ f rt
        return r

findClass :: String -> JavaT JClassPtr
findClass name=withJavaRT (\rt->withCString name (\s->f_findClass rt s))

newObject :: JClassPtr -> String -> [JValue] -> JavaT (JObjectPtr)
newObject cls signature args=withJavaRT 
        (\rt->withCString signature 
                (\s->withArray args
                        (\arr->f_newObject rt cls s arr)))

event :: MVar (Map.Map CLong (JObjectPtr -> IO()))->  CLong -> JObjectPtr -> IO()
event mvar index eventObj=do
        putStrLn "event"
        putStrLn ("listenerEvt:"++(show index))
        withMVar mvar (\m->do
                let handler=Map.lookup index m
                case handler of
                        Nothing-> return ()
                        Just h->h eventObj
                )
        
          
voidMethod :: JObjectPtr -> String -> String -> [JValue] -> JavaT()          
voidMethod obj method signature args=  
        withJavaRT (\rt->
                withCString method
                        (\m->withCString signature
                                (\s->withArray args (\arr->f_callVoidMethod rt obj m s arr))))         

booleanMethod :: JObjectPtr -> String -> String -> [JValue] -> JavaT(Bool)          
booleanMethod obj method signature args= do
        ret<- withJavaRT (\rt->
                withCString method
                        (\m->withCString signature
                                (\s->withArray args (\arr->f_callBooleanMethod rt obj m s arr))))    
        return (ret/=0)
        
toJString :: String -> JavaT (JObjectPtr)
toJString s=  withJavaRT (\rt->withCWString s (\cs->f_newString rt cs (fromIntegral $ length s)))
