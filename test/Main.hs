
module Main where

import Language.Java.JVM.APITest
import Language.Java.JVM.GeneratorTest
import Language.Java.JVM.JavapParserTest
import Language.Java.JVM.SignatureParserTest

--import Control.Monad
--import System.Exit (exitFailure)

import Test.Framework (defaultMain, testGroup,Test)
import Test.Framework.Providers.HUnit

main :: IO ()
main = defaultMain tests

tests :: [Test]
tests = [testGroup "API Tests" (concatMap (hUnitTestToTests) apiTests),
        testGroup "JavaP Parser Tests" (concatMap (hUnitTestToTests) javapParserTests),
        testGroup "Signature Parser Tests" (concatMap (hUnitTestToTests) [signatureParserTests]),
        testGroup "Generator Tests" (concatMap (hUnitTestToTests) generatorTests)]

--main :: IO()
--main = do
--    runHUnitTest apiTests
--    runHUnitTest javapParserTests
--    runHUnitTest signatureParserTests
--    runHUnitTest generatorTests
--    
--runHUnitTest :: Test -> IO ()
--runHUnitTest t=  do
--        counts1<-runTestTT t
--        when ((errors counts1)>0 || (failures counts1)>0) exitFailure     