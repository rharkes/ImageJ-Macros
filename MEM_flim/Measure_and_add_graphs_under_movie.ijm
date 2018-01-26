
var graph_height=60;
var width_of_timepoint=1;	//stretching the graph in time
var line_width=2;
var normalized=false;
var y_min=3.3;
var y_max=3.8;
var smooth=false;
var smooth_radius=1;
colors = newArray("cyan","green","red","yellow","magenta","white");

original=getTitle();
getDimensions(width, height, channels, slices, frames);
//Arrays to hold data
means = newArray(frames);
stdDevs = newArray(frames);


roiManager("Reset");
roi_nr=0;
another_roi=true;
do {
	waitForUser("Select ROI(s) for analysis.");
	if(selectionType()>3) showMessage("Selection must be area type. Try again.");
	else if(selectionType()<0) showMessage("Selection required.");
	else {
		roiManager("Add");
		roiManager("Select",roiManager("Count")-1);
		roiManager("Remove Channel Info");
		roiManager("Remove Slice Info");
		roiManager("Remove Frame Info");
		roiManager("Rename","ROI_"+roi_nr);
		roi_nr++;
	}
another_roi=getBoolean("Continue selecting ROIs?");
} while(another_roi==true);
if(roi_nr==0) exit("Selection required. Exiting macro.");

//roi_nr=4;

//Create graph image
newImage("Graph", "RGB black", frames*width_of_timepoint, graph_height, 1);

setBatchMode(true);

//Measure ROIs and store in graph image
run("Set Measurements...", "  mean standard redirect=None decimal=3");
selectWindow(original);
for(i=0;i<roi_nr;i++) {
	selectWindow(original);
	roiManager("Select",i);
	for(f=0;f<frames;f++) {
		selectWindow(original);
		Stack.setFrame(f+1);
		List.setMeasurements();
		means[f]=List.getValue("Mean");
		stdDevs[f]=List.getValue("StdDev");
		//print(means[f]+" +- "+stdDevs[f]);
	}
	plot_graph(means,stdDevs,normalized);
}
setBatchMode("exit and display");
setBatchMode(false);
add_graph_to_image("Graph");





function plot_graph(means,stdDevs,normalized) {
	Array.getStatistics(means, means_min, means_max, means_mean);
	Array.getStatistics(stdDevs, stdDevs_min, stdDevs_max, stdDevs_mean);

	selectWindow("Graph");
	setColor(colors[i]);
	run("Line Width...", "line="+line_width);
	if(normalized==true) {
		x0=0;
		y0=graph_height-(means[0]-means_min)/(means_max-means_min)*graph_height;
		moveTo(x0,y0);						//set location to first drawing point
		for(f=0;f<frames;f++) {
			x=f*width_of_timepoint;
			y=graph_height-(means[f]-means_min)/(means_max-means_min)*graph_height;
			lineTo(x,y); 					//draw line to value in graph
		}
	}
	else {
		x0=0;
		y0=graph_height-(means[0]-y_min)/(y_max-y_min)*graph_height;
		moveTo(x0,y0);						//set location to first drawing point
		for(f=0;f<frames;f++) {
			x=f*width_of_timepoint;
			y=graph_height-(means[f]-y_min)/(y_max-y_min)*graph_height;
			lineTo(x,y); 					//draw line to value in graph
		}
	}
}


function add_graph_to_image(graph) {
	selectWindow(graph);
	graph_width=getWidth;	//same as frames
	graph_height=getHeight;	//same as graph_height
	run("Copy");
	
	selectWindow(original);
	run("Select None");
	run("Duplicate...", "title=movie duplicate");
	if(smooth==true) run("Mean...", "radius="+smooth_radius+" stack");
	
	run("RGB Color");
	showStatus("increasing size...");
	run("Canvas Size...", "width="+width+" height="+height+graph_height+" position=Top-Left zero");
	showStatus("Adding graph...");

	//Draw ROIs in image
	run("Line Width...", "line="+line_width);
	for(i=0;i<roiManager("Count");i++) {
		roiManager("Select",i);
		run("Colors...", "foreground="+colors[i]);
		run("Draw","stack");
	}

	//Draw graph underneath image
	run("Line Width...", "line=1");
	setColor("White");
	setBatchMode(true);
	for(f=0;f<frames;f++) {
		Stack.setFrame(f+1);
		drawLine(0, height-1, width, height-1);	//Draw white line on the last pixel row of the image
		makeRectangle(minOf(0,width-(f+1)*width_of_timepoint), height, graph_width, graph_height);
		run("Paste");
		makeRectangle((f+1)*width_of_timepoint, height, graph_width, graph_height);
		run("Clear", "slice");	//make dark
	}
	setBatchMode(false);
	run("Select None");
	Stack.setFrame(1);
}



















