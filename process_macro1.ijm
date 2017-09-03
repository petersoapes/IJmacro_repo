//input = "C:\\Users\\alpeterson7\\Desktop\\macro material\\foofoo\\";
input = getDirectory("Choose a Directory");

//file needs to be open .. maybe I need to count all of them
//list = getFileList(input);
//print("this is the list");
//Array.print(list);

//open(input + list[0]);//this will always open the frist one
//setBatchMode("hide");

processFolder(input); //process folder can be called without 

// function to scan folders/subfolders/files to find files with correct suffix
function processFolder(input) {
	list = getFileList(input);
	list = Array.sort(list);
	print("this is the list");
	Array.print(list);
	for (i = 0; i < list.length; i++) {
		print("on list element "+i);
		//if(File.isDirectory(input + File.separator + list[i]))
			//processFolder(input + File.separator + list[i]);
		if(matches(list[i], ".*.tif.*")){
			print("this is an image " + list[i]);
			//make a folder -- and save 			
			CropSC(list[i]);
		}
	}
}	//File.makeDirectory(dirCropOutput);


function CropSC(image){ //rename to something more discriptive, CropSCbiv
//mkdir	
	image_name = substring(image,  0, lengthOf(image)-4);
	File.makeDirectory(input+image_name);
	open(input + image);

	print("trying to open image " + image);
	selectImage(1);
	orig = getTitle();
	print("selected image 1 " +getTitle());
	run("RGB Color");//this command is needed for BD images
	
	run("Set Scale...", "distance=0 known=0 global");
//this image is all red...	

	
	
	saveAs("Tiff", input+image_name +File.separator +image_name+".tiff");
	print("this is  input "+input);
	
	print("trying to open image " + image);
	selectImage(1);
	orig = getTitle();
	print("selected image 1 " +getTitle());
	//run("Duplicate...", "title=duplicate duplicate");

//	selectImage(2);
	run("Stack to Images"); // think this is throwing stack to binary error (why is this here)?
	
	selectImage(2);
	print("selected image 2 " +getTitle());
	redImage = getTitle();
	selectImage(3);
	green = getTitle();
	print("selected image 3 " +getTitle());//not returning
	selectImage(4);
	blue = getTitle();
	print("selected image 4 " +getTitle());	
	selectImage(green);
	close();
	selectImage(blue);
	close();

	print("selecting red channel");
	selectWindow(redImage);
	print("first red threshold");
	setAutoThreshold("Default dark");//for BD data
	run("Convert to Mask");
	run("Dilate"); // i think dilate requires binary
	run("Dilate");
	run("Dilate");//make the red shape larger so that croping gets extra
	run("Despeckle");
	run("Convert to Mask");	     
	run("Analyze Particles...", "  show=Nothing exclude add");
	print(roiManager("count") + " SC particles added");

	var scCount = 0;
	for(r=0;  r < roiManager("count"); r++ ) {
		selectImage(orig);
		run("Duplicate...", "title=duplicate duplicate");//new images might need to be duplicated each time
		selectWindow("duplicate");
		dup_loop = getTitle();
		roiManager("select",r);
		scCount++;
		roiManager("Rename", roiManager("index") + "_SC");
		roiManager("update");
		print("entering loop to crop SCs");
		run("Crop");
//make composite.don't make composite, I think that it messes up things in macro 2
//		run("Make Composite");
		print("preparing to save "+ input+ image_name + File.separator + Roi.getName()+".tiff");
  		saveAs("Tiff", input+image_name+File.separator +Roi.getName()+".tiff");
  		close();
		}
	roiManager("save", input+image_name+File.separator+image_name+"_rois.zip");
	selectImage(orig);
	close();
//	selectImage(2);
//	close();
	selectImage(redImage);
	close();
	roiManager("reset");
	//close();
}