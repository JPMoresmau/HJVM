{-# LANGUAGE ForeignFunctionInterface, EmptyDataDecls, FlexibleContexts, FlexibleInstances, RankNTypes #-}
module Language.Java.JVM.API where

import Language.Java.JVM.Types

import Control.Monad
import qualified Data.Map as Map

import Foreign.C
import Foreign.Ptr
import Foreign.Marshal.Alloc
import Foreign.Marshal.Array
import Control.Concurrent.MVar
import Control.Monad.IO.Class
import Control.Monad.State

import Text.Printf

foreign import ccall safe "start" f_start ::CString -> IO (CLong)
foreign import ccall safe "end" f_end :: IO ()
--foreign import ccall "test" test ::CInt -> IO (CInt)

foreign import ccall safe "findClass" f_findClass :: CString -> IO (JClassPtr)
foreign import ccall safe "freeClass" f_freeClass :: JClassPtr -> IO ()
foreign import ccall safe "freeObject" f_freeObject :: JObjectPtr -> IO ()
foreign import ccall safe "findMethod" f_findMethod :: JClassPtr -> CString -> CString -> IO (JMethodPtr)
foreign import ccall safe "findStaticMethod" f_findStaticMethod :: JClassPtr -> CString -> CString -> IO (JMethodPtr)
foreign import ccall safe "newObject" f_newObject :: JClassPtr -> JMethodPtr -> JValuePtr -> CWString -> IO (JObjectPtr)
foreign import ccall safe "newString" f_newString :: CWString -> CLong  -> CWString-> IO (JObjectPtr)

foreign import ccall safe "callIntMethod" f_callIntMethod :: JObjectPtr -> JMethodPtr -> JValuePtr  -> CWString-> IO (CLong)
foreign import ccall safe "callCharMethod" f_callCharMethod :: JObjectPtr -> JMethodPtr -> JValuePtr  -> CWString-> IO (CUShort)
foreign import ccall safe "callVoidMethod" f_callVoidMethod :: JObjectPtr -> JMethodPtr -> JValuePtr  -> CWString-> IO ()
foreign import ccall safe "callBooleanMethod" f_callBooleanMethod ::  JObjectPtr -> JMethodPtr -> JValuePtr  -> CWString-> IO (CUChar)
foreign import ccall safe "callByteMethod" f_callByteMethod ::  JObjectPtr -> JMethodPtr -> JValuePtr  -> CWString-> IO (CChar)
foreign import ccall safe "callLongMethod" f_callLongMethod ::  JObjectPtr -> JMethodPtr -> JValuePtr  -> CWString-> IO (CLong)
foreign import ccall safe "callShortMethod" f_callShortMethod ::  JObjectPtr -> JMethodPtr -> JValuePtr  -> CWString-> IO (CShort)
foreign import ccall safe "callFloatMethod" f_callFloatMethod ::  JObjectPtr -> JMethodPtr -> JValuePtr  -> CWString-> IO (CFloat)
foreign import ccall safe "callDoubleMethod" f_callDoubleMethod ::  JObjectPtr -> JMethodPtr -> JValuePtr  -> CWString-> IO (CDouble)
foreign import ccall safe "callObjectMethod" f_callObjectMethod ::  JObjectPtr -> JMethodPtr -> JValuePtr  -> CWString-> IO (JObjectPtr)

foreign import ccall safe "callStaticIntMethod" f_callStaticIntMethod :: JClassPtr -> JMethodPtr -> JValuePtr  -> CWString-> IO (CLong)

foreign import ccall safe "registerCallback" f_registerCallback :: CString -> CString -> CString -> FunPtr CallbackInternal -> IO()

foreign import ccall "wrapper" wrap :: CallbackInternal -> IO (FunPtr CallbackInternal)

withJava :: String -> JavaT a -> IO a
withJava = withJava' True

withJava' :: Bool -> String -> JavaT a -> IO a
withJava' end options f= do
      ret<-withCString options (\s->f_start s)
      when (ret < 0) (ioError $ userError "could not start JVM")
      (a,s)<-runStateT f (JavaCache Map.empty Map.empty)
      when end (evalStateT endJava s)
      return a

endJava :: JavaT()
endJava = do
        jc<-getJavaCache
        liftIO $ mapM_ (\ptr->f_freeClass ptr) (Map.elems $ jc_classes jc)
        putJavaCache (JavaCache Map.empty Map.empty)
        liftIO $ f_end 

--withJavaRT :: (JRuntimePtr -> IO (a)) -> JavaT a 
--withJavaRT f=do
--        rt<-get
--        r<-liftIO $ f rt
--        return r

registerCallBackMethod:: (WithJava m) => String -> String -> String -> m (CallbackMapRef)
registerCallBackMethod cls method eventCls =do
        jc<-getJavaCache
        ior<-liftIO $ newMVar Map.empty
        eventW<-liftIO $ wrap (event jc ior)
        liftIO $ withCString cls
                (\clsn->withCString method
                        (\methodn->withCString eventCls
                                (\eventClsn->f_registerCallback clsn methodn eventClsn eventW)))
        return ior

addCallBack :: (WithJava m) => CallbackMapRef  -> Callback  -> m(CLong)
addCallBack cmr cb=do
        liftIO $ modifyMVar cmr (\m-> do
                let index=fromIntegral $ Map.size m
                return (Map.insert index cb m,index))

findClass :: (WithJava m) => ClassName -> m JClassPtr 
findClass name=do
        jc<-getJavaCache
        let mptr=Map.lookup name (jc_classes jc)
        case mptr of
              Just ptr->return ptr
              Nothing->do  
                ptr<-liftIO $ withCString name (\s->f_findClass s)
                putJavaCache (jc{jc_classes=Map.insert name ptr $ jc_classes jc})
                return ptr


withClass :: (WithJava m) => ClassName -> (JClassPtr->m a) -> m a
withClass className f= findClass (className)>>=(\cls->do
                        when (cls==nullPtr) (liftIO $ ioError $ userError $ printf "class %s not found" className)
                        f cls)


freeClass :: (WithJava m) => ClassName -> m ()
freeClass name=do
        jc<-getJavaCache
        let mptr=Map.lookup name (jc_classes jc)
        case mptr of
              Just ptr->do
                liftIO $ f_freeClass ptr
                putJavaCache (jc{jc_classes=Map.delete name $ jc_classes jc})
              Nothing->return ()

findMethod :: (WithJava m) => Method -> m JMethodPtr
findMethod meth=do
        jc<-getJavaCache
        let mptr=Map.lookup meth (jc_methods jc)
        case mptr of
              Just ptr->return ptr
              Nothing -> do
                withClass (m_class meth) (\cls->do
                        ptr<- liftIO $ withCString (m_name meth)
                                (\m->withCString (m_signature meth)
                                        (\s->f_findMethod cls m s
                                                ))
                        putJavaCache (jc{jc_methods=Map.insert meth ptr $ jc_methods jc})
                        return ptr)

findStaticMethod :: (WithJava m) => Method -> m JMethodPtr
findStaticMethod meth=do
        jc<-getJavaCache
        let mptr=Map.lookup meth (jc_methods jc)
        case mptr of
              Just ptr->return ptr
              Nothing -> do
                withClass (m_class meth) (\cls->do
                        ptr<- liftIO $ withCString (m_name meth)
                                (\m->withCString (m_signature meth)
                                        (\s->f_findStaticMethod cls m s
                                                ))
                        putJavaCache (jc{jc_methods=Map.insert meth ptr $ jc_methods jc})
                        return ptr)

withMethod :: (WithJava m) =>  Method -> (JMethodPtr -> m a) -> m a
withMethod mp f=do
        mid<-findMethod mp
        when (mid==nullPtr) (liftIO $ ioError $ userError $ printf "method %s not found" $ show mp)
        f mid

withStaticMethod :: (WithJava m) =>  Method -> (JMethodPtr -> m a) -> m a
withStaticMethod mp f=do
        mid<-findStaticMethod mp
        when (mid==nullPtr) (liftIO $ ioError $ userError $ printf "method %s not found" $ show mp)
        f mid

handleException :: (CWString -> IO a) -> IO a
handleException f=allocaBytes 1000 (\errMsg ->do
        ret<-f errMsg
        s<-peekCWString errMsg
        when (not $ null s) (ioError $ userError s)
        return ret
        )

withObject :: (WithJava m) => (m JObjectPtr) -> (JObjectPtr -> m a) -> m a
withObject f1 f2=do
        obj <- f1
        ret <- f2 obj
        liftIO $ f_freeObject obj
        return (ret)

newObject :: (WithJava m) => ClassName -> String -> [JValue] -> m (JObjectPtr) 
newObject className signature args= withClass (className) (\cls->do
        withMethod (Method className "<init>" signature) (\mid->
                liftIO $ withArray args
                        (\arr-> handleException $ f_newObject cls mid arr)))

event :: JavaCache -> CallbackMapRef -> CallbackInternal
event jc mvar _ _ index eventObj=do
        putStrLn "event"
        putStrLn ("listenerEvt:"++(show index))
        mh<-liftIO $ withMVar mvar (\m->do
                return $ Map.lookup index m
                )
        case mh of
                Nothing-> return ()
                Just h->evalStateT (h eventObj) jc    
    
        
--instance MethodProvider (JClassPtr,String,String) where
--        getMethodID (cls,method,signature)=do
--            withCString method
--                (\m->withCString signature
--                        (\s->f_findMethod cls m s))
--          
--instance MethodProvider (String,String,String) where
--        getMethodID (clsName,method,signature)=do
--            findClass clsName>>=(\cls->do
--                    when (cls==nullPtr) (ioError $ userError $ printf "class %s not found" clsName)
--                    withCString method
--                        (\m->withCString signature
--                                (\s->f_findMethod cls m s)))
--          



          
voidMethod :: (WithJava m) => JObjectPtr -> Method -> [JValue] -> m ()  
voidMethod obj m args= 
        withMethod m (\mid->liftIO $ withArray args (\arr->handleException $ f_callVoidMethod obj mid arr)) 

booleanMethod :: (WithJava m) =>JObjectPtr -> Method -> [JValue] -> m (Bool)   
booleanMethod obj m args= do
        ret<-withMethod m (\mid->liftIO $ withArray args (\arr->handleException $ f_callBooleanMethod obj mid arr))    
        return (ret/=0)

intMethod :: (WithJava m) =>JObjectPtr -> Method -> [JValue] -> m (Integer)   
intMethod obj m args= do
        ret<- withMethod m (\mid->liftIO $ withArray args (\arr->handleException $ f_callIntMethod obj mid arr))    
        return (fromIntegral ret)

charMethod :: (WithJava m) =>JObjectPtr -> Method -> [JValue] -> m (Char)   
charMethod obj m args= do
        ret<- withMethod m (\mid->liftIO $ withArray args (\arr->handleException $ f_callCharMethod obj mid arr))   
        return (toEnum $ fromIntegral ret)

shortMethod :: (WithJava m) =>JObjectPtr -> Method -> [JValue] -> m (Int)   
shortMethod obj m args= do
        ret<- withMethod m (\mid->liftIO $ withArray args (\arr->handleException $ f_callShortMethod obj mid arr))    
        return (fromIntegral ret)

byteMethod :: (WithJava m) =>JObjectPtr -> Method -> [JValue] -> m (Int)   
byteMethod obj m args= do
        ret<- withMethod m (\mid->liftIO $ withArray args (\arr->handleException $ f_callByteMethod obj mid arr))   
        return (fromIntegral ret)
  
longMethod :: (WithJava m) =>JObjectPtr -> Method -> [JValue] -> m (Integer)   
longMethod obj m args= do
        ret<- withMethod m (\mid->liftIO $ withArray args (\arr->handleException $ f_callLongMethod obj mid arr))  
        return (fromIntegral ret)  
        
floatMethod :: (WithJava m) =>JObjectPtr -> Method -> [JValue] -> m (Float)   
floatMethod obj m args= do
        ret<- withMethod m (\mid->liftIO $ withArray args (\arr->handleException $ f_callFloatMethod obj mid arr))    
        return $ realToFrac ret          

doubleMethod :: (WithJava m) =>JObjectPtr -> Method -> [JValue] -> m (Double)   
doubleMethod obj m args= do
        ret<- withMethod m (\mid->liftIO $ withArray args (\arr->handleException $ f_callDoubleMethod obj mid arr))    
        return $ realToFrac ret   
        
objectMethod :: (WithJava m) =>JObjectPtr -> Method -> [JValue] -> m (JObjectPtr)   
objectMethod obj m args= 
        withMethod m (\mid->liftIO $ withArray args (\arr->handleException $ f_callObjectMethod obj mid arr))    
        
        
staticIntMethod :: (WithJava m) =>JClassPtr -> Method -> [JValue] -> m (Integer)   
staticIntMethod cls m args= do
        ret<- withStaticMethod m (\mid->liftIO $ withArray args (\arr->handleException $ f_callStaticIntMethod cls mid arr))    
        return (fromIntegral ret)        
        
toJString :: (MonadIO m) => String -> m (JObjectPtr) 
toJString s=  liftIO $ withCWString s (\cs->handleException $ f_newString cs (fromIntegral $ length s))
