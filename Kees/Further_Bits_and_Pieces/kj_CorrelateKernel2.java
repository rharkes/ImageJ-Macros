import ij.*;
import ij.plugin.filter.PlugInFilter;
import ij.process.*;
import java.awt.*;

// This sample ImageJ plugin filter implements a 3 x 3 smooth on byte data. KJ Feb 2010
// It first creates a bu copy to copy from and then implements the filter

public class kj_CorrelateKernel2 implements PlugInFilter {

	public int setup(String arg, ImagePlus imp) {
		return DOES_ALL+DOES_STACKS+SUPPORTS_MASKING;
	}

	public void run(ImageProcessor ip) {
		int imWidth=ip.getWidth();
		int imHeight=ip.getHeight();	
		Rectangle r = ip.getRoi(); 			//r.x, r.y, r.height, r.width zijn de belangrijke
		int kernelHalfWidth = r.width/2;
		int kernelHalfHeight = r.height/2;
		int kernelWidth = r.width;
		int kernelHeight = r.height;
		int kernelLeft = r.x;
		int kernelTop = r.y;
//NOTE this version still goes wrong if no square roi exists............		
		ImageProcessor ipFloat = new FloatProcessor(imWidth, imHeight);		//create a copy in which to place the result	

		for (int y = kernelHalfHeight; y<imHeight-kernelHalfHeight; y++)
			for (int x = kernelHalfWidth; x<imWidth-kernelHalfWidth; x++){	
//				for (int p = 0; p< kernelHeight; p++)
//					for (int q = 0; q < kernelWidth; q++){
int even = ip.get(x,y);
even=even*even;
even=even/240;
ipFloat.set(x,y,even);
ip.set(x,y,ipFloat.get(x,y));
//					}\

	
//				int even=ip2.get(x,y);
//  even=255-even; //effe inverten voor zichtbaarheid
//				if (even<1) even=1;
//				if (even>255) even=255;
//				ip.set(x,y,even);


			}
					
		}
	}

