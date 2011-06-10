
module Language.Java.JVM.SignatureParserTest where

import Language.Java.JVM.SignatureParser

import Test.HUnit

parse :: String -> IO (Maybe JSignature)
parse sig=do
        let ep=parseSignature sig
        case ep of
                Left err->do
                        assertFailure $ show err
                        return Nothing
                Right td->return $ Just td

signatureParserTests :: Test
signatureParserTests = TestLabel "signatureParserTests" (TestCase (do
        Just j0<-parse "()V"
        assertEqual "noargs, no ret" (JSignature [] Nothing) j0
        Just j1<-parse "(Ljava/lang/Object;)I"
        assertEqual "noargs, no ret" (JSignature ["JObj"] (Just "JInt")) j1
        Just j2<-parse "([CII)Ljava/lang/String;"
        assertEqual "noargs, no ret" (JSignature ["JObj","JInt","JInt"] (Just "JObj")) j2
        ))
        