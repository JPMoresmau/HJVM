
module Language.Java.JVM.JavapParserTest where

import Language.Java.JVM.JavapParser
import Language.Java.JVM.Generator

import Test.HUnit

javaHome="d:\\dev\\java\\jdk1.6.0_07"

javapParserTests=TestList[testObject,testString]

parse cls=do
        ep<-parseClass javaHome cls
        case ep of
                Left err->do
                        assertFailure $ show err
                        return Nothing
                Right td->return $ Just td

testObject=TestLabel "testObject" (TestCase (do
        Just td<-parse "java/lang/Object"
        assertEqual "Object has supers!" 0 (length $ td_supers td)
        ))
        
testString=TestLabel "testString" (TestCase (do
        Just td<-parse "java/lang/String"
        assertEqual "String supers" ["java/lang/Object","java/io/Serializable","java/lang/Comparable","java/lang/CharSequence"] (td_supers td)
        ))