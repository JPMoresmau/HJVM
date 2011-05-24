{-# LANGUAGE ,ForeignFunctionInterface, EmptyDataDecls #-}

module Language.Java.JVM.Types where

import Foreign.C
import Foreign.Ptr
import Foreign.Storable

data JObject
type JObjectPtr=Ptr JObject
data JClass
type JClassPtr=Ptr JClass

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
        sizeOf _= #size jvalue
        alignment a=alignment (undefined :: CDouble)
        poke p (JObj l)= poke p l
        poke p (JInt i)= (poke p i
        poke p (JBool z)= poke p z
        poke p (JByte b)= poke p b
        poke p (JChar c)= poke p c
        poke p (JShort s)= poke p s
        poke p (JLong j)= poke p j
        poke p (JFloat f)= poke p f
        poke p (JDouble d)= poke p d
        peek=error "undefined peek"

data JNIEnv


 