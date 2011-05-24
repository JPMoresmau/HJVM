rem %JAVA_HOME%\bin\javac -d bin src/Prog.java

rem %JAVA_HOME%\bin\javac -d bin -cp d:/dev/java/eclipse/plugins/org.eclipse.swt.win32.win32.x86_3.5.2.v3557f.jar src/Language/Java/SWT/NativeListener.java

dlltool --input-def jvm.def --kill-at --dllname jvm.dll --output-lib libjvm.dll.a

export jdk=/cygdrive/d/dev/java/jdk1.6.0_07

gcc -mno-cygwin -o invoke.exe -I$jdk/include -I$jdk/include/win32 invoke.c -L. -ljvm

rem gcc -I /d/dev/java/jdk1.6.0_07/include -I /d/dev/java/jdk1.6.0_07/include/win32  -L /d/dev/java/jdk1.6.0_07/lib invoke.c

ghc --make -main-is CallFoo -o callfoo CallFoo.hs foo.o


gcc -c -mno-cygwin -o hjvm.o -I$jdk/include -I$jdk/include/win32 hjvm.c -L.

ghc --make -main-is Java -o hjvm -L. -ljvm Java.hs hjvm.o