//kj_ColorCodeDirections..... kj, March 2015. find main directions of filaments and color-code them by 
//convolution with a line-segment kernel.
//It creates a line-kernel, convolutes the inputPic with it, and attaches that to a new stack.
//Then it rotates the kernel, convolutes and attaches again, etc, until rotated by 180 Deg (=0 Deg)
//Then  for each pixel it looks in the stack of rotary convolutions for the rotation that maximally fits 
//(a slicenumber) and assigns a color to it.
//Finally it masks the image by the thresholded input image.

KernelSize=23;
NrOfDirections=60; //max 180 directions
kjFreemReet = 16;
kjGausBlurSize=2;
kjDeleteIntermediates=true;
kjDisplayWindRose=true;
kjDisplayStack = false;
kjDisplayKernel=true;
kjGausBlur=true;
kjBatchMode=true;
kjLineWidth=1;
kjMedFilter=true;
kjSaveDirectionStack=true;
//run("Close All");

path_1 = File.openDialog("Select filament file");
open (path_1);
rename("First.tif");
run("8-bit");
run("Duplicate...", "title=Second.tif"); //store a copy to create the stack
run("Duplicate...", "title=OutputStack.tif"); //store a copy to create the stack
if(kjSaveDirectionStack==true){
run("Duplicate...", "title=ForCoOrientation.tif"); //store a copy for later	
}

//Present and read dialog
Dialog.create("Adjust Parameters....");						//DIALOG CREATE section
Dialog.addCheckbox("no, it's enough", 0); 					// 		<1>NOTE it reads checks and texts in this order!!!!!
Dialog.addNumber("KernelSize",KernelSize); 					//		<2>
Dialog.addNumber("# of Analyzed Directions",NrOfDirections);//		<3>
Dialog.addNumber("FrameRate",kjFreemReet); 					//		<4>
Dialog.addNumber("Kernel Line Width", kjLineWidth);			// 		<4A>
Dialog.addNumber("Gaussian Blurr Size", kjGausBlurSize);	//		<5>
Dialog.addCheckbox("Delete intermediate Results", kjDeleteIntermediates); //   <6>		
Dialog.addCheckbox("Display Wind Rose", kjDisplayWindRose); //   	<7>	
Dialog.addCheckbox("Display Kernel", kjDisplayKernel); 		// 	  	<8>	
Dialog.addCheckbox("Display Stack", kjDisplayStack); 		//   	<9>	
Dialog.addCheckbox("Apply Blurr to Kernel", kjGausBlur); 	//   	<9A>	
Dialog.addCheckbox("Batchmode", kjBatchMode); 				//   	<10>	
Dialog.addCheckbox("Median-filter Result", kjMedFilter);	//	 	<11>
Dialog.addCheckbox("Save Stack for Co-orientation", kjSaveDirectionStack); // 	<12>
Dialog.show;

StopMaar = Dialog.getCheckbox();				//		<1>DIALOG READOUT section
if (StopMaar==true) exit;
KernelSize = Dialog.getNumber(); 				//		<2>
NrOfDirections = Dialog.getNumber(); 			//		<3>
kjFreemReet = Dialog.getNumber(); 				//		<4>
kjLineWidth=Dialog.getNumber();					//		<4A>
kjGausBlurSize = Dialog.getNumber();			//		<5>
kjDeleteIntermediates=Dialog.getCheckbox();		//		<6>
kjDisplayWindRose = Dialog.getCheckbox(); 		//		<7>
kjDisplayKernel = Dialog.getCheckbox(); 		//		<8>
kjDisplayStack = Dialog.getCheckbox(); 			//		<9>
kjGausBlur = Dialog.getCheckbox(); 				//		<9A>
kjBatchMode = Dialog.getCheckbox(); 			//		<10>
kjMedFilter=Dialog.getCheckbox();				//		<11>
kjSaveDirectionStack=Dialog.getCheckbox();		//		<12>
//GO!!
RotateStep = 180/NrOfDirections;
run("Line Width...", "line="+kjLineWidth);
for(i=1;i<=NrOfDirections;i++){
	//create a first kernelImage of twice the Kernelsize squared for generaton of the kerneltext
	//make it bigger than kernel because of rotation; otherwise it pads with zero's
	setTool("line");
	run("Colors...", "foreground=white background=white selection=yellow");
	newImage("kjKernel", "8-bit black", 1+2*KernelSize, 1+2*KernelSize, 1); 
	makeLine(KernelSize, 0, KernelSize, 2*KernelSize);
	run("Draw");
	run("Fill", "slice");
	run("Select None");
	if (kjGausBlur==true){
		run("Gaussian Blur...", "sigma="+kjGausBlurSize);
	}
	run("Rotate... ", "angle="+(i*RotateStep)+" grid=1 interpolation=Bilinear fill");
	makeRectangle(1+KernelSize/2, 1+KernelSize/2, KernelSize, KernelSize);
	run("Crop"); //trim it back to the kernelsize. This avoids black corners

	//convert kernel to string. Gejat van Bram 
	kernel_text = "";
	for(y=0;y<KernelSize;y++) {
		for(x=0;x<KernelSize;x++) {
			kernel_text = kernel_text + toString(getPixel(x,y)) + " ";
		}
		kernel_text = kernel_text + "\n";
	}
	
	selectWindow("First.tif");
	run("Duplicate...", "title=InputPic.tif");
	selectWindow("InputPic.tif");
	run("Convolve...", "text1=["+kernel_text+"] normalize");
	//print(kernel_text);
	run("Concatenate...", "  title=OutputStack.tif image1=OutputStack.tif image2=InputPic.tif image3=[-- None --]");
	if (i==1) {
		selectWindow("kjKernel");
		rename("KernelStack");
	}
	else{
	run("Concatenate...", "  title=KernelStack image1=KernelStack image2=kjKernel image3=[-- None --]");
	}
	print("Step# "+i +" of "+ NrOfDirections + " --Rotation "+(i*RotateStep)+" degrees --Kernel Blurr "+kjGausBlurSize+"--Width "+kjLineWidth);
}


