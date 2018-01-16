run("Set Measurements...", "mean redirect=None decimal=3");
run("32-bit");
for (i=1; i<147; i++){
	setSlice(i);
	makeRectangle(299, 169, 81, 83);
	run("Measure");
	bkgrnd=getResult("Mean",0);
	IJ.deleteRows(0, 0);
	run("Select None");
	run("Subtract...", "value="+bkgrnd+" slice");
	run("Measure");	
	licht=getResult("Mean",0);
	IJ.deleteRows(0, 0);
	//licht=i;
	run("Divide...", "value="+licht+" slice");
	
}
