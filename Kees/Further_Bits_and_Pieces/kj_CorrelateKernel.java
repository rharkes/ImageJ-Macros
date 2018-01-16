import ij.*;
import ij.plugin.filter.PlugInFilter;
import ij.plugin.filter.Printer;
import ij.process.*;
import java.awt.*;


// This sample ImageJ plugin filter implements a 3 x 3 smooth on byte data. KJ Feb 2010
//for some reason I do not understand, it automatically copes with stacks as well

public class kj_CorrelateKernel implements PlugInFilter {

	public int setup(String arg, ImagePlus imp) {
		return DOES_ALL+DOES_STACKS+SUPPORTS_MASKING;
	}

	public void run(ImageProcessor ip) {
		Rectangle r = ip.getRoi();
print(r);
		int kernelWidth=3, kernelHeight = 3;
		for (int y=r.y; y<(r.y+r.height); y++) {                  //count the lines
			for (int x=r.x; x<(r.x+r.width); x++){     //for each pixel in the line
//here starts a complicated piece of kees-logic to make sure it can calculate pixels based on kernels, but
//avoid that I have to take the image in memory twice. One needs to know the kernel size for that first. here: 3 x 3 
				
				int even = 0;
				even=255-ip.get(x,y);
				ip.set(x,y,even);
				}

			}
		}

	}

