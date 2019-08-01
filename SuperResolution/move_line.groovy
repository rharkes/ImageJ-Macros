import ij.IJ
import ij.gui.Roi
import ij.gui.PolygonRoi

nr_of_pixels_to_move = 20

if (ij.WindowManager.getImageCount()==0){
	IJ.noImage()
	return
}
imp = IJ.getImage()
myRoi = imp.getRoi()
if ((myRoi==null)||myRoi.getType()!=Roi.POLYLINE){
	IJ.error("ROI is not a polyline")
	return
}
if (myRoi.isSplineFit()){
	myRoi.removeSplineFit() 
	print("removed splinefit")
}

FP = myRoi.getFloatPolygon()
FPi = myRoi.getInterpolatedPolygon(0.1, false)
for (int i = 0 ; i<FP.npoints;i++){
	int closestPoint =  myRoi.getClosestPoint(FP.xpoints[i], FP.ypoints[i], FPi)
	if (closestPoint==0){
		dx = FPi.xpoints[1]-FPi.xpoints[0]
		dy = FPi.ypoints[0]-FPi.ypoints[1]
	} else if (closestPoint==(FPi.npoints-1)) {
		dx = FPi.xpoints[closestPoint]-FPi.xpoints[closestPoint-1]
		dy = FPi.ypoints[closestPoint-1]-FPi.ypoints[closestPoint]
	} else {
		dx = FPi.xpoints[closestPoint+1]-FPi.xpoints[closestPoint-1]
		dy = FPi.ypoints[closestPoint-1]-FPi.ypoints[closestPoint+1]
	}
	L = Math.sqrt(dx*dx+dy*dy)
	FP.xpoints[i] = FP.xpoints[i] + (nr_of_pixels_to_move*dy/L);
	FP.ypoints[i] = FP.ypoints[i] + (nr_of_pixels_to_move*dx/L);
}
myRoi2 = new PolygonRoi(FP,Roi.POLYLINE)
imp.setRoi(myRoi2)
imp.show()