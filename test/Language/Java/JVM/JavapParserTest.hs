
module Language.Java.JVM.JavapParserTest where

import Language.Java.JVM.JavapParser
import Language.Java.JVM.Generator

import System.Environment

import Test.HUnit

javapParserTests::Test
javapParserTests=TestList[testObject,testString]

parse :: String -> IO (Maybe TypeDecl)
parse cls=do
        javaHome<-getEnv "JAVA_HOME"
        ep<-parseClass javaHome cls
        case ep of
                Left err->do
                        assertFailure $ show err
                        return Nothing
                Right td->return $ Just td

testObject :: Test
testObject=TestLabel "testObject" (TestCase (do
        Just td<-parse "java/lang/Object"
        assertEqual "Object has supers!" 0 (length $ td_supers td)
        assertBool "Object has no decls!" (0<(length $ td_decls td))
        let toString=JMethodDecl "toString" "()Ljava/lang/String;" False -- simple method
        assertBool "Doesn't contain toString" (elem toString $ td_decls td)
        let cons=JMethodDecl "<init>" "()V" False
        assertBool "Doesn't contain constructor" (elem cons $ td_decls td) -- constructor
        let wait=JMethodDecl "wait" "(J)V" False
        assertBool "Doesn't contain wait" (elem wait $ td_decls td) -- throws
        ))
 
testString :: Test       
testString=TestLabel "testString" (TestCase (do
        Just td<-parse "java/lang/String"
        assertEqual "String supers" ["java/lang/Object","java/io/Serializable","java/lang/Comparable","java/lang/CharSequence"] (td_supers td)
        let comp=JFieldDecl "CASE_INSENSITIVE_ORDER" "Ljava/util/Comparator;" True -- static field
        assertBool "Doesn't contain CASE_INSENSITIVE_ORDER" (elem comp $ td_decls td)
        let cons=JMethodDecl "<init>" "([C)V" False
        assertBool "Doesn't contain constructor" (elem cons $ td_decls td) -- constructor with array parameter
        ))