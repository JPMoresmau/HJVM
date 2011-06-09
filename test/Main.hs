
module Main where

import Language.Java.JVM.APITest
import Language.Java.JVM.JavapParserTest

import Control.Monad
import System.Exit (exitFailure)
import Test.HUnit

main = do
    counts1<-runTestTT apiTests
    when ((errors counts1)>0 || (failures counts1)>0) exitFailure
    counts2<-runTestTT javapParserTests
    when ((errors counts2)>0 || (failures counts2)>0) exitFailure