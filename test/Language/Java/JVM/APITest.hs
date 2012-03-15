
module Language.Java.JVM.APITest where


import Language.Java.JVM.API
import Language.Java.JVM.Types

import Control.Monad.IO.Class
import Foreign.Ptr

import System.IO.Error
import Test.HUnit

apiTests::[Test]
apiTests=[testStart,testClassNotFound,testMethodNotFound,testNewString,testIntMethod,testCharMethod,testByteMethod
        ,testShortMethod,testLongMethod,testDoubleMethod,testFloatMethod,testBooleanMethod,testObjectMethod,testException
        ,testStaticIntMethod,testStaticObjectMethod,testStaticIntField,testIntField,testInterfaceMethod
        ,testEnd]

testStart :: Test
testStart=TestLabel "testStartEnd" (TestCase (do
        withJava' False "" (do
                liftIO $ assertBool "true" True
                return ()
                )
        ))

testEnd :: Test
testEnd=TestLabel "testEnd" (TestCase (do
        withJava' True "" (do
                liftIO $ assertBool "true" True
                return ()
                )
        ))  
  
testClassNotFound :: Test
testClassNotFound  =TestLabel "testClassNotFound" (TestCase (do
        ejo<-try $ withJava' False "" (newObject "java/lang/Integer2" "(I)V" [JInt 25])
        case ejo of
                Left _ ->return()
                Right _->assertFailure "should be able to create Integer2"
        el<-try $ withJava' False "" (do
                withObject (newObject "java/lang/Integer" "(I)V" [JInt 25]) (\jo->
                        byteMethod jo (Method "java/lang/Integer2" "byteValue" "()B") [])
                )
        case el of
              Left _ ->return()
              Right _->assertFailure "should be able to call byteValue on Integer2"
        ))
        
testMethodNotFound :: Test
testMethodNotFound  =TestLabel "testMethodNotFound" (TestCase (do
        el<-try $ withJava' False "" (do
                jo<-newObject "java/lang/Integer" "(I)V" [JInt 25]
                byteMethod jo (Method "java/lang/Integer" "byteValue2" "()B") []
                )
        case el of
              Left _ ->return()
              Right _->assertFailure "should not be able to call byteValue2 on Integer"
        ))
        
        
testNewString :: Test       
testNewString=TestLabel "testNewString" (TestCase (do
        withJava' False "" (do
                withObject (toJString "hello") (\jo->
                        liftIO $ assertBool "jo"  (nullPtr/=jo))
                return ())
        ))
        
testIntMethod :: Test
testIntMethod=TestLabel "testIntMethod" (TestCase (do
        withJava' False "" (do
                jo<-toJString "hello"
                l<-intMethod jo (Method "java/lang/String" "length" "()I") []
                liftIO $ f_freeObject jo
                liftIO $ assertEqual "jo" 5 l
                return ())
        ))

testCharMethod :: Test
testCharMethod=TestLabel "testCharMethod" (TestCase (do
        withJava' False "" (do
                jo<-toJString "hello"
                l<-charMethod jo  (Method "java/lang/String" "charAt" "(I)C") [JInt 0]
                liftIO $ assertEqual "h" 'h' l
                return ())
        ))
        
testByteMethod :: Test        
testByteMethod=TestLabel "testByteMethod" (TestCase (do
        withJava' False "" (do
                jo<-newObject "java/lang/Integer" "(I)V" [JInt 25]
                l<-byteMethod jo (Method "java/lang/Integer" "byteValue" "()B") []
                liftIO $ assertEqual "25" 25 l
                return ())
        ))       
 
testShortMethod :: Test      
testShortMethod=TestLabel "testShortMethod" (TestCase (do
        withJava' False "" (do
                jo<-newObject "java/lang/Integer" "(I)V" [JInt 25]
                l<-shortMethod jo (Method "java/lang/Integer" "shortValue" "()S") []
                liftIO $ assertEqual "25" 25 l
                return ())
        ))       
     
testLongMethod :: Test     
testLongMethod=TestLabel "testLongMethod" (TestCase (do
        withJava' False "" (do
                jo<-newObject "java/lang/Integer" "(I)V" [JInt 25]
                l<-longMethod jo (Method "java/lang/Integer" "longValue" "()J") []
                liftIO $ assertEqual "25" 25 l
                return ())
        ))       
      
testDoubleMethod :: Test      
testDoubleMethod=TestLabel "testDoubleMethod" (TestCase (do
        withJava' False "" (do
                jo<-newObject "java/lang/Double" "(D)V" [JDouble 25.67]
                l<-doubleMethod jo (Method "java/lang/Double" "doubleValue" "()D") []
                liftIO $ assertEqual "25.67" 25.67 l
                return ())
        ))          

