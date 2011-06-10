
module Language.Java.JVM.GeneratorTest where

import Language.Java.JVM.Generator
import Language.Java.JVM.JavapParserTest (parse)
import Language.Haskell.Exts.Pretty

import Test.HUnit

generatorTests :: Test
generatorTests = TestList [testObject]

testObject :: Test
testObject=TestLabel "testObject" (TestCase (do
        Just td<-parse "java/lang/Object"
        let (mod,fp)=generate td
        putStrLn $ prettyPrint mod
        ))