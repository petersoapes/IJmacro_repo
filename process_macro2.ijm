//choose directory of new dir
setBatchMode("hide");
dir = getDirectory("Choose a Directory");
print("this is dir "+dir);
processFolder(dir);

//macro2 should act on croped blob images made by macro1
//aspects of image, independant of blobjects,  (just on image sizes)
//macro2 is meant to segregate obvertly bad SC images to a discard folder, and rename the 'good' images
//
function processFolder(input) {
	list = getFileList(input);
	list = Array.sort(list);
	print("this is the list"); // all the SC lists
	Array.print(list);
	for (i = 0; i < list.length; i++) {
		print("on list element "+i);	
		if(endsWith(list[i], "SC.tiff")){
			print("this is an image " + list[i]);
			print("opening file");
			open(dir+list[i]);
			width = getWidth;
			height = getHeight;
			close();
			print("this is wdth "+width);	
//add the size level
		if(width * height < 500){	
			print("too small, should be deleted");
			discard = "discard";
			dirDiscard = dir+File.separator+"discard";
			File.makeDirectory(dirDiscard);	
			open(dir+list[i]);
			selectWindow(list[i]);//doesn't 
			saveAs("Tiff", dirDiscard + File.separator+list[i]);			
			print("deleting old file in centromere loop ");
			File.delete(dir+list[i]);
			close();
		}		
		if(width * height > 500  && (endsWith(list[i], "SC.tiff") ) ){
			print("going into blobject loop");
			//blobject(list[i]);
			blobject(dir+list[i]);		
			roiManager("reset");
			close("*");//if windows are already closed, this will throw error
			}
		}//if name matches SC
	}
	roiManager("reset");
//	close();
} // if(endsWith(getTitle(), "") && counter < 10 ){

function blobject(SC_image){ // macro2, make-count blobject
//	run("Set Scale...", "distance=0 known=0 global");
	//open(dir +File.separator+ SC_image);//this isn't working
	open(SC_image);
	print("this is sc-image "+SC_image);
	T = getTitle;
	filename = getInfo("image.filename");
	filename_indx = substring(filename, 0, indexOf(filename, '_'));
	
	selectWindow(T);
	run("Duplicate...", "title=duplicate duplicate");
	selectWindow(T);
	
	run("Stack to Images");	
	selectImage(2);
	redImage = getTitle();//for some reason, some images a chunck of red channel is deleted
	selectImage(3);
	greenImage = getTitle();
	selectImage(4);
	blueImage = getTitle();
	imageCalculator("and", greenImage, redImage);
	setAutoThreshold("Shanbhag dark");
	setOption("BlackBackground", true);
	fociChannel = getTitle();
	print("channels seperated");

	selectWindow(blueImage);//if too much blue signal -- skip image // or adjust threshold level?
	setAutoThreshold("Default dark");//some 
	run("Convert to Mask");
	run("Despeckle");
	run("Dilate");
	run("Analyze Particles...", "  show=Nothing exclude add");
	IJ.redirectErrorMessages()
	wait(500);
//not sure if the counter is a good 
	for(i=0;i<roiManager("count");i++){
		roiManager("select",i);
		cIndex = i+1;
		roiManager("Rename", roiManager("index") + "_centromere "+ cIndex);
		roiManager("update");
		roiManager("select",i);
	}
	var centromereCount = roiManager("count");
	var blobCount = 0;
//move the centromere test to end -- otherwise, macro breaks cause the other channels are gone
	
	//Third channel, Red channel. Running Ridge detection (RD) to 'detangle' skeleton. Adding 'ridges' to RoiManger
//	setBatchMode("hide"); // hide the UI for this computation to avoid unnecessary overhead
	selectWindow(redImage);
	setAutoThreshold("Otsu dark");
	run("Convert to Mask");
	run("Despeckle");
	run("Invert LUT");//inverting LUT required for correct RD performance -- remove popup
	run("Ridge Detection", "line_width=2 high_contrast=255 low_contrast=240 extend_line show_junction_points show_ids displayresults add_to_manager method_for_overlap_resolution=SLOPE sigma=1.2 lower_threshold=16.83 upper_threshold=40");
//sigma 1.2, lower 16.83, upper 40

	var scCount = 0;
	var SC_index = 0;
	var JPcount = 0;
	for(o=centromereCount; o<roiManager("count");o++){
		roiManager("select",o);
		if (startsWith(Roi.getName(), "C")) {
			roiManager("Rename", roiManager("index") + "SC ");
			SC_index = o;
			scCount++;
			}
		if (startsWith(Roi.getName(), "JP-")) {
			roiManager("delete");
			o--;
		}//if there is a JP, that might be a sign of mulitple SCs
}//clean up RD
	print("sc processed");
	print("this is the SC index " + SC_index);
	
	selectWindow(fociChannel);//change to foci channel
	setAutoThreshold("Minimum dark");// this might be the automatic version
	run("Analyze Particles...", "size=4-Infinity exclude add");//size=6 also works well

	var fociCount = 0;
	for(f=centromereCount+scCount;f<roiManager("count");f++) {
		fociCount++;
		roiManager("select", f);
		roiManager("Rename", roiManager("index")+ "foci_"+ fociCount);
		roiManager("update");
	}//end green channel processing
	print("foci added to manager");

//MAKE BLOB
	for(cen=0; cen < roiManager("count");cen++){
		roiManager("Select",cen);
		if(matches(Roi.getName(), ".*centromere.*")) {
			roiManager("Select",cen);
			makeBlob(cen);
//			Roi.getCoordinates(centx, centy);
			roiManager("update");
			//blobCount++; //redundant
			}
		}// fociCount+1 should be sc
	var ObjClass = "_CO" + fociCount;
	print("objclass " + ObjClass);
	print("this is blobcount "+blobCount);

//what do I do after blob is made? -- rename as blobCount
//discard or keep
	if(fociCount <= 6){ // foci count is proxy of objclass
		print("number of foci acceptable");
		mainTitle=T; //why?
		selectWindow("duplicate");
		print("getTitle result "+ mainTitle);
		mainTitle_path = substring(mainTitle,  0, indexOf(mainTitle, '.tif'));//remove tiff
		print("going to rename "+ SC_image+" to "+ filename_indx + ObjClass); // don't use i
//the correct image is not being saved	
		saveAs("Tiff", input + filename_indx + ObjClass +".tiff");//change to the object variable
		print("deleting old file in good blojct loop " + SC_image);
		File.delete(SC_image);//this made it work
	}
	if(fociCount >= 6){  /// this high ObjClass biv might be a XY -- maybe 'discard' thi
		print("too many foci, move to a discard folder");
		discard = "discard";
		dirDiscard = input+File.separator+"discard";
		File.makeDirectory(dirDiscard); //are these making new discard dirs
		
		selectWindow("duplicate");
		saveAs("Tiff", dirDiscard + File.separator+filename_indx + ObjClass +".tiff");
		File.delete(SC_image);
//had problems saving these to discard
	}//foci count more than 6
	if(scCount > 1){
		print("too many sc pieces, move to a discard folder");
		discard = "discard";
		dirDiscard = input+File.separator+"discard";
		File.makeDirectory(dirDiscard);
		selectWindow("duplicate");//
		saveAs("Tiff", dirDiscard + File.separator+T);//the file is saved.
		
		print("deleting old file in excess sc loop ");
		File.delete(SC_image);
		counter=15; // break out of loop -- i don't think counter in function works
		roiManager("reset");
		//close("*");//try to close all the files
 		wait(500);

		}
	if(centromereCount > 1){
		print("too many centromeres, move to a discard folder");
		discard = "discard";
		dirDiscard = input+File.separator+"discard";
		File.makeDirectory(dirDiscard);
		selectWindow("duplicate");//
		saveAs("Tiff", dirDiscard + File.separator+T);//the file is saved.
		
		print("deleting old file in centromere loop ");
		File.delete(SC_image);
		counter=15; // break out of loop -- i don't think counter in function works
		roiManager("reset");
		//close("*");//try to close all the files
 		wait(500);		
		}//when everything is deleted here ... then tries to process red image.. fatal error.
	
	roiManager("reset");
	print("about to close all windows ");
	close("*");//try to close all the files.  close all wild card
 	wait(500);
 }//blobject function


