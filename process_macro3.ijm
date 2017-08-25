dir = getDirectory("Choose a Directory");
print("this is dir "+dir);
processFolder(dir);

//macro3, is for writing out measurements
//all the images should be good. Time to write the measures!!

//bigggest problem, the macro doesn't move through all of the images smoothly

function processFolder(input) {
	list = getFileList(input);
	list = Array.sort(list);
	print("this is the list"); // all the SC lists
	Array.print(list);
	for (i = 0; i < list.length; i++) {
		print("on list element "+i);
//if matches CO		
		if(matches(list[i], ".*CO.*")){ // these images should all be 'approvd'. time for 
			
			print("this is an image to process" + list[i]);
			macro3(dir+list[i]);
			print("ran the macro 3 block ");
		}
	}
}

function macro3(biv_image){ //rename -- something like print results
	
	print("this is sc-image "+ biv_image); //biv_image is full path
	open(biv_image);
	T = getTitle;
	selectWindow(T);
	cell_path = getInfo("image.directory");//cell_path is path minus image name
	print("this is cell_path " + cell_path);//
	
	cell_name = File.getName(cell_path);//this returns the last folder, foo1
	print("this should be  "+cell_name);//this is cell name
	file_name = T;
	print("this is T " + T); //this is SC name
	file_name_list = split(T, "_");
	Array.print(file_name_list);// SC index and objectClass
	
	obj_class_list = split(file_name_list[1], ".");
	ObjClass = obj_class_list[0];//ObjClass
	print(ObjClass);

	selectWindow(T);
	run("Duplicate...", "title=duplicate duplicate");
	//selectWindow(T);
	
	run("Stack to Images");
	selectImage(2);
	redImage = getTitle();//this is not the same as renaming the image?
	selectImage(3);
	greenImage = getTitle();
	selectImage(4);
	blueImage = getTitle();
	imageCalculator("and", greenImage, redImage);
	setAutoThreshold("Shanbhag dark");
	setOption("BlackBackground", true);
	fociChannel = getTitle();
	
	print("channels seperated");

//First channel, blue channel. Segment and add centromeres to RoiManager.
	selectWindow(blueImage);
	setAutoThreshold("Minimum dark");
	run("Convert to Mask");
	run("Despeckle");
	run("Dilate");
	run("Analyze Particles...", "  show=Nothing exclude add");//add parameters
	IJ.redirectErrorMessages()
	wait(500);

	for(i=0;i<roiManager("count");i++){
		roiManager("select",i);
		cIndex = i+1;
		roiManager("Rename", roiManager("index") + "_centromere "+ cIndex);
		roiManager("update");
		//roiManager("select",i);
		}
	var centromereCount = roiManager("count");
	var blobCount = 0;
	selectWindow(greenImage);
	setAutoThreshold("Minimum dark");// this might be the automatic version
//waitForUser("Step 1, Thresholding", "Adjust threshold for foci signal then press OK" );
	run("Analyze Particles...", "size=4-Infinity exclude add");//size=6 also works well
//relook at size of green foci
	var fociCount = 0;
	for(f=centromereCount;f<roiManager("count");f++) {
		fociCount++;
		roiManager("select", f);
		roiManager("Rename", roiManager("index")+ "foci "+ fociCount);
		roiManager("update");
	}//end green channel processing
	
	print("foci added");

	setBatchMode("hide"); // hide the UI for this computation to avoid unnecessary overhead
	selectWindow(redImage);
	setAutoThreshold("Otsu dark");
	run("Convert to Mask");
	run("Despeckle");
	setBatchMode("hide");
	run("Invert LUT");//inverting LUT required for correct RD performance -- remove popup
	run("Ridge Detection", "line_width=2 high_contrast=255 low_contrast=240 extend_line show_junction_points show_ids displayresults add_to_manager method_for_overlap_resolution=SLOPE sigma=1.2 lower_threshold=16.83 upper_threshold=40");

	var SC_index = 0;
	var scCount = 0;
	JPcount = 0;

	for(o=centromereCount;o<roiManager("count");o++){ //this count will change	
		roiManager("select",o);
		print("selected o "+ o + " max count is "+roiManager("count")-1);
		if(startsWith(Roi.getName(), "C")){			
			roiManager("Rename", roiManager("index") + "SC ");
			print("SC added");
			SC_index = o;
			scCount++;
			}
		if(startsWith(Roi.getName(), "JP-")) { 			//if JP found, flag image as having 2 blobjects
			print("JP deleted");
			roiManager("delete");
			o--;
			}//if there is a JP, that might be a sign of mulitple SCs	
		}//clean up RD
	print("scCount is "+scCount);
	print("SC index is "+ SC_index);
//	roiManager("deselect");


//if there are multiple SC
	if(scCount > 1){
		print("more than one sc counted!!");//the SCINDEX will have to be changed
		sc_lengths = newArray();
		for(k = centromereCount+fociCount; k <roiManager("count"); k++){
			print("this is the q "+ k);
			roiManager("select", k);
			run("Measure");
			Length = getResult('Length', nResults-1 );
			print("this is the length of measuresd SC " + Length);
			sc_lengths = Array.concat(sc_lengths, Length);
			}
		rnk_scLength = Array.rankPositions(sc_lengths);
		print("this is the sc length array");
		Array.print(sc_lengths);	
		print("this is the rank of sc length array");
		Array.print(rnk_scLength);
		print("this is the first ranked sc " +rnk_scLength[0] +" this is the SC value " +sc_lengths[rnk_scLength[0]]);//I think I need to add old rois
		print("this is the last ranked sc " +rnk_scLength[rnk_scLength.length-1] + " this is the SC value " +sc_lengths[rnk_scLength[rnk_scLength.length-1]]);
		print("translate rnak indx to roi index " +  ( rnk_scLength[ rnk_scLength.length-1 ] + centromereCount+fociCount) );
		indx_longst_sc = ( rnk_scLength[ rnk_scLength.length-1 ] + centromereCount+fociCount); //4
//last is longest//delete everything but longest
//the rankd sc -- are from the sc array
		delete_sc = Array.slice(rnk_scLength, 0, rnk_scLength.length-1);
//the delete_sc also has to be adjusted....
		for(y=0; y < delete_sc.length;y++){
			delete_sc[y] = delete_sc[y]+centromereCount+fociCount;
		}
		print("this is the adjusted array of sc to delete");
		Array.print(delete_sc);
		roiManager("Select", delete_sc);
		roiManager("delete");
		//roiManager("update");
		print("extra SC deleteed");
		roiManager("Select", roiManager("count")-1);
		roiManager("Rename", roiManager("index") + "SC ");//rename longest
		print("renamed longest SC!!!");
		roiManager("update");
		}
	print("sc processed");
	SC_index=roiManager("count")-1;
	print("SC index defined as " + SC_index);

//MAKE BLOB LOOP (sometimes blobs arent made)
//check if there are mulitple centromeres -- if there are mulitple centromeres...
	print("centromere count "+centromereCount);
	if(centromereCount == 1){
		for(cen=0; cen < roiManager("count");cen++){
			roiManager("Select",cen);
		if(matches(Roi.getName(), ".*centromere.*")) {
			roiManager("Select",cen);
			print("making blob");
			makeBlob(cen); //some of the reverse property is being set here
			roiManager("update");
				}
			}
	} else {
	print("there are mulitple centromeres ... this could mess up blob making");
	}
	print("this is blob count " + blobCount);
		
	print("starting SC measures");
	roiManager("Select", SC_index);
	run("Measure");
	SC_length = getResult('Length', nResults-1 ); //results window names rows, but ndex is 0, clear results before this?
	
	measure_array = newArray(cell_name, file_name, ObjClass, SC_length);
	print("measure array made "+ measure_array.length + " long.");
	Array.print(measure_array);
//adding foci to result array in loop.
	foci_array = newArray(); // make a foci specific array (incedes, x coords, y coords )
//fill the above array with foci indeces
	
	for(i=0; i < roiManager("count");i++){
		roiManager("Select",i);
		if(matches(Roi.getName(), ".*foci.*")) {
			foci_array = Array.concat(foci_array, i);
			}
		}
	print("foci array made, this might be useful later ");

	Array.print(foci_array);// 1,2,3

//now that foci array is made, check that all of the foci are within the one blobject
	final_foci_array = newArray();
	for(ff=0; ff < foci_array.length; ff++ ){ //this should be the array
		print("testing if blobject roi contains foci roi ");
		roiManager("Select", foci_array[ff]); //
		print("the roi selected is "+ Roi.getName() );
		Roi.getBounds(ff_x, ff_y, ff_width, ff_height);
		print("these are the coords "+ ff_x + " " +ff_y);
		roiManager("deselect");
		roiManager("Select", roiManager("count")-1 );//this should be the same for the whole loop
		print("the 'blob' selected is " + Roi.getName() );
		if(Roi.contains(ff_x, ff_y)){
			print("blobject contains foci "+foci_array[ff]);
			final_foci_array = Array.concat(final_foci_array, foci_array[ff]);
		} 
		else {
			print("blobject DOESNT contain foci "+foci_array[ff] + "  " + ff_x +" " + ff_y);
//change name in roiManager, adjust foci array
		}
	}
	print("this final array should only be foci in blobject");
	Array.print(final_foci_array);
//delete or do something for non contained foci

//IFD loop //the number of foci can be infered from the length of measure array
//or use foci specific array ...foci_array = newArray();
	IFD = "NA";
	if(final_foci_array.length <=1){
		print("IFD will be empty");
	}
	if(final_foci_array.length == 2){
//make unique vars for each foci
		roiManager("select", SC_index);
		getSelectionCoordinates(SCx, SCy);
		roiManager("Select", SC_index);
		rev_stat = Roi.getProperty("reverse");//reverse status might not be being set.
		print("this is rev stat before making result array "+ rev_stat);
		if(rev_stat=="yes"){ //i think this is working, even though SplineMeasure has loops for accounting for reverse
			SCx = Array.reverse(SCx); //if there are more foci, this will reverse twice
			SCy = Array.reverse(SCy); //only run the reverse on first foci
			}
//X coord, Y coord, sc index, roi index
		F1_WAout = walk_array(final_foci_array[0], SCx, SCy);//walk-array to get index	
		print("this is the 1WA arrays"); //these arrays are empty
		Array.print(F1_WAout);
		
		F2_WAout = walk_array(final_foci_array[1], SCx, SCy);
		print("this is the 2WA arrays");
		Array.print(F2_WAout);
		
		IFD = splineMeasure(SC_index, F1_WAout[2], F2_WAout[2]);//these indeces were out of range for 11
		}
	measure_array = Array.concat(measure_array, IFD);

	for(f=1; f < SC_index; f++) { //loop through the foci rois -- if there are muliutple SC's this will mess up
		print("adding the foci positions to the measure ");
		roiManager("select", SC_index);
//still need to check reverse array
		getSelectionCoordinates(SCx, SCy);//
		roiManager("Select", SC_index);
		rev_stat = Roi.getProperty("reverse");
		print("this is rev stat before making result array "+ rev_stat);
		if(rev_stat=="yes"){ //i think this is working, even though SplineMeasure has loops for accounting for reverse
			SCx = Array.reverse(SCx); //if there are more foci, this will reverse twice
			SCy = Array.reverse(SCy); //only run the reverse on first foci
	}
	WAout = walk_array(f, SCx, SCy);//walk-array to get index	
	print("this is the walk array array");
	Array.print(WAout); //reverse array didn't apply
//define the SC index ... will this always be last roi? second to last roi?
	foci_pos = splineMeasure(SC_index, 0, WAout[2]); //f needs to be the index that the foci is in
//concate foci info to array
	measure_array = Array.concat(measure_array, foci_pos);
	print("this is the new measure array ");
	Array.print(measure_array);
}//foci loop
	measure_array[0] = cell_name;
	print("this is the measure array before it's printed to file ");

	Array.print(measure_array);
//create the text file, //set the correct path -- for within the current dir 
//f = File.open("");

	path = dir + "result.txt";
//put the results into an array, then print
//printing array values to a text value is sensitive

	for(re=0; re < measure_array.length; re++){ //this should loop through the result array	
		//print("first array val " + re);
		val = measure_array[re];//strangely calling an array[indx], will include a \n 
		//print(f, val + " \t" + "test" + " \t" ); // still having the problem with, printing in new lines, not tabs
		File.append( measure_array[re] + "\t", path);
		}//printing array
	File.append("\n ", path);
	close("*");
	
	roiManager("save", cell_path+file_name_list[0]+ObjClass+"_rois.zip");
	
	roiManager("reset");
//reset results
	close("Results");
	}//macro3 function/loop


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

