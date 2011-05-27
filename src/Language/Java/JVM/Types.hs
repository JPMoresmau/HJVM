{-# LANGUAGE ForeignFunctionInterface, EmptyDataDecls, TypeSynonymInstances #-}

module Language.Java.JVM.Types where

import Foreign.C
import Foreign.Ptr
import Foreign.Storable
import Control.Monad.State
import qualified Data.Map as Map
import Control.Concurrent.MVar

data JObject
type JObjectPtr=Ptr JObject
data JClass
type JClassPtr=Ptr JClass
data JRuntime
type JRuntimePtr=Ptr JRuntime

data JEnv
type JEnvPtr=Ptr JEnv

type CallbackInternal=(JEnvPtr -> JObjectPtr -> CLong -> JObjectPtr -> IO())

type Callback = (JObjectPtr -> JavaT ())

type CallbackMap = Map.Map CLong Callback
type CallbackMapRef =MVar CallbackMap

data JValue=JObj JObjectPtr
        | JInt CLong
        | JBool CUChar
        | JByte CChar
        | JChar CUShort
        | JShort CShort
        | JLong CLong
        | JFloat CFloat
        | JDouble CDouble

type JValuePtr=Ptr JValue

instance Storable JValue where
        sizeOf _= 8
        alignment _=alignment (undefined :: CDouble)
        poke p (JObj l)= poke (castPtr p) l
        poke p (JInt i)= poke (castPtr p) i
        poke p (JBool z)= poke (castPtr p) z
        poke p (JByte b)= poke (castPtr p) b
        poke p (JChar c)= poke (castPtr p) c
        poke p (JShort s)= poke (castPtr p) s
        poke p (JLong j)= poke (castPtr p) j
        poke p (JFloat f)= poke (castPtr p) f
        poke p (JDouble d)= poke (castPtr p) d
        peek=error "undefined peek"


type JavaT =StateT JRuntimePtr IO
     
class (Monad m, MonadIO m) => WithJava m where
        withJavaRT  :: (JRuntimePtr -> IO (a)) -> m a 
        
instance WithJava JavaT where
        withJavaRT f = do
                rt<-get
                r<-liftIO $ f rt
                return r