selectWindow("OutputStack.tif");
setSlice(1);
run("Delete Slice"); //throw away the first slices
run("Duplicate...", "title=CopyStack.tif duplicate");

	//Now find out which direction (which plane in the stack) is dominant for each pixel
selectWindow("OutputStack.tif");
run("Z Project...", "projection=[Max Intensity]");
rename("MaxImage.tif");
run("Subtract...", "value=1"); //MaxImage = the max value of all slices (=convolutions) minus 1

for(i=1;i<=NrOfDirections;i++){
selectWindow("OutputStack.tif");
setSlice(i);
imageCalculator("Subtract", "OutputStack.tif","MaxImage.tif"); //only if the pixelvalue in this slice (i) is actually the
	//largest, it will be positive (+1), else it will be 0 or negative and hence, thrown away. This finds very effectively
	//in which slice the max is present.
run("Multiply...", "value="+i+" slice"); //then the gray value in slice i will be i if it is the max
}

run("Z Project...", "projection=[Max Intensity]"); //and this shows the orientation
run("kjDirectionsLUT2");
run("Brightness/Contrast...");

selectWindow("First.tif"); //MAKE first result
run("Auto Threshold", "method=Huang white");
imageCalculator("Min create", "MAX_OutputStack.tif","First.tif");
rename("HuangedResult.tif");
setMinAndMax(0, NrOfDirections-1);
	//THIS has created the Huang-thresholded result

selectWindow("HuangedResult.tif"); //MAKE second result
run("Duplicate...", "title=SecondResult.tif");
run("RGB Color");
run("RGB Stack");
selectWindow("Second.tif");
run("32-bit");
run("Divide...", "value=255");
imageCalculator("Multiply create 32-bit stack", "SecondResult.tif","Second.tif");
rename("IntensModulatedResult.tif");
run("8-bit");
run("Stack to RGB");
run("Enhance Contrast", "saturated=0.35");
if (kjMedFilter==true){
run("Median...");
}
	//THIS has created the intensity-modulated result image

	if(kjSaveDirectionStack==true){
		selectWindow("First.tif");		
		run("8-bit");
		setAutoThreshold("Default dark");
		setOption("BlackBackground", true);
		run("Convert to Mask");
		imageCalculator("Min create stack", "OutputStack.tif","First.tif");
		selectWindow("Result of OutputStack.tif");
		rename("DirectionStack");
	}
if (kjDeleteIntermediates == true){
	selectWindow("IntensModulatedResult.tif");
	close();
	selectWindow("SecondResult.tif");
	close();
	selectWindow("MAX_OutputStack.tif");
	close();
	selectWindow("MaxImage.tif");
	close();
	selectWindow("OutputStack.tif");
	close();
	selectWindow("First.tif");
	close();
	run("Tile");
}

selectWindow("KernelStack");
if(kjDisplayKernel==true){
	run("Size...", "width=256 height=256 constrain average interpolation=None");
	run("Fire");
	run("Enhance Contrast", "saturated=0.35");
}
else{
	close();
}

if(kjDisplayWindRose == true){
	//Next, create a separate graywedge-LUT/Windrose
	newImage("kjDirectionsLUT", "8-bit ramp", 256, 31, 1);
	run("Rotate 90 Degrees Right");
	
	run("kjDirectionsLUT2"); //Next make the windrose
	newImage("kjWindroos", "8-bit black", 130, 256, 0);
	for(i=1;i<=NrOfDirections;i++){
		setTool("line");
		run("Line Width...", "line=1");
		j=i*RotateStep*3.1415/180;
		//print(j);
		makeLine(2, 127, 2+127*sin(j), 127-127*cos(j));
		setForegroundColor(i,i,i);
		run("Draw");
	}
	run("Multiply...", "value="+255/NrOfDirections);
	run("kjDirectionsLUT2");
	run("Combine...", "stack1=kjDirectionsLUT stack2=kjWindroos"); 
	rename("WindRose");
	Overlay.remove;
	setFont("SanSerif", 15, "antialiased");
	setColor("black");
	Overlay.drawString("+90", 0, 20);
	Overlay.drawString("0", 0, 135);
	Overlay.drawString("-90", 0,255);
	Overlay.show(); //Done with Lut/Windrose
}

selectWindow("CopyStack.tif");
if (kjDisplayStack==true){
	run("Enhance Contrast", "saturated=0.35");
	run("Animation Options...", "speed=kjFreemReet first=1 last=9999 start");
	doCommand("Start Animation [\\]");}
else {
	close();	
}





	