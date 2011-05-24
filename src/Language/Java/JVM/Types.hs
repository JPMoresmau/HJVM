{-# LANGUAGE ForeignFunctionInterface, EmptyDataDecls #-}

module Language.Java.JVM.Types where

import Foreign.C
import Foreign.Ptr
import Foreign.Storable
import Control.Monad.State

data JObject
type JObjectPtr=Ptr JObject
data JClass
type JClassPtr=Ptr JClass
data JRuntime
type JRuntimePtr=Ptr JRuntime

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
        alignment a=alignment (undefined :: CDouble)
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

type JavaT a= (StateT JRuntimePtr IO) a

 