run("Clear Results");
getDimensions(width, height, channels, slices, frames);
row = 0;
for (i=0;i<roiManager("count");i++) {
	roiManager("Select",i);
	for(y=0;y<height;y++) {
		for(x=0;x<width;x++) {
			if(Roi.contains(x,y)) {
				setResult("r", row, i);
				setResult("x", row, x);
				setResult("y", row, y);
				row++;
			}
		}	
	}
}	