testFloatMethod :: Test
testFloatMethod=TestLabel "testFloatMethod" (TestCase (do
        withJava' False "" (do
                jo<-newObject "java/lang/Float" "(F)V" [JFloat 25.67]
                l<-floatMethod jo (Method "java/lang/Float" "floatValue" "()F") []
                liftIO $ assertEqual "25.67" 25.67 l
                return ())
        ))       
 
testBooleanMethod :: Test        
testBooleanMethod=TestLabel "testBooleanMethod" (TestCase (do
        withJava' False "" (do
                jo<-toJString "hello"
                l<-booleanMethod jo (Method "java/lang/String" "equals" "(Ljava/lang/Object;)Z") [JObj jo]
                liftIO $ f_freeObject jo
                liftIO $ assertBool "equals" l
                return ())
        ))
 
testObjectMethod :: Test        
testObjectMethod=TestLabel "testObjectMethod" (TestCase (do
        withJava' False "" (do
                jo<-newObject "java/lang/Integer" "(I)V" [JInt 25]
                s<-objectMethod jo (Method "java/lang/Object" "toString" "()Ljava/lang/String;") []
                liftIO $ f_freeObject jo
                freeClass "java/lang/Integer"
                liftIO $ assertBool "toString" (nullPtr/=s)
                liftIO $ f_freeObject s
                return ())
        ))     
   
   
testStaticIntMethod :: Test
testStaticIntMethod=TestLabel "testStaticIntMethod" (TestCase (do
        withJava' False "" (do
                jo<-toJString "5"
                jc<-findClass "java/lang/Integer"
                l<-staticIntMethod jc (Method "java/lang/Integer" "parseInt" "(Ljava/lang/String;)I") [JObj jo]
                liftIO $ f_freeClass jc
                liftIO $ f_freeObject jo
                liftIO $ assertEqual "parseInt" 5 l
                return ())
        ))   
   
testStaticObjectMethod :: Test
testStaticObjectMethod=TestLabel "testStaticObjectMethod" (TestCase (do
        withJava' False "" (do
                jc<-findClass "java/lang/Integer"
                jo<-staticObjectMethod jc (Method "java/lang/Integer" "valueOf" "(I)Ljava/lang/Integer;") [JInt 5]
                liftIO $ assertBool "testStaticObjectMethod" (nullPtr/=jo)
                liftIO $ f_freeClass jc
                liftIO $ f_freeObject jo
                return ())
        ))      
   
testStaticIntField   :: Test
testStaticIntField=TestLabel "testStaticIntField" (TestCase (do
        withJava' False "" (do
                jc<-findClass "java/lang/Integer"
                l<-getStaticIntField jc (Field "java/lang/Integer" "MAX_VALUE" "I")
                liftIO $ assertBool "testStaticIntField" (l>0)
                liftIO $ f_freeClass jc
                return ())
        ))      
   
testException :: Test        
testException=TestLabel "testException" (TestCase (do
        el<-try $ withJava' False "" (do
                s<-toJString "aa"
                newObject "java/lang/Integer" "(Ljava/lang/String;)V" [JObj s]
                )
        case el of
              Left _ ->return()
              Right _->assertFailure "should be not able to call new Integer with aa"
        ))   
        
testIntField :: Test
testIntField=TestLabel "testIntField" (TestCase (do
        withJava' False "" (do
                pt<-newObject "java/awt/Point" "()V" []
                let fx=Field "java/awt/Point" "x" "I"
                x1<-getIntField pt fx
                liftIO $ assertEqual "x1 is not 0" 0 x1
                setIntField pt fx 100
                x2<-getIntField pt fx
                liftIO $ assertEqual "x2 is not 100" 100 x2
                return ())
        ))
        
testInterfaceMethod :: Test
testInterfaceMethod=TestLabel "testInterfaceMethod" (TestCase (do
        withJava' False "" (do
                jc<-findClass "java/text/NumberFormat"
                jo<-staticObjectMethod jc (Method "java/text/NumberFormat" "getInstance" "()Ljava/text/NumberFormat;") []
                s<-objectMethod jo (Method "java/text/NumberFormat" "format" "(D)Ljava/lang/String;") [JDouble 5.3]
                liftIO $ assertBool "format" (nullPtr/=s)
                liftIO $ f_freeObject s
                liftIO $ f_freeObject jo
                liftIO $ f_freeClass jc
                )
        ))        