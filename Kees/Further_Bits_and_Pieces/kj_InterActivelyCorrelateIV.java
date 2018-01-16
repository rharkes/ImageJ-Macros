import ij.*;
import ij.plugin.filter.PlugInFilter;
import ij.process.*;
import ij.process.ImageProcessor.*;
import java.awt.*;
import java.lang.Math;
import ij.gui.*;
import ij.plugin.*;
import java.io.*;
import ij.ImagePlus; 							//import maar een zooitje.....

/* Kees-Iris TestDrive  User sets roi and plugin searches for it in the pic
NOTE still does not do stacks 
R=Sum(Xi-Xm)(Yi-Ym) / sqrt(Sum(Xi-Xm)^2).sqrt(Sum(Yi-Ym)^2)
 */

public class kj_InterActivelyCorrelateIV implements PlugInFilter {

public int setup(String arg,  ImagePlus imp) {
	return DOES_ALL;
}

public void run(ImageProcessor ip) {
	Rectangle r = ip.getRoi(); 					//this is the roi that sets the correlation kernel
	int kernelWidth =r.width;
	int kernelHeight = r.height;
	int halfKernelWidth = (int)(kernelWidth/2 + 0.5);
	int halfKernelHeight = (int) (kernelHeight/2 + 0.5);	
	int imWidth=ip.getWidth();
	int imHeight=ip.getHeight();	
	ImageProcessor ip2 = ip.duplicate(); 				//create a copy for output
	ImageProcessor kernel = ip.crop();				//separate ip for the kernel
	int N = kernel.getWidth() * kernel.getHeight();			//nr of pixels in the kernel
	double R=0;
	float Ym=0;
	float Xm=0;
	float Teller;
	float sumYiMinYmSqr = 0; 					
	float sumXiMinXmSqr= 0; 					
	double sqrtSumYiMinYmSqr = 0; 				//this is the last third of the equation
	double sqrtSumXiMinXmSqr= 0; 				//this is the first half of the divisor
	int even = 0;
	float effe = 0; 

				//--------------R=Sum(Xi-Xm)(Yi-Ym) / sqrt(Sum(Xi-Xm)^2).sqrt(Sum(Yi-Ym)^2) 

	for(int i = 0; i< kernelHeight; i ++){				//FIRST [1] calculate all Y things out of the loop 
		for (int j=0; j < kernelWidth; j++){
			even = even + kernel.get(j,i);
		}
	}
	Ym = even / N;							//This is Ymean
		 		//--------------------------------------------------
	for(int i = 0; i< kernelHeight; i ++){				//[2] Now sqrt(Sum(Yi-Ym)^2)
		for (int j=0; j < kernelWidth; j++){
			effe = kernel.get(j,i)-Ym;
			effe = effe * effe;				//faster than sqr
			sumYiMinYmSqr=sumYiMinYmSqr+effe;
		}
	}
	sqrtSumYiMinYmSqr = Math.sqrt(sumYiMinYmSqr);	//this is sqrt(Sum(Yi-Ym)^2)

				//--------------------Now for each imageSubKernel: THE BIG LOOP--------------------------
	for (int y=halfKernelHeight; y<imHeight-halfKernelHeight; y++){ //count the lines
		for (int x=halfKernelWidth; x<imWidth-halfKernelWidth; x++){ //for each pixel in the line
			even = 0;
			for(int Y = -halfKernelHeight; Y < halfKernelHeight; Y++){ 
				for(int X = -halfKernelWidth; X < halfKernelWidth; X++){
					even=even+ip.get(x + X,y + Y);
				}
			}
			Xm = even/N; 					//this is Xmean for the subkernel
			effe = 0;					//next sqrt(Sum(Xi-Xm)^2) en de teller
			Teller =0;
			sumXiMinXmSqr = 0;
			for(int Y = -halfKernelHeight; Y < halfKernelHeight; Y++){
				for(int X= -halfKernelWidth; X < halfKernelWidth; X++){ 
					Teller = Teller +((ip.get(x+X, y+Y)-Xm)*(kernel.get(X+halfKernelWidth, Y + halfKernelHeight)-Ym));
					effe = ip.get(x,y) -Xm;
					effe = effe * effe;
					sumXiMinXmSqr = sumXiMinXmSqr+effe;
				}
			}
		 		//--------------------------------------------------
			sqrtSumXiMinXmSqr = Math.sqrt(sumXiMinXmSqr);
			R = Teller / (sqrtSumXiMinXmSqr*sqrtSumYiMinYmSqr);	// this is R for this pixel
			R =(R+1)*127;							//scale from (-1to+1) to byte
			byte RR = (byte)R;
			ip2.set(x,y,RR);  

		}
	}			
	//----------------
		
	String Tietel="This is the copy, Iris";
	ImagePlus keesImPlus = new ImagePlus(Tietel, ip2);		//result
	keesImPlus.show();
	ImagePlus kerneltje = new ImagePlus("kernel", kernel); 	//ter controle only
	kerneltje.show();
}
}

