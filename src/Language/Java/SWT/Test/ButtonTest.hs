
module Language.Java.SWT.Test.ButtonTest where

import Control.Monad
import Control.Monad.State
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
      --eventW<-wrap (event ior)
      --ret<-withCString "-Djava.class.path=bin;d:/dev/java/eclipse/plugins/org.eclipse.swt.win32.win32.x86_3.5.2.v3557f.jar" (\s->start s eventW)
      withJava "-Djava.class.path=bin;d:/dev/java/eclipse/plugins/org.eclipse.swt.win32.win32.x86_3.5.2.v3557f.jar" (event ior) (do
      --putStrLn (show ret)
      --when (ret>(-1)) (do
          displayCls<- findClass "org/eclipse/swt/widgets/Display"
          liftIO $ putStrLn ("displayCls:"++(show displayCls))
          shellCls<- findClass "org/eclipse/swt/widgets/Shell"
          liftIO $ putStrLn ("shellCls:"++(show shellCls)) 
          layoutCls<- findClass "org/eclipse/swt/layout/FillLayout"
          liftIO $ putStrLn ("layoutCls:"++(show layoutCls)) 
          buttonCls<- findClass "org/eclipse/swt/widgets/Button"
          liftIO $ putStrLn ("buttonCls:"++(show buttonCls)) 
          listenerCls<-findClass "Language/Java/SWT/NativeListener" 
          liftIO $ putStrLn ("listenerCls:"++(show listenerCls)) 
          
          display<-newObject displayCls "()V" []
          liftIO $ putStrLn ("display:"++(show display))
          
          shell<-newObject shellCls "(Lorg/eclipse/swt/widgets/Display;)V" [JObj display]
          liftIO $ putStrLn ("shell:"++(show shell))
          
          text<-toJString "Hello SWT From Haskell"
          voidMethod shell "setText" "(Ljava/lang/String;)V" [JObj text]
          voidMethod shell "setSize" "(II)V" [JInt 300,JInt 200]

          layout<-newObject layoutCls "()V" []
          liftIO $ putStrLn ("layout:"++(show layout))
          
          voidMethod shell "setLayout" "(Lorg/eclipse/swt/widgets/Layout;)V" [JObj layout]
         
          button<-newObject buttonCls "(Lorg/eclipse/swt/widgets/Composite;I)V" [JObj shell,JInt 8]  -- SWT.PUSH
          liftIO $ putStrLn ("button:"++(show button))
          
          text2<-toJString "Click me"
          voidMethod button "setText" "(Ljava/lang/String;)V" [JObj text2]
          
          rt<-get
          liftIO $ modifyMVar ior (\m-> do
                let index=fromIntegral $ Map.size m
                evalStateT (do
                        listener<-newObject listenerCls "(I)V" [JInt index]
                        liftIO $ putStrLn ("listener:"++(show listener))
                        voidMethod button "addListener" "(ILorg/eclipse/swt/widgets/Listener;)V" [JInt 13,JObj listener]  -- SWT.Selection
                        ) rt
                return (Map.insert index (\e->do
                        putStrLn ("button clicked")
                        modifyMVar count (\c->do
                                let nc=c+1
                                let s=if nc==1 then "once." else ((show nc)++ " times.")
                                evalStateT (do
                                        text3<-toJString ("Clicked "++s)
                                        voidMethod button "setText" "(Ljava/lang/String;)V" [JObj text3]
                                        ) rt
                                return(nc,())
                             )
                        ) m,()))
          
          voidMethod shell "open" "()V" []
          
          displayLoop display shell
          
          voidMethod display "dispose" "()V" []
          )
 