{-# LANGUAGE ForeignFunctionInterface, EmptyDataDecls, FlexibleContexts, FlexibleInstances, RankNTypes,MultiParamTypeClasses #-}
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
foreign import ccall safe "findField" f_findField :: JClassPtr -> CString -> CString -> IO (JFieldPtr)
foreign import ccall safe "findStaticField" f_findStaticField :: JClassPtr -> CString -> CString -> IO (JFieldPtr)
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
foreign import ccall safe "callStaticCharMethod" f_callStaticCharMethod :: JClassPtr -> JMethodPtr -> JValuePtr  -> CWString-> IO (CUShort)
foreign import ccall safe "callStaticVoidMethod" f_callStaticVoidMethod :: JClassPtr -> JMethodPtr -> JValuePtr  -> CWString-> IO ()
foreign import ccall safe "callStaticBooleanMethod" f_callStaticBooleanMethod ::  JClassPtr -> JMethodPtr -> JValuePtr  -> CWString-> IO (CUChar)
foreign import ccall safe "callStaticByteMethod" f_callStaticByteMethod ::  JClassPtr -> JMethodPtr -> JValuePtr  -> CWString-> IO (CChar)
foreign import ccall safe "callStaticLongMethod" f_callStaticLongMethod ::  JClassPtr -> JMethodPtr -> JValuePtr  -> CWString-> IO (CLong)
foreign import ccall safe "callStaticShortMethod" f_callStaticShortMethod ::  JClassPtr -> JMethodPtr -> JValuePtr  -> CWString-> IO (CShort)
foreign import ccall safe "callStaticFloatMethod" f_callStaticFloatMethod ::  JClassPtr -> JMethodPtr -> JValuePtr  -> CWString-> IO (CFloat)
foreign import ccall safe "callStaticDoubleMethod" f_callStaticDoubleMethod ::  JClassPtr -> JMethodPtr -> JValuePtr  -> CWString-> IO (CDouble)
foreign import ccall safe "callStaticObjectMethod" f_callStaticObjectMethod ::  JClassPtr -> JMethodPtr -> JValuePtr  -> CWString-> IO (JObjectPtr)

foreign import ccall safe "getStaticIntField" f_getStaticIntField :: JClassPtr -> JFieldPtr -> CWString-> IO (CLong)
foreign import ccall safe "getStaticBooleanField" f_getStaticBooleanField :: JClassPtr -> JFieldPtr -> CWString-> IO (CUChar)
foreign import ccall safe "getStaticCharField" f_getStaticCharField :: JClassPtr -> JFieldPtr -> CWString-> IO (CUShort)
foreign import ccall safe "getStaticShortField" f_getStaticShortField :: JClassPtr -> JFieldPtr -> CWString-> IO (CShort)
foreign import ccall safe "getStaticByteField" f_getStaticByteField :: JClassPtr -> JFieldPtr -> CWString-> IO (CChar)
foreign import ccall safe "getStaticLongField" f_getStaticLongField :: JClassPtr -> JFieldPtr -> CWString-> IO (CLong)
foreign import ccall safe "getStaticDoubleField" f_getStaticDoubleField :: JClassPtr -> JFieldPtr -> CWString-> IO (CDouble)
foreign import ccall safe "getStaticFloatField" f_getStaticFloatField :: JClassPtr -> JFieldPtr -> CWString-> IO (CFloat)
foreign import ccall safe "getStaticObjectField" f_getStaticObjectField :: JClassPtr -> JFieldPtr -> CWString-> IO (JObjectPtr)

foreign import ccall safe "setStaticIntField" f_setStaticIntField :: JClassPtr -> JFieldPtr-> CLong  -> CWString -> IO ()
foreign import ccall safe "setStaticBooleanField" f_setStaticBooleanField :: JClassPtr -> JFieldPtr-> CUChar -> CWString -> IO ()
foreign import ccall safe "setStaticCharField" f_setStaticCharField :: JClassPtr -> JFieldPtr-> CUShort  -> CWString-> IO ()
foreign import ccall safe "setStaticShortField" f_setStaticShortField :: JClassPtr -> JFieldPtr-> CShort -> CWString -> IO ()
foreign import ccall safe "setStaticByteField" f_setStaticByteField :: JClassPtr -> JFieldPtr -> CChar -> CWString-> IO ()
foreign import ccall safe "setStaticLongField" f_setStaticLongField :: JClassPtr -> JFieldPtr -> CLong -> CWString-> IO ()
foreign import ccall safe "setStaticDoubleField" f_setStaticDoubleField :: JClassPtr -> JFieldPtr-> CDouble  -> CWString-> IO ()
foreign import ccall safe "setStaticFloatField" f_setStaticFloatField :: JClassPtr -> JFieldPtr-> CFloat -> CWString -> IO ()
foreign import ccall safe "setStaticObjectField" f_setStaticObjectField :: JClassPtr -> JFieldPtr -> JObjectPtr -> CWString -> IO ()

foreign import ccall safe "getIntField" f_getIntField :: JObjectPtr -> JFieldPtr -> CWString-> IO (CLong)
foreign import ccall safe "getBooleanField" f_getBooleanField :: JObjectPtr -> JFieldPtr -> CWString-> IO (CUChar)
foreign import ccall safe "getCharField" f_getCharField :: JObjectPtr -> JFieldPtr -> CWString-> IO (CUShort)
foreign import ccall safe "getShortField" f_getShortField :: JObjectPtr -> JFieldPtr -> CWString-> IO (CShort)
foreign import ccall safe "getByteField" f_getByteField :: JObjectPtr -> JFieldPtr -> CWString-> IO (CChar)
foreign import ccall safe "getLongField" f_getLongField :: JObjectPtr -> JFieldPtr -> CWString-> IO (CLong)
foreign import ccall safe "getDoubleField" f_getDoubleField :: JObjectPtr -> JFieldPtr -> CWString-> IO (CDouble)
foreign import ccall safe "getFloatField" f_getFloatField :: JObjectPtr -> JFieldPtr -> CWString-> IO (CFloat)
foreign import ccall safe "getObjectField" f_getObjectField :: JObjectPtr -> JFieldPtr -> CWString-> IO (JObjectPtr)

foreign import ccall safe "setIntField" f_setIntField :: JObjectPtr -> JFieldPtr-> CLong  -> CWString -> IO ()
foreign import ccall safe "setBooleanField" f_setBooleanField :: JObjectPtr -> JFieldPtr-> CUChar -> CWString -> IO ()
foreign import ccall safe "setCharField" f_setCharField :: JObjectPtr -> JFieldPtr-> CUShort  -> CWString-> IO ()
foreign import ccall safe "setShortField" f_setShortField :: JObjectPtr -> JFieldPtr-> CShort -> CWString -> IO ()
foreign import ccall safe "setByteField" f_setByteField :: JObjectPtr -> JFieldPtr -> CChar -> CWString-> IO ()
foreign import ccall safe "setLongField" f_setLongField :: JObjectPtr -> JFieldPtr -> CLong -> CWString-> IO ()
foreign import ccall safe "setDoubleField" f_setDoubleField :: JObjectPtr -> JFieldPtr-> CDouble  -> CWString-> IO ()
foreign import ccall safe "setFloatField" f_setFloatField :: JObjectPtr -> JFieldPtr-> CFloat -> CWString -> IO ()
foreign import ccall safe "setObjectField" f_setObjectField :: JObjectPtr -> JFieldPtr -> JObjectPtr -> CWString -> IO ()

foreign import ccall safe "registerCallback" f_registerCallback :: CString -> CString -> CString -> FunPtr CallbackInternal -> IO()

foreign import ccall "wrapper" wrap :: CallbackInternal -> IO (FunPtr CallbackInternal)

withJava :: String -> JavaT a -> IO a
withJava = withJava' True

withJava' :: Bool -> String -> JavaT a -> IO a
withJava' end options f= do
      ret<-withCString options (\s->f_start s)
      when (ret < 0) (ioError $ userError "could not start JVM")
      (a,s)<-runStateT f (JavaCache Map.empty Map.empty  Map.empty)
      when end (evalStateT endJava s)
      return a

endJava :: JavaT()
endJava = do
        jc<-getJavaCache
        liftIO $ mapM_ (\ptr->f_freeClass ptr) (Map.elems $ jc_classes jc)
        putJavaCache (JavaCache Map.empty Map.empty Map.empty)
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
        when (mid==nullPtr) (liftIO $ ioError $ userError $ printf "static method %s not found" $ show mp)
        f mid

findField :: (WithJava m) => Field -> m JFieldPtr
findField field=do
        jc<-getJavaCache
        let mptr=Map.lookup field (jc_fields jc)
        case mptr of
              Just ptr->return ptr
              Nothing -> do
                withClass (f_class field) (\cls->do
                        ptr<- liftIO $ withCString (f_name field)
                                (\m->withCString (f_signature field)
                                        (\s->f_findField cls m s
                                                ))
                        putJavaCache (jc{jc_fields=Map.insert field ptr $ jc_fields jc})
                        return ptr)

findStaticField :: (WithJava m) => Field -> m JFieldPtr
findStaticField field=do
        jc<-getJavaCache
        let mptr=Map.lookup field (jc_fields jc)
        case mptr of
              Just ptr->return ptr
              Nothing -> do
                withClass (f_class field) (\cls->do
                        ptr<- liftIO $ withCString (f_name field)
                                (\m->withCString (f_signature field)
                                        (\s->f_findStaticField cls m s
                                                ))
                        putJavaCache (jc{jc_fields=Map.insert field ptr $ jc_fields jc})
                        return ptr)

withField :: (WithJava m) =>  Field -> (JFieldPtr -> m a) -> m a
withField mp f=do
        fid<-findField mp
        when (fid==nullPtr) (liftIO $ ioError $ userError $ printf "field %s not found" $ show mp)
        f fid

withStaticField :: (WithJava m) =>  Field -> (JFieldPtr -> m a) -> m a
withStaticField mp f=do
        fid<-findStaticField mp
        when (fid==nullPtr) (liftIO $ ioError $ userError $ printf "static field %s not found" $ show mp)
        f fid

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

execMethod :: (HaskellJavaConversion h j,WithJava m) => 
        (JObjectPtr -> JMethodPtr -> JValuePtr  -> CWString-> IO j)
        -> JObjectPtr -> Method -> [JValue] -> m h
execMethod f obj m args = javaToHaskell $ withMethod m (\mid->liftIO $ withArray args (\arr->handleException $ f obj mid arr))    

booleanMethod :: (WithJava m) =>JObjectPtr -> Method -> [JValue] -> m (Bool)   
booleanMethod obj m args= execMethod f_callBooleanMethod obj m args

intMethod :: (WithJava m) =>JObjectPtr -> Method -> [JValue] -> m (Integer)   
intMethod obj m args= execMethod f_callIntMethod obj m args

charMethod :: (WithJava m) =>JObjectPtr -> Method -> [JValue] -> m (Char)   
charMethod obj m args= execMethod f_callCharMethod obj m args

shortMethod :: (WithJava m) =>JObjectPtr -> Method -> [JValue] -> m (Int)   
shortMethod obj m args= execMethod f_callShortMethod obj m args

byteMethod :: (WithJava m) =>JObjectPtr -> Method -> [JValue] -> m (Int)   
byteMethod obj m args= execMethod f_callByteMethod obj m args
  
longMethod :: (WithJava m) =>JObjectPtr -> Method -> [JValue] -> m (Integer)   
longMethod obj m args= execMethod f_callLongMethod obj m args
        
floatMethod :: (WithJava m) =>JObjectPtr -> Method -> [JValue] -> m (Float)   
floatMethod obj m args= execMethod f_callFloatMethod obj m args   

doubleMethod :: (WithJava m) =>JObjectPtr -> Method -> [JValue] -> m (Double)   
doubleMethod obj m args= execMethod f_callDoubleMethod obj m args
        
objectMethod :: (WithJava m) =>JObjectPtr -> Method -> [JValue] -> m (JObjectPtr)   
objectMethod obj m args= execMethod f_callObjectMethod obj m args

execStaticMethod :: (HaskellJavaConversion h j,WithJava m) => 
        (JClassPtr -> JMethodPtr -> JValuePtr  -> CWString-> IO j)
        -> JClassPtr -> Method -> [JValue] -> m h
execStaticMethod f cls m args = javaToHaskell $ withStaticMethod m (\mid->liftIO $ withArray args (\arr->handleException $ f cls mid arr)) 
        
staticIntMethod :: (WithJava m) =>JClassPtr -> Method -> [JValue] -> m (Integer)   
staticIntMethod cls m args= execStaticMethod f_callStaticIntMethod cls m args

staticBooleanMethod :: (WithJava m) =>JClassPtr -> Method -> [JValue] -> m (Bool)   
staticBooleanMethod cls m args= execStaticMethod f_callStaticBooleanMethod cls m args

staticCharMethod :: (WithJava m) =>JClassPtr -> Method -> [JValue] -> m (Char)   
staticCharMethod cls m args= execStaticMethod f_callStaticCharMethod cls m args

staticShortMethod :: (WithJava m) =>JClassPtr -> Method -> [JValue] -> m (Int)   
staticShortMethod cls m args= execStaticMethod f_callStaticShortMethod cls m args

staticByteMethod :: (WithJava m) =>JClassPtr -> Method -> [JValue] -> m (Int)   
staticByteMethod cls m args= execStaticMethod f_callStaticByteMethod cls m args
  
staticLongMethod :: (WithJava m) =>JClassPtr -> Method -> [JValue] -> m (Integer)   
staticLongMethod cls m args= execStaticMethod f_callStaticLongMethod cls m args
        
staticFloatMethod :: (WithJava m) =>JClassPtr -> Method -> [JValue] -> m (Float)   
staticFloatMethod cls m args= execStaticMethod f_callStaticFloatMethod cls m args
  
staticDoubleMethod :: (WithJava m) =>JClassPtr -> Method -> [JValue] -> m (Double)   
staticDoubleMethod cls m args= execStaticMethod f_callStaticDoubleMethod cls m args
        
staticObjectMethod :: (WithJava m) =>JClassPtr -> Method -> [JValue] -> m (JObjectPtr)   
staticObjectMethod cls m args= execStaticMethod f_callStaticObjectMethod cls m args

getStaticField :: (HaskellJavaConversion h j,WithJava m) => 
        (JClassPtr -> JFieldPtr -> CWString-> IO j)
        -> JClassPtr -> Field -> m h
getStaticField f cls fi = javaToHaskell $ withStaticField fi (\fid->liftIO $ handleException $ f cls fid) 

getStaticIntField :: (WithJava m) =>JClassPtr -> Field -> m (Integer)   
getStaticIntField = getStaticField f_getStaticIntField 

getStaticBooleanField :: (WithJava m) =>JClassPtr -> Field -> m (Bool)   
getStaticBooleanField = getStaticField f_getStaticBooleanField 

getStaticCharField :: (WithJava m) =>JClassPtr -> Field -> m (Char)   
getStaticCharField = getStaticField f_getStaticCharField 

getStaticShortField :: (WithJava m) =>JClassPtr -> Field -> m (Int)   
getStaticShortField = getStaticField f_getStaticShortField 

getStaticByteField :: (WithJava m) =>JClassPtr -> Field -> m (Int)   
getStaticByteField= getStaticField f_getStaticByteField 

getStaticLongField :: (WithJava m) =>JClassPtr -> Field -> m (Integer)   
getStaticLongField = getStaticField f_getStaticLongField

getStaticDoubleField :: (WithJava m) =>JClassPtr -> Field -> m (Double)   
getStaticDoubleField= getStaticField f_getStaticDoubleField

getStaticFloatField :: (WithJava m) =>JClassPtr -> Field -> m (Float)   
getStaticFloatField= getStaticField f_getStaticFloatField

getStaticObjectField :: (WithJava m) =>JClassPtr -> Field -> m (JObjectPtr)   
getStaticObjectField= getStaticField f_getStaticObjectField

setStaticField :: (HaskellJavaConversion h j,WithJava m) => 
        (JClassPtr -> JFieldPtr -> j -> CWString  -> IO ())
        -> JClassPtr -> Field -> h -> m ()
setStaticField f cls fi v= withStaticField fi (\fid->liftIO $ handleException $ f cls fid $ fromHaskell v) 

setStaticIntField :: (WithJava m) =>JClassPtr -> Field -> Integer -> m ()   
setStaticIntField = setStaticField f_setStaticIntField

setStaticBooleanField :: (WithJava m) =>JClassPtr -> Field -> Bool -> m ()   
setStaticBooleanField = setStaticField f_setStaticBooleanField

setStaticCharField :: (WithJava m) =>JClassPtr -> Field -> Char -> m ()   
setStaticCharField = setStaticField f_setStaticCharField

setStaticShortField :: (WithJava m) =>JClassPtr -> Field -> Int -> m ()   
setStaticShortField = setStaticField f_setStaticShortField

setStaticByteField :: (WithJava m) =>JClassPtr -> Field -> Int -> m ()   
setStaticByteField = setStaticField f_setStaticByteField

setStaticLongField :: (WithJava m) =>JClassPtr -> Field -> Integer -> m ()   
setStaticLongField = setStaticField f_setStaticLongField

setStaticDoubleField :: (WithJava m) =>JClassPtr -> Field -> Double -> m ()   
setStaticDoubleField = setStaticField f_setStaticDoubleField

setStaticFloatField :: (WithJava m) =>JClassPtr -> Field -> Float -> m ()   
setStaticFloatField = setStaticField f_setStaticFloatField

setStaticObjectField :: (WithJava m) =>JClassPtr -> Field -> JObjectPtr -> m ()   
setStaticObjectField = setStaticField f_setStaticObjectField

getField :: (HaskellJavaConversion h j,WithJava m) => 
        (JObjectPtr -> JFieldPtr -> CWString-> IO j)
        -> JObjectPtr -> Field -> m h
getField f cls fi = javaToHaskell $ withField fi (\fid->liftIO $ handleException $ f cls fid) 

getIntField :: (WithJava m) =>JObjectPtr -> Field -> m (Integer)   
getIntField = getField f_getIntField 

getBooleanField :: (WithJava m) =>JObjectPtr -> Field -> m (Bool)   
getBooleanField = getField f_getBooleanField 

getCharField :: (WithJava m) =>JObjectPtr -> Field -> m (Char)   
getCharField = getField f_getCharField 

getShortField :: (WithJava m) =>JObjectPtr -> Field -> m (Int)   
getShortField = getField f_getShortField 

getByteField :: (WithJava m) =>JObjectPtr -> Field -> m (Int)   
getByteField= getField f_getByteField 

getLongField :: (WithJava m) =>JObjectPtr -> Field -> m (Integer)   
getLongField = getField f_getLongField

getDoubleField :: (WithJava m) =>JObjectPtr -> Field -> m (Double)   
getDoubleField= getField f_getDoubleField

getFloatField :: (WithJava m) =>JObjectPtr -> Field -> m (Float)   
getFloatField= getField f_getFloatField

getObjectField :: (WithJava m) =>JObjectPtr -> Field -> m (JObjectPtr)   
getObjectField= getField f_getObjectField

setField :: (HaskellJavaConversion h j,WithJava m) => 
        (JObjectPtr -> JFieldPtr -> j -> CWString  -> IO ())
        -> JObjectPtr -> Field -> h -> m ()
setField f cls fi v= withField fi (\fid->liftIO $ handleException $ f cls fid $ fromHaskell v) 

setIntField :: (WithJava m) =>JObjectPtr -> Field -> Integer -> m ()   
setIntField = setField f_setIntField

setBooleanField :: (WithJava m) =>JObjectPtr -> Field -> Bool -> m ()   
setBooleanField = setField f_setBooleanField

setCharField :: (WithJava m) =>JObjectPtr -> Field -> Char -> m ()   
setCharField = setField f_setCharField

setShortField :: (WithJava m) =>JObjectPtr -> Field -> Int -> m ()   
setShortField = setField f_setShortField

setByteField :: (WithJava m) =>JObjectPtr -> Field -> Int -> m ()   
setByteField = setField f_setByteField

setLongField :: (WithJava m) =>JObjectPtr -> Field -> Integer -> m ()   
setLongField = setField f_setLongField

setDoubleField :: (WithJava m) =>JObjectPtr -> Field -> Double -> m ()   
setDoubleField = setField f_setDoubleField

setFloatField :: (WithJava m) =>JObjectPtr -> Field -> Float -> m ()   
setFloatField = setField f_setFloatField

setObjectField :: (WithJava m) =>JObjectPtr -> Field -> JObjectPtr -> m ()   
setObjectField = setField f_setObjectField



toJString :: (MonadIO m) => String -> m (JObjectPtr) 
toJString s=  liftIO $ withCWString s (\cs->handleException $ f_newString cs (fromIntegral $ length s))