//I think the reverse status is causing the array to be reversed twice
function splineMeasure(sc, point1, point2){//make sure that 0 is first
	print("entering spline measure"); 
	roiManager("Select", sc);
	if(matches(Roi.getName(), ".*SC.*")) { // make sure the name is captitalized
		Roi.getSplineAnchors(Scpx, Scpy);//getting spline anchors of the SC
		roiManager("Select", sc);
		rev_status = Roi.getProperty("reverse");
		print("this is rev stat in splineM function "+ rev_status);// not reverse status
		if(rev_status == "yes"){ //this should be evaluating correctly
			print("within splineMeasure and rev status is 'yes' ");//this isn't printing
			print("the first points are is "+point1 +" and "+point2);
			Scpx = Array.reverse(Scpx); 
			Scpy = Array.reverse(Scpy);
		}
		NwAx = newArray(Scpx.length);
		NwAy = newArray(Scpx.length);//what is this used for?
		scx_trimd = newArray(0);
		scy_trimd = newArray(0);
		print("the full length is "+ Scpx.length);
		if( abs( parseFloat(point1)) > abs( parseFloat(point2)) ){ //if I get the SCarray reverse and foci order correct, this loop won't be needed.
			print("points are wrong order");
			scx_trimd = Array.slice(Scpx, point2,point1);//use slice to create splines between p1 and p2	
			scy_trimd = Array.slice(Scpy, point2,point1);
			Roi.setPolylineSplineAnchors(scx_trimd, scy_trimd);//the arry thing needs to be added as a spline
			roiManager("add");//splines must be added to RoiManager to measure 
			roiManager("Select", roiManager("Count")-1);
			roiManager("measure");
			RLength = getResult('Length', nResults-1);
			print("the results length " + RLength);
//			roiManager("delete");//commont out the delete and select new to remove the newly added apliens
//			roiManager("Select", 0);
			print("result length "+ RLength);
			return RLength;//i think the return Rlength should be at end of each loop
		}
		if( abs( parseFloat(point1)) < abs(parseFloat(point2)) ){
			print("points are correct order");
			scx_trimd = Array.slice(Scpx, point1, point2);//use slice to create splines between p1 and p2	
			scy_trimd = Array.slice(Scpy, point1, point2);
//what is this spliced array length? it keeps throwing errors...
			print("spline length " + scx_trimd.length);//this is the 
//choose between end centromere/middle of centromere or begining of SC
			Roi.setPolylineSplineAnchors(scx_trimd, scy_trimd);//the arry thing needs to be added as a spline
			roiManager("add");
			roiManager("Select", roiManager("Count")-1);
			roiManager("measure");
			RLength = getResult('Length', nResults-1);
//			roiManager("delete");  // comment these out when macro starts behaving
//			roiManager("Select", 0);
			print("resulting spline length "+ RLength);//
//print("second trim "+ scy_trimd.length);
			return RLength;
		}
	}//sc name
} // end of function

function walk_array(roi, array_x, array_y){//arg wtf is the difference between info and new_info
	roiManager("Select", roi);
	new_info = newArray(roi); 
	for(k=0; k < array_x.length; k++){ 		
		if(Roi.contains(array_x[k], array_y[k])){			
			new_info = newArray(array_x[k], array_y[k], k, roi);//
			x_pos = array_x[k];
			y_pos = array_y[k];
			}//these values should update to the last values
		}
		//I don't know what new info-data needs to be added. just use the new_info made in loop above.
//		info = newArray(); // array indx, xposition, y position
		info = new_info;// xposition, y position, --new_info; pos x, pos y, arrayINDX, roiINDX
		return info;
}

function isNear(x1,y1,x2,y2, min_distance) {
    if( sqrt((x1-x2)*(x1-x2) + (y1-y2)*(y1-y2)) < min_distance) {
        return true;
    } 
return false;
}//end isNear funciton

	