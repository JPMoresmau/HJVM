
module Language.Java.JVM.Generator where

import Language.Java.JVM.JavapParser
import Language.Java.JVM.SignatureParser

import Control.Monad.Identity
import Control.Monad.State

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
        
generate :: TypeDecl -> (Module,FilePath)
generate td=let
        cls=td_name td
        moduleName=map toMod cls 
        fp=addExtension moduleName "hs"
        decls=runIdentity $ evalStateT (mapM (generateDecl cls) (td_decls td)) ((SrcLoc fp 5 1),Set.empty)
        imp=ImportDecl (SrcLoc fp 3 1) (ModuleName "Language.Java.JVM.Types") False False Nothing Nothing Nothing
        in (Module (SrcLoc fp 1 1) (ModuleName moduleName) [] Nothing Nothing [imp] decls,fp)
        where 
                toMod '/'='_'
                toMod a=a
                
generateDecl :: String -> JDecl -> SrcLocT Decl
generateDecl cls (JMethodDecl name signature static)=do
                sl<-srcLoc
                id<-identName name
                let 
                    Right (JSignature params ret)=parseSignature signature
                    exp=if name=="<init>" 
                        then
                               App (App (Var (UnQual (Ident "newObject"))) (Lit $ String cls)) (Lit $ String signature)
                        else 
                               let  
                                        methoddef=App (App (App (Con (UnQual (Ident "Method"))) (Lit $ String cls)) (Lit $ String name)) (Lit $ String signature)
                                        methodInvocation=Var (UnQual (Ident $ wrapperToMethod ret))
                                        obj=Var (UnQual (Ident "obj"))
                               in App (App methodInvocation obj) methoddef        
                    pats=zipWith (\_ idx->PVar $ Ident ("p"++(show idx))) params [0..]
                    patsWithObj=if name /= "<init>" && (not static)
                        then ((PVar $ Ident "obj") : pats)
                        else pats
                    parms=zipWith (\w idx->App (Var $ UnQual $ Ident w) (Var $ UnQual $ Ident ("p"++(show idx)))) params [0..]
                    rhs=UnGuardedRhs $ App exp $ List parms
                    m0=Match sl (Ident id) patsWithObj Nothing rhs (BDecls [])
                return $ FunBind [m0]
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

wrapperToUnwrapped :: String -> String
wrapperToUnwrapped "JObj"="JObjectPtr"
wrapperToUnwrapped "JInt"="CLong"
wrapperToUnwrapped "JBool"="CUChar"
wrapperToUnwrapped "JByte"="CChar"
wrapperToUnwrapped "JChar"="CUShort"
wrapperToUnwrapped "JShort"="CShort"
wrapperToUnwrapped "JLong"="CLong"
wrapperToUnwrapped "JFloat"="CFloat"
wrapperToUnwrapped "JDouble"="CDouble"
wrapperToUnwrapped a=error ("undefined wrapper"++a)

wrapperToMethod :: Maybe String -> String
wrapperToMethod (Just "JObj")="objectMethod"
wrapperToMethod (Just "JInt")="intMethod"
wrapperToMethod (Just "JBool")="boolMethod"
wrapperToMethod (Just "JByte")="byteMethod"
wrapperToMethod (Just "JChar")="charMethod"
wrapperToMethod (Just "JShort")="shortMethod"
wrapperToMethod (Just "JLong")="longMethod"
wrapperToMethod (Just "JFloat")="floatMethod"
wrapperToMethod (Just "JDouble")="doubleMethod"
wrapperToMethod Nothing="voidMethod"
wrapperToMethod (Just a)=error ("undefined wrapper"++a)
