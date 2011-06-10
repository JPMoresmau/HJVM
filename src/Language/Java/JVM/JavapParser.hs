{-# LANGUAGE RankNTypes #-}

module Language.Java.JVM.JavapParser where

import Language.Java.JVM.Types

import Control.Monad
import Data.Functor.Identity
import Data.List
import Data.Maybe

import Text.Parsec
import qualified Text.Parsec.Token as P
import Text.Parsec.Language (javaStyle)

  
data TypeDecl=TypeDecl {
        td_name::ClassName
        ,td_supers::[ClassName]
        ,td_decls::[JDecl]
        }
        deriving (Show,Read,Eq,Ord)

data JDecl=JMethodDecl {
        d_name::String
        ,d_signature::String
        ,d_static::Bool
        }
        | JFieldDecl {
        d_name::String
        ,d_signature::String
        ,d_static::Bool
        }
        deriving (Show,Read,Eq,Ord)
       
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
        decls<-braces (do
                decls<-many $ decl
                return $ catMaybes decls)
        return $ TypeDecl name (concat $ catMaybes [extends,implements]) decls

decl :: ParsecT String u Identity (Maybe JDecl)
decl = do
        sta<-static
        choice [(do
                staticBlock
                return Nothing)
                ,(do
                        className
                        (name,meth)<-choice [(do
                                parens (classList0)
                                return ("<init>",True)
                                ),
                                (do
                                name <-identifier
                                p<-optionMaybe $ parens (classList0)
                                return (name,isJust p)
                                )
                                ]
                        when meth (optional (do
                                symbol "throws"
                                classList
                                ))
                        semi        
                        sign<-signature
                        return $ if meth
                                then Just $ JMethodDecl name sign sta
                                else Just $ JFieldDecl name sign sta
                )]

--methodDecl :: ParsecT String u Identity (Bool -> Decl)
--methodDecl=do
--        className
--        name<-choice [(do
--                parens (classList0)
--                return "<init>"
--                ),
--                (do
--                name <-identifier
--                parens (classList0)
--                return name
--                )
--                ]
--        optional (do
--                symbol "throws"
--                classList
--                )
--        semi        
--        sign<-signature
--        return $ MethodDecl name sign
--         
--fieldDecl :: ParsecT String u Identity (Bool -> Decl)
--fieldDecl=do
--        className
--        name<-identifier
--        semi        
--        sign<-signature
--        return $ FieldDecl name sign         
         
signature :: ParsecT String u Identity String
signature=do
        symbol "Signature"
        colon
        manyTill anyToken (try (newline))
               
staticBlock :: ParsecT String u Identity ()
staticBlock=do
        braces whiteSpace
        semi
        signature
        return ()

classList :: ParsecT String u Identity [ClassName]
classList=sepBy1 className comma

classList0 :: ParsecT String u Identity [ClassName]
classList0=sepBy className comma

className ::ParsecT String u Identity ClassName
className = do
      names<-sepBy1 identifier dot  
      optionMaybe $ brackets whiteSpace
      return $ intercalate "/" names

static :: ParsecT String u Identity Bool
static = do
        mds<-modifiers
        return $ elem "static" mds

modifiers ::ParsecT String u Identity [String]
modifiers = many $ try $ choice [
        try $ symbol "public"
        ,try $ symbol "protected"
        ,symbol "private"
        ,symbol "static"
        ,symbol "volatile"
        ,symbol "transient"
        ,symbol "final"
        ,symbol "native"]

lexer ::P.GenTokenParser String u Identity
lexer=P.makeTokenParser javaStyle  

parens :: ParsecT String u Identity a -> ParsecT String u Identity a  
parens      = P.parens lexer
braces ::  ParsecT String u Identity a -> ParsecT String u Identity a  
braces      = P.braces lexer
brackets ::  ParsecT String u Identity a -> ParsecT String u Identity a  
brackets      = P.brackets lexer

identifier :: ParsecT String u Identity String
identifier  = P.identifier lexer

symbol :: String -> ParsecT String u Identity String
symbol      = P.symbol lexer

dot :: ParsecT String u Identity String
dot         = P.dot lexer

comma :: ParsecT String u Identity String
comma       = P.comma lexer

colon :: ParsecT String u Identity String
colon       = P.colon lexer

semi :: ParsecT String u Identity String
semi        = P.semi lexer

whiteSpace :: ParsecT String u Identity ()
whiteSpace  = P.whiteSpace lexer