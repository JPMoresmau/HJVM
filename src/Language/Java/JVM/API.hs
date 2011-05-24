{-# LANGUAGE ForeignFunctionInterface, EmptyDataDecls #-}
module Language.Java.JVM.API where

import Language.Java.JVM.Types

import Control.Monad
import qualified Data.Map as Map

import Foreign.C
import Foreign.Ptr
import Foreign.Marshal.Alloc
import Foreign.Marshal.Array
import Foreign.Storable
import Control.Concurrent.MVar



foreign import ccall safe "start" start ::CString -> FunPtr (CLong ->JObjectPtr -> IO()) -> IO (CInt)
foreign import ccall safe "end" end :: IO ()
--foreign import ccall "test" test ::CInt -> IO (CInt)

foreign import ccall safe "findClass" findClass :: CString -> IO (JClassPtr)
foreign import ccall safe "newObject" newObject :: JClassPtr -> CString -> JValuePtr -> IO (JObjectPtr)
foreign import ccall safe "callIntMethod" callIntMethod ::JObjectPtr -> CString -> CString -> JValuePtr -> IO (CLong)
foreign import ccall safe "callVoidMethod" callVoidMethod ::JObjectPtr -> CString -> CString -> JValuePtr -> IO ()
foreign import ccall safe "callBooleanMethod" callBooleanMethod ::JObjectPtr -> CString -> CString -> JValuePtr -> IO (CUChar)
foreign import ccall safe "newString" newString :: CWString -> CLong -> IO (JObjectPtr)

foreign import ccall "wrapper" wrap :: (CLong -> JObjectPtr -> IO()) -> IO (FunPtr (CLong -> JObjectPtr -> IO()))

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
        
          
voidMethod :: JObjectPtr -> String -> String -> [JValue] -> IO()          
voidMethod obj method signature args=  
        withCString method
                (\m->withCString signature
                        (\s->withArray args (\arr->callVoidMethod obj m s arr)))            

booleanMethod :: JObjectPtr -> String -> String -> [JValue] -> IO(Bool)          
booleanMethod obj method signature args= do
        ret<-withCString method
                (\m->withCString signature
                        (\s->withArray args (\arr->callBooleanMethod obj m s arr)))    
        return (ret/=0)
        
toJString :: String -> IO JObjectPtr
toJString s=  withCWString s (\cs->newString cs (fromIntegral $ length s))
