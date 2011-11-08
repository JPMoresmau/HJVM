
module Language.Java.JVM.Generator where

import Language.Java.JVM.JavapParser
import Language.Java.JVM.SignatureParser

import Control.Monad.Identity
import Control.Monad.State

import Data.Char (toUpper)
import Data.List (foldl')
import qualified Data.Set as Set

import Language.Haskell.Exts.Syntax
import Text.Parsec
import System.Info
import System.FilePath
import System.Process


addExeExtension :: FilePath -> String
addExeExtension fn= case os of
        "mingw32"->addExtension fn "exe"
        "cygwin32"->addExtension fn "exe"
        "win32"->addExtension fn "exe"
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
        
generate :: TypeDecl -> (Module,FilePath)
generate td=let
        cls=td_name td
        moduleName=map toMod (zip [0..] cls)
        fp=addExtension moduleName "hs"
        decls=concat $ runIdentity $ evalStateT (mapM (generateDecl cls) (td_decls td)) ((SrcLoc fp 6 1),Set.empty)
        impTypes=ImportDecl (SrcLoc fp 3 1) (ModuleName "Language.Java.JVM.Types") False False Nothing Nothing Nothing
        impAPI=ImportDecl (SrcLoc fp 3 1) (ModuleName "Language.Java.JVM.API") False False Nothing Nothing Nothing
        in (Module (SrcLoc fp 2 1) (ModuleName ("Language.Java.JVM.Bindings."++moduleName)) [LanguagePragma (SrcLoc fp 1 1) [Ident "RankNTypes"]] Nothing Nothing [impTypes,impAPI] decls,fp)
        where 
                toMod (_,'/')='_'
                toMod (0,a)=toUpper a
                toMod (_,a)=a
                
generateDecl :: String -> JDecl -> SrcLocT [Decl]
generateDecl cls (JMethodDecl name signature static)=do
                slTyp<-srcLoc
                slFun<-srcLoc
                id<-identName name
                let 
                    Right (JSignature params ret)=parseSignature signature
                    (exp,ret')=if name=="<init>" 
                        then
                               (App (App (Var (UnQual (Ident "newObject"))) (Lit $ String cls)) (Lit $ String signature),Just "JObj")
                        else 
                               let  
                                        methoddef=App (App (App (Con (UnQual (Ident "Method"))) (Lit $ String cls)) (Lit $ String name)) (Lit $ String signature)
                                        methodInvocation=Var (UnQual (Ident $ wrapperToMethod ret))
                                        obj=Var (UnQual (Ident "obj"))
                               in (App (App methodInvocation obj) methoddef,ret)        
                    pats=zipWith (\_ idx->PVar $ Ident ("p"++(show idx))) params [0..]
                    patsWithObj=if name /= "<init>" && (not static)
                        then ((PVar $ Ident "obj") : pats)
                        else pats
                    parms=zipWith (\w idx->App (Var $ UnQual $ Ident w) $ cast w (Var $ UnQual $ Ident ("p"++(show idx)))) params [0..]
                    rhs=UnGuardedRhs $ App exp $ List parms
                    m0=Match slFun (Ident id) patsWithObj Nothing rhs (BDecls [])
                    retType=TyApp (TyVar $ Ident "m") (TyVar $ Ident $ wrapperToUnwrapped ret')
                    paramType=foldl' (\t p->(TyFun (TyVar $ Ident $ wrapperToUnwrapped $ Just p) t)) retType params
                    objType=if name=="<init>" 
                        then paramType
                        else (TyFun (TyVar $ Ident "JObjectPtr") paramType)
                    typ=TyForall Nothing [ClassA (UnQual $ Ident "WithJava") [(TyVar $ Ident "m")]] objType
                    sig=TypeSig slFun [Ident id] typ
                return $ [sig,FunBind [m0]]
generateDecl cls (JFieldDecl name signature static)=undefined

type SrcLocT=StateT GenState Identity

type GenState=(SrcLoc,Set.Set String)

srcLoc :: SrcLocT SrcLoc
srcLoc= do
        sl<-gets fst
        modify (\((SrcLoc fp l c),g)->(SrcLoc fp (l+1) c,g))
        return sl

identName:: String -> SrcLocT String
identName n=do
        names<-gets snd
        let
                n'=if n=="<init>"
                        then "new"
                        else n
                possibleNames=[n'] ++ (map (\idx->(n')++(show idx)) [1..])
                okNames=filter (\pn->Set.notMember pn names) possibleNames
                firstOK=head okNames
        modify (\(s,ns)->(s,Set.insert firstOK ns))
        return firstOK

cast :: String -> Exp -> Exp
cast "JLong"= App (Var $ UnQual $ Ident "fromIntegral")
cast "JInt"= App (Var $ UnQual $ Ident "fromIntegral")
cast _=id

wrapperToUnwrapped :: Maybe String -> String
wrapperToUnwrapped (Just "JObj")="JObjectPtr"
wrapperToUnwrapped (Just "JInt")="Integer"
wrapperToUnwrapped (Just "JBool")="Bool"
wrapperToUnwrapped (Just "JByte")="Int"
wrapperToUnwrapped (Just "JChar")="Char"
wrapperToUnwrapped (Just "JShort")="Int"
wrapperToUnwrapped (Just "JLong")="Integer"
wrapperToUnwrapped (Just "JFloat")="Float"
wrapperToUnwrapped (Just "JDouble")="Double"
wrapperToUnwrapped Nothing="()"
wrapperToUnwrapped (Just a)=error ("undefined wrapper"++a)

wrapperToMethod :: Maybe String -> String
wrapperToMethod (Just "JObj")="objectMethod"
wrapperToMethod (Just "JInt")="intMethod"
wrapperToMethod (Just "JBool")="booleanMethod"
wrapperToMethod (Just "JByte")="byteMethod"
wrapperToMethod (Just "JChar")="charMethod"
wrapperToMethod (Just "JShort")="shortMethod"
wrapperToMethod (Just "JLong")="longMethod"
wrapperToMethod (Just "JFloat")="floatMethod"
wrapperToMethod (Just "JDouble")="doubleMethod"
wrapperToMethod Nothing="voidMethod"
wrapperToMethod (Just a)=error ("undefined wrapper"++a)
