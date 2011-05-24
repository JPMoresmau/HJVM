package Language.Java.SWT;

import org.eclipse.swt.widgets.Event;
import org.eclipse.swt.widgets.Listener;

public class NativeListener implements Listener {
	private int index;
	
	public NativeListener (int i){
		i=index;
	}
	
	public void handleEvent(Event paramEvent) {
		nativeEvent(index,paramEvent);			
	}
	
	public native void nativeEvent(int index,Event paramEvent);
}