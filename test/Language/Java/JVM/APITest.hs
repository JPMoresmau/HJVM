
module Language.Java.JVM.APITest where


import Language.Java.JVM.API
import Language.Java.JVM.Types

import Control.Monad.IO.Class
import Foreign.Ptr

import Test.HUnit

apiTests=TestList[testStartEnd,testNewString,testIntMethod,testCharMethod,testByteMethod,testShortMethod,testLongMethod,testDoubleMethod,testFloatMethod,testBooleanMethod]


testStartEnd=TestLabel "testStartEnd" (TestCase (do
        withJava' False "" (do
                liftIO $ assertBool "true" True
                return ()
                )
        ))
        
testNewString=TestLabel "testNewString" (TestCase (do
        withJava' False "" (do
                jo<-toJString "hello"
                liftIO $ assertBool "jo"  (nullPtr/=jo)
                return ())
        ))
        
testIntMethod=TestLabel "testIntMethod" (TestCase (do
        withJava' False "" (do
                jo<-toJString "hello"
                l<-intMethod jo ("java/lang/String","length","()I") []
                liftIO $ assertEqual "jo" 5 l
                return ())
        ))

testCharMethod=TestLabel "testCharMethod" (TestCase (do
        withJava' False "" (do
                jo<-toJString "hello"
                l<-charMethod jo  ("java/lang/String","charAt","(I)C") [JInt 0]
                liftIO $ assertEqual "h" 'h' l
                return ())
        ))
        
testByteMethod=TestLabel "testByteMethod" (TestCase (do
        withJava' False "" (do
                cls<-findClass "java/lang/Integer"
                jo<-newObject cls "(I)V" [JInt 25]
                l<-byteMethod jo (cls,"byteValue","()B") []
                liftIO $ assertEqual "25" 25 l
                return ())
        ))       
      
testShortMethod=TestLabel "testShortMethod" (TestCase (do
        withJava' False "" (do
                cls<-findClass "java/lang/Integer"
                mid<-getMethodID (cls,"shortValue","()S")
                jo<-newObject cls "(I)V" [JInt 25]
                l<-shortMethod jo mid []
                liftIO $ assertEqual "25" 25 l
                return ())
        ))       
     
testLongMethod=TestLabel "testLongMethod" (TestCase (do
        withJava' False "" (do
                cls<-findClass "java/lang/Integer"
                jo<-newObject cls "(I)V" [JInt 25]
                l<-longMethod jo (cls,"longValue","()J") []
                liftIO $ assertEqual "25" 25 l
                return ())
        ))       
      
testDoubleMethod=TestLabel "testDoubleMethod" (TestCase (do
        withJava' False "" (do
                cls<-findClass "java/lang/Double"
                jo<-newObject cls "(D)V" [JDouble 25.67]
                l<-doubleMethod jo (cls,"doubleValue","()D") []
                liftIO $ assertEqual "25.67" 25.67 l
                return ())
        ))          

testFloatMethod=TestLabel "testFloatMethod" (TestCase (do
        withJava' False "" (do
                cls<-findClass "java/lang/Float"
                jo<-newObject cls "(F)V" [JFloat 25.67]
                l<-floatMethod jo (cls,"floatValue","()F") []
                liftIO $ assertEqual "25.67" 25.67 l
                return ())
        ))       
        
testBooleanMethod=TestLabel "testBooleanMethod" (TestCase (do
        withJava' True "" (do
                jo<-toJString "hello"
                l<-booleanMethod jo ("java/lang/String","equals","(Ljava/lang/Object;)Z") [JObj jo]
                liftIO $ assertBool "equals" l
                return ())
        ))
        

        