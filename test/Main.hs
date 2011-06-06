
module Main where

import Language.Java.JVM.APITest

import Control.Monad
import System.Exit (exitFailure)
import Test.HUnit

main = do
    counts<-runTestTT apiTests
    when ((errors counts)>0 || (failures counts)>0) exitFailure