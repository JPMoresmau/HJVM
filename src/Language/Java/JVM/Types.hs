{-# LANGUAGE ForeignFunctionInterface, EmptyDataDecls, TypeSynonymInstances, RankNTypes, ImpredicativeTypes, MultiParamTypeClasses, FlexibleInstances #-}

module Language.Java.JVM.Types where

import qualified Data.Map as Map
import Foreign.C
import Foreign.Ptr
import Foreign.Storable
import Data.Map (Map)
import Control.Concurrent.MVar
import Control.Monad.State

data JObject
type JObjectPtr=Ptr JObject
data JClass
type JClassPtr=Ptr JClass
data JMethod
type JMethodPtr=Ptr JMethod
data JField
type JFieldPtr=Ptr JField
--data JRuntime
--type JRuntimePtr=Ptr JRuntime

newtype TypedJObjectPtr a=TypedJObjectPtr JObjectPtr
        deriving (Eq,Show)
        
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

--class MethodProvider a where
--        getMethodID :: a -> IO (JMethodPtr)

--instance MethodProvider JMethodPtr where
--        getMethodID=return

type ClassName = String

data Method = Method {
        m_class::ClassName
        ,m_name:: String
        ,m_signature:: String
        }
        deriving (Read,Show,Eq,Ord)

data Field= Field {
        f_class::ClassName
        ,f_name:: String
        ,f_signature:: String
        }
        deriving (Read,Show,Eq,Ord)
        
type ClassCache=Map ClassName JClassPtr
type MethodCache=Map Method JMethodPtr
type FieldCache=Map Field JFieldPtr
        
data JavaCache=JavaCache {
        jc_classes::ClassCache
        ,jc_methods::MethodCache
        ,jc_fields::FieldCache
        }        
        
type JavaT =StateT JavaCache IO
     
class (Monad m, MonadIO m) => WithJava m where
        getJavaCache  :: m JavaCache
        putJavaCache  :: JavaCache -> m()
        
instance WithJava JavaT where
        getJavaCache = do
                rt<-get
                return rt
        putJavaCache=put

javaToHaskell :: (HaskellJavaConversion h j,WithJava m)=> m j -> m h
javaToHaskell = liftM toHaskell

haskellToJava :: (HaskellJavaConversion h j,WithJava m)=> m h -> m j
haskellToJava = liftM fromHaskell
        
class HaskellJavaConversion h j where
        toHaskell :: j -> h
        fromHaskell :: h -> j
        
instance HaskellJavaConversion Float CFloat where
        toHaskell = realToFrac
        fromHaskell = realToFrac
        
instance HaskellJavaConversion Double CDouble where
        toHaskell = realToFrac
        fromHaskell = realToFrac
                
instance HaskellJavaConversion Integer CLong where
        toHaskell = fromIntegral
        fromHaskell = fromIntegral
        
instance HaskellJavaConversion Int CChar where
        toHaskell = fromIntegral  
        fromHaskell = fromIntegral        
        
instance HaskellJavaConversion Int CShort where
        toHaskell = fromIntegral  
        fromHaskell = fromIntegral  

instance HaskellJavaConversion Bool CUChar where
        toHaskell = (0 /=)   
        fromHaskell True = 1
        fromHaskell False = 0   

instance HaskellJavaConversion Char CUShort where
        toHaskell = toEnum . fromIntegral
        fromHaskell = fromIntegral . fromEnum

instance HaskellJavaConversion JObjectPtr JObjectPtr where
        toHaskell = id    
        fromHaskell = id    
          