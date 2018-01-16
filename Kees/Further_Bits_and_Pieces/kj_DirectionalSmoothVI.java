import ij.*;
import ij.plugin.filter.PlugInFilter;
import ij.process.*;
import ij.process.ImageProcessor.*;
import java.awt.*;
import ij.gui.*;
import ij.plugin.*;
import ij.ImagePlus; //import maar een zooitje.....

/* Kees-Iris TestDrive  GENERAL FRAME FOR CALCULATION INTO NEW IMAGE
INTERMEDIATE version with solved: 1) makes a new window; 2) any size input (not just 500),
3) the user sets the smooth kernel with a rectangle ROI.
NOTE still does not do stacks */

public class kj_DirectionalSmoothVI implements PlugInFilter {

	public int setup(String arg,  ImagePlus imp) {
		return DOES_ALL+SUPPORTS_MASKING;
	}

	public void run(ImageProcessor ip) {
	Rectangle r = ip.getRoi(); //this is the roi that sets the correlation kernel
	int kernelWidth =r.width;
	int kernelHeight = r.height;
	int halfKernelWidth = (int)(kernelWidth/2 + 0.5);
	int halfKernelHeight = (int) (kernelHeight/2 + 0.5);	
	int imWidth=ip.getWidth();
	int imHeight=ip.getHeight();	
	ImageProcessor ip2 = ip.duplicate(); 				//create a copy
//------------------
	for (int y=halfKernelHeight; y<imHeight-halfKernelHeight; y++) //count the lines
		for (int x=halfKernelWidth; x<imWidth-halfKernelWidth; x++){ //for each pixel in the line
			int even = 0;
		
			for(int Y = -halfKernelHeight; Y < halfKernelHeight; Y++){ 
				for(int X = -halfKernelWidth; X < halfKernelWidth; X++){
					even=even+ip.get(x + X,y + Y);
				}
			}
			even=even/(kernelWidth*kernelHeight);
			ip2.set(x,y,even);
		}
//----------------
	String Tietel="This is the copy, Iris";
	ImagePlus keesImPlus = new ImagePlus(Tietel, ip2);
	keesImPlus.show();
		}
	}


