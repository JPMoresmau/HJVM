
module Language.Java.JVM.Generator where

import Language.Java.JVM.JavapParser

import Text.Parsec
import System.Info
import System.FilePath
import System.Process

addExeExtension :: FilePath -> String
addExeExtension fn= case os of
        "mingw32"->addExtension fn "exe"
        "cygwin32"->addExtension fn "exe"
        "win32"->addExtension fn"exe"
        _->fn     

runJavap :: FilePath -> String -> IO(String)
runJavap javaHome className=do
        let javapPath=javaHome </> "bin" </> (addExeExtension "javap")
        s<-readProcess javapPath ["-s",className] ""
        let l=lines s
        case l of
                (_:xs)-> return $ unlines xs
                _ -> return ""

parseClass :: FilePath -> String -> IO (Either ParseError TypeDecl)
parseClass javaHome className=do
        contents<-runJavap javaHome className
        return $ parseTypeDecl contents