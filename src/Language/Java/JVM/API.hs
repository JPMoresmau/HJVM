{-# LANGUAGE ForeignFunctionInterface, EmptyDataDecls, FlexibleContexts #-}
module Language.Java.JVM.API where

import Language.Java.JVM.Types

import Control.Monad
import qualified Data.Map as Map

import Foreign.C
import Foreign.Ptr
import Foreign.Marshal.Array
import Control.Concurrent.MVar
import Control.Monad.IO.Class

foreign import ccall safe "start" f_start ::CString -> IO (CLong)
foreign import ccall safe "end" f_end :: IO ()
--foreign import ccall "test" test ::CInt -> IO (CInt)

foreign import ccall safe "findClass" f_findClass :: CString -> IO (JClassPtr)
foreign import ccall safe "newObject" f_newObject :: JClassPtr -> CString -> JValuePtr -> IO (JObjectPtr)
foreign import ccall safe "callIntMethod" f_callIntMethod :: JObjectPtr -> CString -> CString -> JValuePtr -> IO (CLong)
foreign import ccall safe "callVoidMethod" f_callVoidMethod :: JObjectPtr -> CString -> CString -> JValuePtr -> IO ()
foreign import ccall safe "callBooleanMethod" f_callBooleanMethod ::  JObjectPtr -> CString -> CString -> JValuePtr -> IO (CUChar)
foreign import ccall safe "newString" f_newString :: CWString -> CLong -> IO (JObjectPtr)

foreign import ccall safe "registerCallback" f_registerCallback :: CString -> CString -> CString -> FunPtr CallbackInternal -> IO()

foreign import ccall "wrapper" wrap :: CallbackInternal -> IO (FunPtr CallbackInternal)

withJava :: String -> IO a -> IO a
withJava = withJava' True

withJava' :: Bool -> String -> IO a -> IO a
withJava' end options f= do
      ret<-withCString options (\s->f_start s)
      when (ret < 0) (ioError $ userError "could not start JVM")
      a<-f
      when end f_end
      return a

--withJavaRT :: (JRuntimePtr -> IO (a)) -> JavaT a 
--withJavaRT f=do
--        rt<-get
--        r<-liftIO $ f rt
--        return r

registerCallBackMethod:: (MonadIO m) => String -> String -> String -> m (CallbackMapRef)
registerCallBackMethod cls method eventCls =do
        ior<-liftIO $ newMVar Map.empty
        eventW<-liftIO $ wrap (event ior)
        liftIO $ withCString cls
                (\clsn->withCString method
                        (\methodn->withCString eventCls
                                (\eventClsn->f_registerCallback clsn methodn eventClsn eventW)))
        return ior

addCallBack :: (MonadIO m) => CallbackMapRef  -> Callback  -> m(CLong)
addCallBack cmr cb=do
        liftIO $ modifyMVar cmr (\m-> do
                let index=fromIntegral $ Map.size m
                return (Map.insert index cb m,index))

findClass :: (MonadIO m) => String -> m JClassPtr 
findClass name=liftIO $ withCString name (\s->f_findClass s)

newObject :: (MonadIO m) =>JClassPtr -> String -> [JValue] -> m (JObjectPtr) 
newObject cls signature args=liftIO $ withCString signature 
                (\s->withArray args
                        (\arr->f_newObject cls s arr))

event :: CallbackMapRef -> CallbackInternal
event mvar _ _ index eventObj=do
        putStrLn "event"
        putStrLn ("listenerEvt:"++(show index))
        withMVar mvar (\m->do
                let handler=Map.lookup index m
                case handler of
                        Nothing-> return ()
                        Just h->h eventObj
                )
        
          
voidMethod :: (MonadIO m) =>JObjectPtr -> String -> String -> [JValue] -> m ()  
voidMethod obj method signature args=  
        liftIO $ withCString method
                (\m->withCString signature
                        (\s->withArray args (\arr->f_callVoidMethod obj m s arr)))      

booleanMethod :: (MonadIO m) =>JObjectPtr -> String -> String -> [JValue] -> m (Bool)   
booleanMethod obj method signature args= do
        ret<-liftIO $ withCString method
                (\m->withCString signature
                        (\s->withArray args (\arr->f_callBooleanMethod obj m s arr)))    
        return (ret/=0)

intMethod :: (MonadIO m) =>JObjectPtr -> String -> String -> [JValue] -> m (Int)   
intMethod obj method signature args= do
        ret<- liftIO $ withCString method
                        (\m->withCString signature
                                (\s->withArray args (\arr->f_callIntMethod obj m s arr)))    
        return (fromIntegral ret)
        
toJString :: (MonadIO m) => String -> m (JObjectPtr) 
toJString s=  liftIO $ withCWString s (\cs->f_newString cs (fromIntegral $ length s))
