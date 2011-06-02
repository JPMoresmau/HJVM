{-# LANGUAGE ForeignFunctionInterface, EmptyDataDecls, FlexibleContexts, FlexibleInstances #-}
module Language.Java.JVM.API where

import Language.Java.JVM.Types

import Control.Monad
import qualified Data.Map as Map

import Foreign.C
import Foreign.Ptr
import Foreign.Marshal.Array
import Control.Concurrent.MVar
import Control.Monad.IO.Class

import Text.Printf

foreign import ccall safe "start" f_start ::CString -> IO (CLong)
foreign import ccall safe "end" f_end :: IO ()
--foreign import ccall "test" test ::CInt -> IO (CInt)

foreign import ccall safe "findClass" f_findClass :: CString -> IO (JClassPtr)
foreign import ccall safe "findMethod" f_findMethod :: JClassPtr -> CString -> CString -> IO (JMethodPtr)
foreign import ccall safe "newObject" f_newObject :: JClassPtr -> CString -> JValuePtr -> IO (JObjectPtr)
foreign import ccall safe "newString" f_newString :: CWString -> CLong -> IO (JObjectPtr)

foreign import ccall safe "callIntMethod" f_callIntMethod :: JObjectPtr -> JMethodPtr -> JValuePtr -> IO (CLong)
foreign import ccall safe "callCharMethod" f_callCharMethod :: JObjectPtr -> JMethodPtr -> JValuePtr -> IO (CUShort)
foreign import ccall safe "callVoidMethod" f_callVoidMethod :: JObjectPtr -> JMethodPtr -> JValuePtr -> IO ()
foreign import ccall safe "callBooleanMethod" f_callBooleanMethod ::  JObjectPtr -> JMethodPtr -> JValuePtr -> IO (CUChar)
foreign import ccall safe "callByteMethod" f_callByteMethod ::  JObjectPtr -> JMethodPtr -> JValuePtr -> IO (CChar)
foreign import ccall safe "callLongMethod" f_callLongMethod ::  JObjectPtr -> JMethodPtr -> JValuePtr -> IO (CLong)
foreign import ccall safe "callShortMethod" f_callShortMethod ::  JObjectPtr -> JMethodPtr -> JValuePtr -> IO (CShort)
foreign import ccall safe "callFloatMethod" f_callFloatMethod ::  JObjectPtr -> JMethodPtr -> JValuePtr -> IO (CFloat)
foreign import ccall safe "callDoubleMethod" f_callDoubleMethod ::  JObjectPtr -> JMethodPtr -> JValuePtr -> IO (CDouble)

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
        
instance MethodProvider (JClassPtr,String,String) where
        getMethodID (cls,method,signature)=do
            withCString method
                (\m->withCString signature
                        (\s->f_findMethod cls m s))
          
instance MethodProvider (String,String,String) where
        getMethodID (clsName,method,signature)=do
            findClass clsName>>=(\cls->do
                    when (cls==nullPtr) (ioError $ userError $ printf "class %s not found" clsName)
                    withCString method
                        (\m->withCString signature
                                (\s->f_findMethod cls m s)))
          
withMethod ::  (MethodProvider mp)  => mp -> (JMethodPtr -> IO(a)) -> IO (a)
withMethod mp f=do
        mid<-getMethodID mp
        when (mid==nullPtr) (ioError $ userError "method not found")
        f mid
          
voidMethod :: (MonadIO m,MethodProvider mp) =>JObjectPtr -> mp -> [JValue] -> m ()  
voidMethod obj mp args= 
        liftIO $ withMethod mp (\mid->withArray args (\arr->f_callVoidMethod obj mid arr)) 

booleanMethod :: (MonadIO m,MethodProvider mp) =>JObjectPtr -> mp -> [JValue] -> m (Bool)   
booleanMethod obj mp args= do
        ret<-liftIO $ withMethod mp (\mid->withArray args (\arr->f_callBooleanMethod obj mid arr))    
        return (ret/=0)

intMethod :: (MonadIO m,MethodProvider mp) =>JObjectPtr -> mp -> [JValue] -> m (Integer)   
intMethod obj mp args= do
        ret<- liftIO $ withMethod mp (\mid->withArray args (\arr->f_callIntMethod obj mid arr))    
        return (fromIntegral ret)

charMethod :: (MonadIO m,MethodProvider mp) =>JObjectPtr -> mp -> [JValue] -> m (Char)   
charMethod obj mp args= do
        ret<- liftIO $ withMethod mp (\mid->withArray args (\arr->f_callCharMethod obj mid arr))   
        return (toEnum $ fromIntegral ret)

shortMethod :: (MonadIO m,MethodProvider mp) =>JObjectPtr -> mp -> [JValue] -> m (Int)   
shortMethod obj mp args= do
        ret<- liftIO $ withMethod mp (\mid->withArray args (\arr->f_callShortMethod obj mid arr))    
        return (fromIntegral ret)

byteMethod :: (MonadIO m,MethodProvider mp) =>JObjectPtr -> mp -> [JValue] -> m (Int)   
byteMethod obj mp args= do
        ret<- liftIO $ withMethod mp (\mid->withArray args (\arr->f_callByteMethod obj mid arr))   
        return (fromIntegral ret)
  
longMethod :: (MonadIO m,MethodProvider mp) =>JObjectPtr -> mp -> [JValue] -> m (Integer)   
longMethod obj mp args= do
        ret<- liftIO $ withMethod mp (\mid->withArray args (\arr->f_callLongMethod obj mid arr))  
        return (fromIntegral ret)  
        
floatMethod :: (MonadIO m,MethodProvider mp) =>JObjectPtr -> mp -> [JValue] -> m (Float)   
floatMethod obj mp args= do
        ret<- liftIO $ withMethod mp (\mid->withArray args (\arr->f_callFloatMethod obj mid arr))    
        return $ realToFrac ret          

doubleMethod :: (MonadIO m,MethodProvider mp) =>JObjectPtr -> mp -> [JValue] -> m (Double)   
doubleMethod obj mp args= do
        ret<- liftIO $ withMethod mp (\mid->withArray args (\arr->f_callDoubleMethod obj mid arr))    
        return $ realToFrac ret   
        
toJString :: (MonadIO m) => String -> m (JObjectPtr) 
toJString s=  liftIO $ withCWString s (\cs->f_newString cs (fromIntegral $ length s))
