{-# LANGUAGE RankNTypes #-}

module Language.Java.JVM.JavapParser where

import Language.Java.JVM.Types

import Data.Functor.Identity
import Data.List
import Data.Maybe

import Text.Parsec
import qualified Text.Parsec.Token as P
import Text.Parsec.Language (javaStyle)

  
data TypeDecl=TypeDecl {
        td_name::ClassName
        ,td_supers::[ClassName]
        ,td_decls::[Decl]
        }
        deriving (Show,Read)

data Decl=MethodDecl {
        d_name::String
        ,d_signature::String
        ,d_static::Bool
        }
        | FieldDecl {
        d_name::String
        ,d_signature::String
        ,d_static::Bool
        }
        deriving (Show,Read)
       
parseTypeDecl :: String -> Either ParseError TypeDecl
parseTypeDecl contents= parse typeDecl "unknown" contents

typeDecl ::ParsecT String u Identity TypeDecl
typeDecl=do
        modifiers
        choice [symbol "class",symbol "interface"]
        name<-className
        extends<-optionMaybe (do
                symbol "extends"
                classList
                )  
        implements<-optionMaybe (do
                symbol "implements"
                classList
                ) 
        return $ TypeDecl name (concat $ catMaybes [extends,implements]) []


classList :: ParsecT String u Identity [ClassName]
classList=sepBy1 className comma

className ::ParsecT String u Identity ClassName
className = do
      names<-sepBy1 identifier dot  
      return $concat $ intersperse "/" names

modifiers ::ParsecT String u Identity [String]
modifiers = many $ choice [
        symbol "public"
        ,symbol "protected"
        ,symbol "private"
        ,symbol "static"
        ,symbol "volatile"
        ,symbol "transient"
        ,symbol "final"]

lexer ::P.GenTokenParser String u Identity
lexer=P.makeTokenParser javaStyle    
parens      = P.parens lexer
braces      = P.braces lexer
identifier  = P.identifier lexer
symbol      = P.symbol lexer
dot         = P.dot lexer
comma         = P.comma lexer