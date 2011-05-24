
module Language.Java.SWT.Test.ButtonTest where

import Control.Monad
import qualified Data.Map as Map


import Language.Java.JVM.API
import Language.Java.JVM.Types
import Language.Java.SWT.SWT

import Foreign.C
import Foreign.Ptr
import Foreign.Marshal.Alloc
import Foreign.Marshal.Array
import Foreign.Storable
import Control.Concurrent.MVar

main = do
      ior<-newMVar Map.empty
      count<-newMVar 0
      eventW<-wrap (event ior)
      ret<-withCString "-Djava.class.path=bin;d:/dev/java/eclipse/plugins/org.eclipse.swt.win32.win32.x86_3.5.2.v3557f.jar" (\s->start s eventW)
      putStrLn (show ret)
      when (ret>(-1)) (do
          displayCls<-withCString "org/eclipse/swt/widgets/Display" findClass
          putStrLn ("displayCls:"++(show displayCls))
          shellCls<-withCString "org/eclipse/swt/widgets/Shell" findClass
          putStrLn ("shellCls:"++(show shellCls)) 
          layoutCls<-withCString "org/eclipse/swt/layout/FillLayout" findClass
          putStrLn ("layoutCls:"++(show layoutCls)) 
          buttonCls<-withCString "org/eclipse/swt/widgets/Button" findClass
          putStrLn ("buttonCls:"++(show buttonCls)) 
          listenerCls<-withCString "Language/Java/SWT/NativeListener" findClass
          putStrLn ("listenerCls:"++(show listenerCls)) 
          
          
          display<-withCString "()V" (\s->newObject displayCls s nullPtr)
          putStrLn ("display:"++(show display))
          
          arr1<-newArray [JObj display]
          shell<-withCString "(Lorg/eclipse/swt/widgets/Display;)V" (\s->newObject shellCls s arr1)
          putStrLn ("shell:"++(show shell))
          free arr1
          
          text<-toJString "Hello SWT From Haskell"
          voidMethod shell "setText" "(Ljava/lang/String;)V" [JObj text]
          voidMethod shell "setSize" "(II)V" [JInt 300,JInt 200]

          layout<-withCString "()V" (\s->newObject layoutCls s nullPtr)
          putStrLn ("layout:"++(show layout))
          
          voidMethod shell "setLayout" "(Lorg/eclipse/swt/widgets/Layout;)V" [JObj layout]
         
          arr2<-newArray [JObj shell,JInt 8]  -- SWT.PUSH
          button<-withCString "(Lorg/eclipse/swt/widgets/Composite;I)V" (\s->newObject buttonCls s arr2)
          putStrLn ("button:"++(show button))
          free arr2
          text2<-toJString "Click me"
          voidMethod button "setText" "(Ljava/lang/String;)V" [JObj text2]
          

          modifyMVar ior (\m-> do
                let index=fromIntegral $ Map.size m
                arr3<-newArray [JInt index]
                listener<-withCString "(I)V" (\s->newObject listenerCls s arr3)
                putStrLn ("listener:"++(show listener))
                free arr3
                voidMethod button "addListener" "(ILorg/eclipse/swt/widgets/Listener;)V" [JInt 13,JObj listener]  -- SWT.Selection
                
                return (Map.insert index (\e->do
                        putStrLn ("button clicked")
                        modifyMVar count (\c->do
                                let nc=c+1
                                let s=if nc==1 then "once." else ((show nc)++ " times.")
                                text3<-toJString ("Clicked "++s)
                                voidMethod button "setText" "(Ljava/lang/String;)V" [JObj text3]
                                return(nc,())
                             )
                        ) m,()))
          
          voidMethod shell "open" "()V" []
          
          displayLoop display shell
          
          voidMethod display "dispose" "()V" []
          end
          )
 