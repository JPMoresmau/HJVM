 public class Prog {
     public static void main(String[] args) {
          System.out.println("Hello World " + args[0]);
     }
     
     public int getMethod(){
    	 return 4; 
     }
     
     public int getMethod(int a){
    	 System.out.println("a:"+a);
    	 return a+1; 
     }
 }