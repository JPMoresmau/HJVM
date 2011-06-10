
module Language.Java.JVM.SignatureParser where

import Data.Functor.Identity
import Text.Parsec


data JSignature=JSignature [String] (Maybe String)
        deriving (Read,Show,Eq,Ord)

parseSignature :: String -> Either ParseError JSignature
parseSignature contents= parse signature "unknown" contents

signature :: ParsecT String u Identity JSignature
signature = do
        char '('
        params<-many typeSignature
        char ')'
        ret<-choice [(do
                t<-typeSignature
                return $ Just t),(do
                char 'V'
                return Nothing)]
        return $ JSignature params ret
        
typeSignature :: ParsecT String u Identity String
typeSignature = choice [(do
                char '['
                ts<-typeSignature
                return "JObj"
                --return (ts++"[]")
                
        ),(do
                char 'L'
                manyTill (anyChar) (try $ char ';')
                return "JObj")
        ,(do
                char 'I'
                return "JInt")
        ,(do
                char 'S'
                return "JShort")
        ,(do
                char 'Z'
                return "JBool")
        ,(do
                char 'B'
                return "JByte")
        ,(do
                char 'D'
                return "JDouble")
        ,(do
                char 'F'
                return "JFloat")
        ,(do
                char 'C'
                return "JChar")
        ,(do
                char 'J'
                return "JLong")
        ] 