function makeBlob(cen){
	print("entering makeblob. cen is "+ cen);
	roiManager("Select", cen);
	
//	Roi.setProperty("reverse", "no");
	print("getting centromere coordinates"); // maybe just switch to roi is in function
	Roi.getCoordinates(centx, centy);
	print("a centromere coord "+ centx[2] + " this long" + centx.length);
	roiManager("deselect");

	roiManager("Select", SC_index);//just select SC instead of looping through all
	print("selecting noncen/SC " + SC_index);//1
	Roi.getCoordinates(SCx, SCy);
	print("getting SC coordinates");
	print("a SC coord "+ SCx[2]);
	
	roiManager("deselect");
	reverse_status="no";
	paired=false;
	
	for(k=0; k < SCx.length && !paired;  k++){  //k pixels in centromere //
		print("in SC pixel loop. paired is " + paired);
		roiManager("deselect");
		roiManager("Select", cen);
		//print("test if SC is in centromere");
//if <maybe this should be if cent contains sc		
		if(Roi.contains(SCx[k], SCy[k])) { // this test is for if SC co-occurs with any centr
 			print(" sc contains cent pixel");
 			roiManager("deselect");
 			roiManager("Select", cen);

 			//I got the blob making to fix itself one time
			if(Roi.contains(SCx[1], SCy[1])){  //change this to [5], since some ends of SC extend past centromere
				print(cen + " " + SC_index + "SC array starts at centromere");
				Roi.setProperty("reverse", "no");//this is set for centromeres
				reverse_status = "no";
				//paired=true;
				roiManager("update");//update required to set property in play
				
				}
			print("checking reverse loop");
			if(Roi.contains(SCx[SCx.length-1], SCy[SCy.length-1])) { //if cent contains end of SC
				print(cen + " " + SC_index + "centromere is at end of array. Reversing Arrays");
				SCx = Array.reverse(SCx);
				SCy = Array.reverse(SCy);
				print("reverse loop had hit");
				reverse_status = "yes";
				Roi.setProperty("reverse", "yes");//set for centromeres
				//paired=true;
				roiManager("update");
				}
		
			run("Measure");
			roiManager("update");
		 	blob_parts = Array.concat(cen, SC_index);//noncen = SC
		 	Array.print(blob_parts);
		 	//roiManager("Select", blob_parts);//roiManager("Select", newArray(cen, noncen)) doesn't work
		   	roiManager("Select", Array.concat(cen, SC_index) );
		   		
		   	roiManager("Combine");
			roiManager("Add");//new object
			roiManager("deselect");
			roiManager("Select", roiManager("count")-1); //select the new roi
			roiManager("Rename", roiManager("index")+"_blob");
			print("blob made");
			print("last part of setting blob properties");
			roiManager("update");
			blobCount++;
			paired=true;
			}
		//	print("SC roi didn't overlap with anything");
		print("paired is "+ paired);		//if Roi contains
		}//k pixels in centromere
						
	}//end function