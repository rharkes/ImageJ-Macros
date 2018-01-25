// @File(label = "Input directory", style = "directory") input
// @File(label = "Output file", style = "file") output
// @String(label = "File suffix", value = ".tif") suffix

/*
 * Macro template to process multiple images in a folder
 */

processFolder(input);

// function to scan folders/subfolders/files to find files with correct suffix
function processFolder(input) {
	list = getFileList(input);
	list = Array.sort(list)
	for (i = 0; i < list.length; i++) {
		if(File.isDirectory(input + list[i]))
			processFolder("" + input + list[i]);
		if(endsWith(list[i], suffix))
			processFile(input, output, list[i]);
	}

	function processFile(input, output, file) {
		print("Processing: " + input + file);
		intfilepath = input + "\\" + file;
		outfilepath = output + "\\" + file;
		open(intfilepath);
	}
	run("Images to Stack", "name=Stack title=[] use");
	selectWindow("Stack");
	{
		saveAs("Tiff", output + "\\" + "Stack");
	}
}