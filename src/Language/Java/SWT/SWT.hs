
module Language.Java.SWT.SWT where

import Language.Java.JVM.API
import Language.Java.JVM.Types

import Control.Monad
import Foreign.C


displayLoop :: JObjectPtr -> JObjectPtr -> IO()
displayLoop display shell= do
       shellIsDisposed<-booleanMethod shell "isDisposed" "()Z" []
       when (not shellIsDisposed) (do 
                displayDispatch<-booleanMethod display "readAndDispatch" "()Z" []
                when (not displayDispatch) (
                        voidMethod display "sleep" "()V" []
                     )
                displayLoop display shell
           )
       return ()  

push :: CLong
push = 8

selection :: CLong
selection = 13