
module Main where

import Language.Java.JVM.APITest
import Language.Java.JVM.GeneratorTest
import Language.Java.JVM.JavapParserTest
import Language.Java.JVM.SignatureParserTest

import Control.Monad
import System.Exit (exitFailure)
import Test.HUnit

main :: IO()
main = do
    runHUnitTest apiTests
    runHUnitTest javapParserTests
    runHUnitTest signatureParserTests
    runHUnitTest generatorTests
    
runHUnitTest :: Test -> IO ()
runHUnitTest t=  do
        counts1<-runTestTT t
        when ((errors counts1)>0 || (failures counts1)>0) exitFailure     