
module Language.Java.JVM.APITest where


import Language.Java.JVM.API
import Language.Java.JVM.Types

import Control.Monad.IO.Class
import Foreign.Ptr

import System.IO.Error
import Test.HUnit

apiTests=TestList[testStartEnd,testClassNotFound,testMethodNotFound,testNewString,testIntMethod,testCharMethod,testByteMethod,testShortMethod,testLongMethod,testDoubleMethod,testFloatMethod,testBooleanMethod]


testStartEnd=TestLabel "testStartEnd" (TestCase (do
        withJava' False "" (do
                liftIO $ assertBool "true" True
                return ()
                )
        ))
  
testClassNotFound  =TestLabel "testClassNotFound" (TestCase (do
        ejo<-try $ withJava' False "" (newObject "java/lang/Integer2" "(I)V" [JInt 25])
        case ejo of
                Left ior ->return()
                Right obj->assertFailure "should be able to create Integer2"
        el<-try $ withJava' False "" (do
                jo<-newObject "java/lang/Integer" "(I)V" [JInt 25]
                byteMethod jo (Method "java/lang/Integer2" "byteValue" "()B") []
                )
        case el of
              Left ior ->return()
              Right b->assertFailure "should be able to call byteValue on Integer2"
        ))
        
testMethodNotFound  =TestLabel "testMethodNotFound" (TestCase (do
        el<-try $ withJava' False "" (do
                jo<-newObject "java/lang/Integer" "(I)V" [JInt 25]
                byteMethod jo (Method "java/lang/Integer" "byteValue2" "()B") []
                )
        case el of
              Left ior ->return()
              Right b->assertFailure "should be able to call byteValue2 on Integer"
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
                l<-intMethod jo (Method "java/lang/String" "length" "()I") []
                liftIO $ assertEqual "jo" 5 l
                return ())
        ))

testCharMethod=TestLabel "testCharMethod" (TestCase (do
        withJava' False "" (do
                jo<-toJString "hello"
                l<-charMethod jo  (Method "java/lang/String" "charAt" "(I)C") [JInt 0]
                liftIO $ assertEqual "h" 'h' l
                return ())
        ))
        
testByteMethod=TestLabel "testByteMethod" (TestCase (do
        withJava' False "" (do
                jo<-newObject "java/lang/Integer" "(I)V" [JInt 25]
                l<-byteMethod jo (Method "java/lang/Integer" "byteValue" "()B") []
                liftIO $ assertEqual "25" 25 l
                return ())
        ))       
      
testShortMethod=TestLabel "testShortMethod" (TestCase (do
        withJava' False "" (do
                jo<-newObject "java/lang/Integer" "(I)V" [JInt 25]
                l<-shortMethod jo (Method "java/lang/Integer" "shortValue" "()S") []
                liftIO $ assertEqual "25" 25 l
                return ())
        ))       
     
testLongMethod=TestLabel "testLongMethod" (TestCase (do
        withJava' False "" (do
                jo<-newObject "java/lang/Integer" "(I)V" [JInt 25]
                l<-longMethod jo (Method "java/lang/Integer" "longValue" "()J") []
                liftIO $ assertEqual "25" 25 l
                return ())
        ))       
      
testDoubleMethod=TestLabel "testDoubleMethod" (TestCase (do
        withJava' False "" (do
                jo<-newObject "java/lang/Double" "(D)V" [JDouble 25.67]
                l<-doubleMethod jo (Method "java/lang/Double" "doubleValue" "()D") []
                liftIO $ assertEqual "25.67" 25.67 l
                return ())
        ))          

testFloatMethod=TestLabel "testFloatMethod" (TestCase (do
        withJava' False "" (do
                jo<-newObject "java/lang/Float" "(F)V" [JFloat 25.67]
                l<-floatMethod jo (Method "java/lang/Float" "floatValue" "()F") []
                liftIO $ assertEqual "25.67" 25.67 l
                return ())
        ))       
        
testBooleanMethod=TestLabel "testBooleanMethod" (TestCase (do
        withJava' True "" (do
                jo<-toJString "hello"
                l<-booleanMethod jo (Method "java/lang/String" "equals" "(Ljava/lang/Object;)Z") [JObj jo]
                liftIO $ assertBool "equals" l
                return ())
        ))
        

        