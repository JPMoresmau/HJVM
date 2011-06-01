{-# LANGUAGE ForeignFunctionInterface, EmptyDataDecls #-}
module Java where 

import Control.Monad
import qualified Data.Map as Map

import Foreign.C
import Foreign.Ptr
import Foreign.Marshal.Alloc
import Foreign.Marshal.Array
import Foreign.Storable
import Control.Concurrent.MVar

data JObject
type JObjectPtr=Ptr JObject
data JClass
type JClassPtr=Ptr JClass

data JValue=JObj JObjectPtr
        | JInt CLong
        | JBool CUChar

type JValuePtr=Ptr JValue

instance Storable JValue where
        sizeOf a=8 
        alignment a=8
        poke p (JObj ptr)=poke (castPtr p) ptr
        poke p (JInt l)=poke (castPtr p) l
        poke p (JBool l)=poke (castPtr p) l
        peek=error "undefined peek"

foreign import ccall safe "start" start ::CString -> FunPtr (CLong ->JObjectPtr -> IO()) -> IO (CInt)
foreign import ccall safe "end" end :: IO ()
--foreign import ccall "test" test ::CInt -> IO (CInt)

foreign import ccall safe "findClass" findClass :: CString -> IO (JClassPtr)
foreign import ccall safe "newObject" newObject :: JClassPtr -> CString -> JValuePtr -> IO (JObjectPtr)
foreign import ccall safe "callIntMethod" callIntMethod ::JObjectPtr -> CString -> CString -> JValuePtr -> IO (CLong)
foreign import ccall safe "callVoidMethod" callVoidMethod ::JObjectPtr -> CString -> CString -> JValuePtr -> IO ()
foreign import ccall safe "callBooleanMethod" callBooleanMethod ::JObjectPtr -> CString -> CString -> JValuePtr -> IO (CUChar)
foreign import ccall safe "newString" newString :: CWString -> CLong -> IO (JObjectPtr)


foreign import ccall "wrapper" wrap :: (CLong -> JObjectPtr -> IO()) -> IO (FunPtr (CLong -> JObjectPtr -> IO()))
{--
data JNIEnv = JNIEnv
type JNIEnvHandle = Ptr JNIEnv

data JavaVM = JavaVM
type JavaVMHandle = Ptr JavaVM

data JavaVMInitArgs = JavaVMInitArgs
type JavaVMInitArgsHandle = Ptr JavaVMInitArgs


main = do
    ret<-alloca (\jvm-> alloca (\env-> alloca (\args->createJavaVM jvm env args)))
    putStrLn (show ret)--}
        
--main = do
--    ret<-withCString "-Djava.class.path=bin" start
--    putStrLn (show ret)
--    when (ret>(-1)) (do
--            --ret2<-test ret
--            --putStrLn (show ret2)
--            clsName<-newCString "Prog"
--            cls<-withCString "Prog" findClass
--            putStrLn (show cls)
--            obj<-withCString "()V" (\s->newObject cls s nullPtr)
--            putStrLn (show obj)
--            arr<-newArray [JInt 5]
--            ret4<-withCString "getMethod" (\m->(withCString "(I)I" (\s->callIntMethod obj m s arr)))
--            putStrLn (show ret4)
--            ret5<-withCString "getMethod" (\m->(withCString "()I" (\s->callVoidMethod obj m s nullPtr)))
--            putStrLn (show ret5)
--            end
--        )

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
          listenerCls<-withCString "NativeListener" findClass
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
          
          wait display shell
          
          voidMethod display "dispose" "()V" []
          end
          )
 
event :: MVar (Map.Map CLong (JObjectPtr -> IO()))->  CLong -> JObjectPtr -> IO()
event mvar index eventObj=do
        putStrLn "event"
        putStrLn ("listenerEvt:"++(show index))
        withMVar mvar (\m->do
                let handler=Map.lookup index m
                case handler of
                        Nothing-> return ()
                        Just h->h eventObj
                )
        
          
voidMethod :: JObjectPtr -> String -> String -> [JValue] -> IO()          
voidMethod obj method signature args=  
        withCString method
                (\m->withCString signature
                        (\s->withArray args (\arr->callVoidMethod obj m s arr)))            

booleanMethod :: JObjectPtr -> String -> String -> [JValue] -> IO(Bool)          
booleanMethod obj method signature args= do
        ret<-withCString method
                (\m->withCString signature
                        (\s->withArray args (\arr->callBooleanMethod obj m s arr)))    
        return (ret/=0)
          
wait :: JObjectPtr -> JObjectPtr -> IO()
wait display shell= do
       shellIsDisposed<-booleanMethod shell "isDisposed" "()Z" []
       when (not shellIsDisposed) (do 
                displayDispatch<-booleanMethod display "readAndDispatch" "()Z" []
                when (not displayDispatch) (
                        voidMethod display "sleep" "()V" []
                     )
                wait display shell
           )
       return ()      
   
toJString :: String -> IO JObjectPtr
toJString s=  withCWString s (\cs->newString cs (fromIntegral $ length s))
