#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.

//Some useful constants.
Function mol()
	return 6.02214086e14
end
Function mu_0()
	return pi*4e7
end
Function eps_0()
	return 8.854187817e-12
end
Function m_e()
	return 9.10938356e-31
end
Function m_p()
	return 1.6726219e-27
end
Function m_n()
	return 1.674927471e-27
end
Function q_e()
	return 1.60217662e-19
end
Function v_c()
	return 299792458
end
Function Plank()
	return 6.62607004e-34
end
Function Boltz()
	return 1.380649e-23
end

//GUI for deleting unused waves.
Function cleanWavesGUI()
	String parentDirectory = strvarordefault("root:MatthewGlobals:gparentDirectory","All")
	Prompt parentDirectory, "From root, cwd, cwd+subdirs?", popup "root;cwd;cwd+"
	doPrompt "Delete all unused waves?",parentDirectory
	
	If(v_flag)
		return -1
	endif
	
	//Checking for MatthewGlobals folder
	If(DataFolderExists("root:MatthewGlobals") == 0)
		NewDataFolder root:MatthewGlobals
	endif
	
	String/g root:MatthewGlobals:gparentDirectory = parentDirectory
	
	If(!cmpstr(parentDirectory,"root",2))
		cleanWaves(root:)
	elseif(!cmpstr(parentDirectory,"cwd+subdirs?",2))
		cleanWaves(GetDataFolderDFR())
	else
		killWaves/a/z //Clean up current directory only.
	endif	
	
	//Delete DFRList waves
	variable iter1=0
	Do	
		If(waveexists($("root:MatthewGlobals:subDFRefList"+num2str(iter1))))
			killwaves $("root:MatthewGlobals:subDFRefList"+num2str(iter1))
			iter1+=1
		endif
	While(waveexists($("root:MatthewGlobals:subDFRefList"+num2str(iter1))))
end

//Recursive clean up of passed directory and any subfolders.
Function cleanWaves(parentDirectory)
	dfref parentDirectory
	cd parentDirectory

	//Count subfolders.
	Variable subDFCount, iter1, iter2
	String DFListName = "root:MatthewGlobals:subDFRefList"
	subDFCount = CountObjectsDFR(parentDirectory,4)

	//Enter recursion if subfolder count > 0.
	if(subDFCount > 0)
		//Find unused wave name for DFList
		iter2 = 0
		Do	
			DFListName = "root:MatthewGlobals:subDFRefList"+num2str(iter2)
			If(waveexists($DFListName))
				iter2 += 1
			endif
		While(waveexists($DFListName))
		
		//Make a dfref wave of all subdirectories.
		make/df/n=(subDFCount) $DFListName
		wave/df subDFRefList = $DFListName
		String strList=RemoveEnding(TrimString(replaceString("FOLDERS:",DataFolderDir(1),"")),";")
		for(iter1=0;iter1<subDFCount;iter1++)
			subDFRefList[iter1] = parentDirectory:$ListToTextWave(strList,",")[iter1]
		endfor

		//Recursive iterate through subdirectories cleaning up unused waves.
		for(iter1=0;iter1<subDFCount;iter1++)
			//Ignore MatthewGlobals and Packages directories.
			if(DataFolderRefsEqual(subDFRefList[iter1],root:MatthewGlobals)==0 && DataFolderRefsEqual(subDFRefList[iter1],root:Packages)==0)
				print "Cleaning "+GetDataFolder(1) //History printout of progress.
				killWaves/a/z
				cleanWaves(subDFRefList[iter1]) //Recursive call to subfolder.
			endif
		endfor
	else
		killWaves/a/z //Base case, clean up current directory only.
	endif
end

Function colourPlotGUI()
	String nameBase = strvarordefault("root:MatthewGlobals:gCSPnameBase", "f")
	String append0s = strvarordefault("root:MatthewGlobals:gappend0s", "Yes")
	Variable index0 = numvarordefault("root:MatthewGlobals:gindex0", 0)
	Variable indexF = numvarordefault("root:MatthewGlobals:gindexF", 10)
	Variable scaleX0 = numvarordefault("root:MatthewGlobals:gscaleX0", 1)
	Variable scaleXF = numvarordefault("root:MatthewGlobals:gscaleXF", 10)
	Variable scaleY0 = numvarordefault("root:MatthewGlobals:gscaleY0", 1)
	Variable scaleYF = numvarordefault("root:MatthewGlobals:gscaleYF", 10)
	String transposeXY = strvarordefault("root:MatthewGlobals:gtransposeXY", "No")
	String unitsY = strvarordefault("root:MatthewGlobals:gunitsY", "Tesla")
	Prompt nameBase, "Base Name"
	prompt append0s, "Do indices have 0s preappended?", popup "Yes;No"
	Prompt index0, "First Index"
	Prompt indexF, "Last Index"
	Prompt scaleX0, "Scaling: X Initial"
	Prompt scaleY0, "Scaling: Y Initial"
	Prompt scaleXF, "Scaling: X Final"
	Prompt scaleYF, "Scaling: Y Final"
	Prompt transposeXY, "Transpose X and Y axis", popup("Yes;No")
	Prompt unitsY, "Units of Y", popup("Volts;GHz;Tesla;1/Tesla;ν;μS")
	DoPrompt "Colour Scale Plot", nameBase, append0s, index0, indexF, scaleX0, scaleY0, scaleXF, scaleYF, transposeXY, unitsY
	
	If(v_flag)
		return -1
	endif

	String/g root:MatthewGlobals:gCSPnameBase = nameBase
	String/g root:MatthewGlobals:gappend0s = append0s
	Variable/g root:MatthewGlobals:gindex0 = index0
	Variable/g root:MatthewGlobals:gindexF = indexF
	Variable/g root:MatthewGlobals:gscaleX0 = scaleX0
	Variable/g root:MatthewGlobals:gscaleXF = scaleXF
	String/g root:MatthewGlobals:gtransposeXY = transposeXY
	Variable/g root:MatthewGlobals:gscaleY0 = scaleY0
	Variable/g root:MatthewGlobals:gscaleYF = scaleYF
	String/g root:MatthewGlobals:gunitsY = unitsY
		
	colourPlotGUI2()
end

Function colourPlotGUI2()
	String isCmplx=strvarordefault("root:MatthewGlobals:gisCmplx", "Yes")
	String cmplxPart = strvarordefault("root:MatthewGlobals:gcmplxPart", "Re")
	Prompt isCmplx, "Wave is Complex?", popup("No;Yes")
	Prompt cmplxPart, "Complex Part", popup("Im;Re")
	DoPrompt "Colour Scale Plot", isCmplx,cmplxPart
	
	If(v_flag)
		return -1
	endif
	
	String/g root:MatthewGlobals:gisCmplx = isCmplx
	String/g root:MatthewGlobals:gcmplxPart = cmplxPart
	
	colourPlot()
end

Function colourPlot()
	svar nameBase = root:MatthewGlobals:gCSPnameBase
	svar append0s = root:MatthewGlobals:gappend0s
	nvar index0 = root:MatthewGlobals:gindex0
	nvar indexF = root:MatthewGlobals:gindexF
	nvar scaleX0 = root:MatthewGlobals:gscaleX0
	nvar scaleXF = root:MatthewGlobals:gscaleXf
	nvar scaleY0 = root:MatthewGlobals:gscaleY0
	nvar scaleYF = root:MatthewGlobals:gscaleYF
	svar transposeXY = root:MatthewGlobals:gtransposeXY
	svar unitsY = root:MatthewGlobals:gunitsY
	svar isCmplx = root:MatthewGlobals:gisCmplx
	svar cmplxPart = root:MatthewGlobals:gcmplxPart
	String unitsX = ""
	String wNameCsp = ""
	String wName = ""
	Variable int1 = 0
	Variable int2 = 0
	Variable zint
	Variable num0s
	String zeros = ""
	Variable ptsX
	Variable ptsY = ABS(indexF-index0) + 1
	String printString
	String cspExists = "False"
	Variable numDigits = 3
	
	//Look for first available name for the csp wave
	Do	
		wNameCsp = nameBase + "M" + num2str(int1)
		If(waveexists($wNameCsp))
			int1 += 1
		else
			cspExists = "True"
		endif
	While(StringMatch(cspExists, "True") != 1)
	
	print "***************************************************"
	//Preappend zeros if needed for finding first wave's values
//	If(cmpstr(append0s, "Yes"))		
//		num0s = numDigits - strlen(num2str(index0))
//		zeros = ""
//		for(zint = 0; zint < num0s; zint+=1)
//			zeros = zeros + "0"
//		endfor
//	endif

	//Get some values from first wave to write to csp
	If(!cmpstr(append0s,"Yes",2))
		wName = nameBase + preAppendZeros(num2str(index0), numDigits=numDigits)
	else
		wName = nameBase + preAppendZeros(num2str(index0), numDigits=0)
	endif
//	wName = nameBase + zeros + num2str(index0)
	ptsX = numpnts($wName)
	unitsX = WaveUnits($wName, 0)
	
	//Make the csp, load the csp wave, and display readout to console
	make/o/n=((ptsX), (ptsY)) $wNameCsp
	wave cspW = $wNameCsp
	printString = "Colour Scale Plot: " + wNameCsp
	print printString
	
	//Loop to create the 2D matrix for the csp
	for(int1 = index0; int1 <= indexF; int1+=1)
	
		//Preappend zeros if needed for loading waves to write
//		If(cmpstr(append0s, "Yes"))
//			num0s = numDigits - strlen(num2str(int1))
//			zeros = ""
//			for(zint = 0; zint < num0s; zint+=1)
//				zeros = zeros + "0"
//			endfor
//		endif
		
		//Set name of to be dumped into column and load it
		If(!cmpstr(append0s, "Yes",2))
			wName = nameBase + preAppendZeros(num2str(int1), numDigits=numDigits)
		else
			wName = nameBase + preAppendZeros(num2str(int1), numDigits=0)
		endif
//		wName = nameBase + zeros + num2str(int1)
		wave usedW = $wName
		
		//Fill a row with a wave
		for(int2 = 0; int2 < ptsX; int2+=1)
			//Checking for Complex Wave
			if(!cmpstr(isCmplx,"No",2))
				cspW[int2][int1-index0] = usedW[int2]	
			elseif(!cmpstr(cmplxPart,"Im",2))
				cspW[int2][int1-index0] = Imag(usedW[int2])
			elseif(!cmpstr(cmplxPart,"Re",2))
				cspW[int2][int1-index0] = Real(usedW[int2])
			endif
		endfor
	endfor
	print "***************************************************"	
	
	//Set the scale of the wave and display it
	Display/W=(60,44,640,519)
	AppendImage $wNameCsp
	ImageStats $wNameCsp
	ModifyImage $wNameCsp ctab={V_max,V_min,RedWhiteBlue,0}
	ModifyGraph mirror=2
//	Setscale/i x scaleX0, scaleXF, unitsX,$wNameCsp
//	Setscale/i y scaleY0, scaleYF, unitsY,$wNameCsp
//	SetAxis bottom scaleX0,scaleXF
	If(cmpstr(unitsY,"1/Tesla") == 0 && StringMatch(transposeXY, "Yes") != 1)
		Execute ("Label left"+" "+"\""+"Tesla\\S-1"+"\"")
		ModifyGraph tickUnit(left)=1
	elseif(cmpstr(unitsY,"1/Tesla") == 0 && StringMatch(transposeXY, "Yes") == 1)
		Execute ("Label bottom"+" "+"\""+"Tesla\\S-1"+"\"")
		ModifyGraph tickUnit(bottom)=1
	endif
	If(StringMatch(transposeXY, "Yes") == 1)
		matrixtranspose $wNameCsp
//		SetAxis bottom scaleY0, scaleYF
		Setscale/i x scaleY0, scaleYF, unitsY,$wNameCsp
		Setscale/i y scaleX0, scaleXF, unitsX,$wNameCsp
	else
		Setscale/i x scaleX0, scaleXF, unitsX,$wNameCsp
		Setscale/i y scaleY0, scaleYF, unitsY,$wNameCsp
	endif

end

//Prompt for Values in GUI
Function fitFillingCSPGUI()
	String nameBase = strvarordefault("gnameBase", "")
	Variable CNP = numvarordefault("gCNP", 0)
	Variable vMin = numvarordefault("gvMin", 0)
	Variable bMin = numvarordefault("gybMin", 0)
	Variable vMax = numvarordefault("gvMax", 10)
	Variable bMax = numvarordefault("gbMax", 10)
	Variable permi = numvarordefault("gpermi", 3)
	Variable dist = numvarordefault("gdist", 35)
	Variable delta = numvarordefault("gdelta", 0.01)
	Prompt nameBase, "Name of CSP"
	Prompt CNP, "Charge Neutral Point"
	Prompt vMin, "V min (Volts)"
	Prompt bMin, "B min (Tesla)"
	Prompt vMax, "V max (Volts)"
	Prompt bMax, "B max (Tesla)"
	Prompt permi, "Relative Permittivity"
	Prompt dist, "Distance from Gate (nm)"
	Prompt delta, "Error from Nue"
	DoPrompt "Fit Filling Factor to CSP",nameBase,CNP,vMin,bMin,vMax,bMax,permi,dist,delta
	
	If(v_flag)
		return -1
	endif
	
	String/g gnameBase = nameBase
	Variable/g gCNP = CNP
	Variable/g gvMin = vMin
	Variable/g gbMin = bMin
	Variable/g gvMax = vMax
	Variable/g gbMax = bMax
	Variable/g gpermi = permi
	Variable/g gdist = dist
	Variable/g gdelta = delta
	
	fitFillingCSP()
	
end

//Function for Creating the Image
//Should duplicate image and make matrix elements that correspond to fillings be black
//No idea how much of it works
Function fitFillingCSP()
	svar namebase = root:gnamebase
	nvar CNP = root:gCNP
	nvar vMin = root:gvMin
	nvar bMin = root:gbMin
	nvar vMax = root:gvMax
	nvar bMax = root:gbMax
	nvar permi = root:gpermi
	nvar dist = root:gdist
	nvar delta = root:gdelta
	Variable c = 2.28599e-7*permi/(1e-9*dist) //h*epsilon0*epsilon/(d*e^2)
	Variable intV //Iterator 1
	Variable intB //Iterator 2
	Variable absNue
	Variable vDim = 2000
	Variable bDim = vDim
	Variable vOffset
	Variable vDelta
	Variable Vi
	Variable bOffset
	Variable bDelta
	Variable Bj
	Variable lVMin = vMin
	Variable lVMax = vMax
	String printString

	//Create the Image File and Set Scale
	String nueName = namebase + "nue"	
	make/o/n=(vDim,bDim) $nueName
	SetScale/i x vMin,vMax,"Volts",$nueName
	SetScale/i y bMin,bMax,"Tesla",$nueName
	
	//Load the New Image Wave
	wave nueW = root:$nueName

	//Set a Few Constants for Math
	vOffset = DimOffset(nueW,0)
	vDelta = DimDelta(nueW,0)
	bOffset = DimOffset(nueW,1)
	bDelta = DimDelta(nueW,1)
	
	//Fill Image Table Values
	for(intV = 0; intV < vDim; intV+=1)
		for(intB = 0; intB < bDim; intB+=1)
			//GET B AND V VALUES
			Vi = vOffset+intV*vDelta-CNP
			Bj = bOffset+intB*bDelta
			//Calculate |nue|
			absNue = c*Abs(Vi/Bj)
			//Check if |nue| is Within Delta of an Integer
			if((absNue - floor(absNue)) <= delta)
				nueW[intV][intB] = 5
			else
				nueW[intV][intB] = 0
			endif
		endfor
	endfor
	
	//Set Colours
	ModifyImage $nueName ctab= {1,2,BlueBlackRed,0}
	ModifyImage $nueName minRGB=NaN,maxRGB=(0,0,0)
	
end

Function CSLabelGUI()
	String listAxis = "None;S21;S11;S21;S12;S22;ΔS21;ΔS11;ΔS12;ΔS22;Volts;Meters;Tesla;Hz;Seconds;σ_xx;σ_xy;Δσ_xx;Δσ_xy;ρ_xx;ρ_xy;Ω;Ω/sq;φ;Δφ;ν;Δν"
	String listPrefix = "None;Yotta;Zeta;Exa;Tera;Peta;Giga;Mega;Kilo;Milli;Micro;Nano;Pico;Femto;Atto;Zepto;Yocto"
	
	string axis = strvarordefault("root:MatthewGlobals:gCSAxis", "None")
	string prefix = strvarordefault("root:MatthewGlobals:gCSPrefix", "None")
	string graph = strvarordefault("root:MatthewGlobals:ggraph","")
	prompt axis, "Axis Label", popup listAxis
	prompt prefix, "Axis Prefix", popup listPrefix
	prompt graph, "Graph", popup ImageNameList("",";")
	
	doPrompt "Colour Scale Label", axis, prefix, graph

	If(v_flag)
		return -1
	endif
	
	//Checking for MatthewGlobals folder
	If(DataFolderExists("root:MatthewGlobals") == 0)
		NewDataFolder root:MatthewGlobals
	endif
	
	string/g root:MatthewGlobals:gCSAxis = axis
	string/g root:MatthewGlobals:gCSPrefix = prefix
	string/g root:MatthewGlobals:ggraph = graph
	
	CSLabel()	
end

Function CSLabel()
	svar CSAxis = root:MatthewGlobals:gCSAxis
	svar CSPrefix = root:MatthewGlobals:gCSPrefix
	svar graph = root:MatthewGlobals:ggraph
	string prefix
	string baseCmd = "ColorScale/C/N="+graph+" "

		strswitch(CSPrefix)
			case "None":
				prefix = ""
				break;
			case "Yotta":
				prefix = "Y"
				break;
			case "Zetta":
				prefix = "Z"
				break;
			case "Exa":
				prefix = "E"
				break;
			case "Peta":
				prefix = "P"
				break;
			case "Tera":
				prefix = "T"
				break;
			case "Giga":
				prefix = "G"
				break;
			case "Mega":
				prefix = "M"
				break;
			case "Kilo":
				prefix = "K"
				break;
			case "Milli":
				prefix = "m"
				break;
			case "Micro":
				prefix = "μ"
				break;
			case "Nano":
				prefix = "n"
				break;
			case "Pico":
				prefix = "p"
				break;
			case "Femto":
				prefix = "f"
				break;
			case "Atto":
				prefix = "a"
				break;
			case "Zepto":
				prefix = "z"
				break;
			case "Yocto":
				prefix = "y"
				break;
		endswitch
		
		strswitch(CSAxis)
			case "None":
				break;
			case "S11":
				Execute (baseCmd+" "+"\"|S\B11\M|\S2\M ("+prefix+"dB)\B"+graph+"\"")
				break;
			case "S21":
				Execute (baseCmd+" "+"\"|S\B21\M|\S2\M ("+prefix+"dB)\B"+graph+"\"")
				break;
			case "S12":
				Execute (baseCmd+" "+"\"|S\B12\M|\S2\M ("+prefix+"dB)\B"+graph+"\"")
				break;
			case "S22":
				Execute (baseCmd+" "+"\"|S\B22\M|\S2\M ("+prefix+"dB)\B"+graph+"\"")
				break;
			case "ΔS11":
				Execute (baseCmd+" "+"\"Δ|S\B11\M|\S2\M ("+prefix+"dB)\B"+graph+"\"")
				break;
			case "ΔS21":
				Execute (baseCmd+" "+"\"Δ|S\B21\M|\S2\M ("+prefix+"dB)\B"+graph+"\"")
				break;
			case "ΔS12":
				Execute (baseCmd+" "+"\"Δ|S\B12\M|\S2\M ("+prefix+"dB)\B"+graph+"\"")
				break;
			case "ΔS22":
				Execute (baseCmd+" "+"\"Δ|S\B22\M|\S2\M ("+prefix+"dB)\B"+graph+"\"")
				break;
			case "Volts":
				Execute (baseCmd+" "+"\"Bias ("+prefix+"V)\B"+graph+"\"")
				break;
			case "Meters":
				Execute (baseCmd+" "+"\""+prefix+"m\B"+graph+"\"")
				break;
			case "Tesla":
				Execute (baseCmd+" "+"\"Field ("+prefix+"T)\B"+graph+"\"")
				break;
			case "Hz":
				Execute (baseCmd+" "+"\"Frequency ("+prefix+"Hz)\B"+graph+"\"")
				break;
			case "Seconds":
				Execute (baseCmd+" "+"\"Time ("+prefix+"s)\B"+graph+"\"")
				break;
			case "σ_xx":
				Execute (baseCmd+" "+"\"Re[σ\Bxx\M("+prefix+"S)]\B"+graph+"\"")
				break;
			case "σ_xy":
				Execute (baseCmd+" "+"\"Re[σ\Bxy\M("+prefix+"S)]\B"+graph+"\"")
				break;
			case "Δσ_xx":
				Execute (baseCmd+" "+"\"Re[Δσ\Bxx\M("+prefix+"S)]\B"+graph+"\"")
				break;
			case "Δσ_xy":
				Execute (baseCmd+" "+"\"Re[Δσ\Bxy\M("+prefix+"S)]\B"+graph+"\"")
				break;
			case "ρ_xx":
				Execute (baseCmd+" "+"\"ρ\Bxx\M("+prefix+"Ω)\B"+graph+"\"")
				break;
			case "ρ_xy":
				Execute (baseCmd+" "+"\"ρ\Bxy\M("+prefix+"Ω)\B"+graph+"\"")
				break;
			case "Ω":
				Execute (baseCmd+" "+"\""+prefix+"Ω\B"+graph+"\"")
				break;
			case "Ω/sq":
				Execute (baseCmd+" "+"\""+prefix+"Ω/sq\B"+graph+"\"")
				break;
			case "φ":
				Execute (baseCmd+" "+"\""+prefix+"φ(S\B21\M) ("+prefix+"radians)\B"+graph+"\"")
				break;
			case "Δφ":
				Execute (baseCmd+" "+"\""+prefix+"Δφ(S\B21\M) ("+prefix+"radians)\B"+graph+"\"")
				break;
		endswitch
		ColorScale/C/N=$graph/F=0/B=1 image=$graph, heightPct=35
		ColorScale/C/N=$graph/A=LT image=$graph, lowTrip=0.001
		ColorScale/C/N=$graph/A=LT height=180
		ColorScale/C/N=$graph/A=LT fsize=18
end

Function defaultGraph()
	ModifyGraph grid(bottom)=2,tick=2,mirror=1,standoff=0
//	ModifyGraph manTick(bottom)={0,1,0,0},manMinor(bottom)={3,2}
	Legend/C/N=text0/J/F=0/B=1/H={0,5,10}/A=LT
	ModifyGraph margin(right)=252
	ModifyGraph font="Times New Roman"
	ModifyGraph lowTrip(bottom)=0.01
end
//Å for adding angstrom to prefix list.
Function AxisLabelsGUI()
	String listAxis = "None;S21;S11;S21;S12;S22;ΔS21;ΔS11;ΔS12;ΔS22;Volts;Meters;Tesla;Hz;Seconds;ReImσ_xx;σ_xx;σ_xy;Δσ_xx;Δσ_xy;ρ_xx;ρ_xy;Ω;Ω/sq;φ;Δφ;ν;Δν"
	String listPrefix = "None;Yotta;Zetta;Exa;Tera;Peta;Giga;Mega;Kilo;Milli;Micro;Nano;Pico;Femto;Atto;Zepto;Yocto"
	
	String leftAxis = strvarordefault("root:MatthewGlobals:gleftAxis", "None")
	String leftPrefix = strvarordefault("root:MatthewGlobals:gleftPrefix", "None")
	String rightAxis = strvarordefault("root:MatthewGlobals:grightAxis", "None")
	String rightPrefix = strvarordefault("root:MatthewGlobals:grightPrefix", "None")
	String bottomAxis = strvarordefault("root:MatthewGlobals:gbottomAxis", "None")
	String bottomPrefix = strvarordefault("root:MatthewGlobals:gbottomPrefix", "None")
	String topAxis = strvarordefault("root:MatthewGlobals:gtopAxis", "None")
	String topPrefix = strvarordefault("root:MatthewGlobals:gtopPrefix", "None")
	Prompt leftAxis, "Left Axis Label", popup listAxis
	Prompt leftPrefix, "Left Prefix", popup listPrefix
	Prompt rightAxis, "Right Axis Label", popup listAxis
	Prompt rightPrefix, "Right Prefix", popup listPrefix
	Prompt bottomAxis, "Bottom Axis Label", popup listAxis
	Prompt bottomPrefix, "Bottom Prefix", popup listPrefix
	Prompt topAxis, "Top Axis Label", popup listAxis
	Prompt topPrefix, "Top Prefix", popup listPrefix

	DoPrompt "Axis Labels",leftAxis,leftPrefix,rightAxis,rightPrefix,bottomAxis,bottomPrefix,topAxis,topPrefix
	
	If(v_flag)
		return -1
	endif
	
	//Checking for MatthewGlobals folder
	If(DataFolderExists("root:MatthewGlobals") == 0)
		NewDataFolder root:MatthewGlobals
	endif
	
	String/g root:MatthewGlobals:gleftAxis = leftAxis
	String/g root:MatthewGlobals:gleftPrefix = leftPrefix
	String/g root:MatthewGlobals:grightAxis = rightAxis
	String/g root:MatthewGlobals:grightPrefix = rightPrefix
	String/g root:MatthewGlobals:gbottomAxis = bottomAxis
	String/g root:MatthewGlobals:gbottomPrefix = bottomPrefix
	String/g root:MatthewGlobals:gtopAxis = topAxis
	String/g root:MatthewGlobals:gtopPrefix = topPrefix
	
	AxisLabels()
end

Function AxisLabels()
	svar leftAxis = root:MatthewGlobals:gleftAxis
	svar leftPrefix = root:MatthewGlobals:gleftPrefix
	svar rightAxis = root:MatthewGlobals:grightAxis
	svar rightPrefix = root:MatthewGlobals:grightPrefix
	svar bottomAxis = root:MatthewGlobals:gbottomAxis
	svar bottomPrefix = root:MatthewGlobals:gbottomPrefix
	svar topAxis = root:MatthewGlobals:gtopAxis
	svar topPrefix = root:MatthewGlobals:gtopPrefix
	
	String listAxis = (leftAxis+";"+rightAxis+";"+bottomAxis+";"+topAxis+";")
	String listPrefix = (leftPrefix+";"+rightPrefix+";"+bottomPrefix+";"+topPrefix+";")
	Variable iter
	String axis, prefix

	for(iter = 0; iter < 4; iter+=1)
		strswitch(StringFromList(iter,listPrefix))
			case "None":
				prefix = ""
				break;
			case "Yotta":
				prefix = "Y"
				break;
			case "Zetta":
				prefix = "Z"
				break;
			case "Exa":
				prefix = "E"
				break;
			case "Peta":
				prefix = "P"
				break;
			case "Tera":
				prefix = "T"
				break;
			case "Giga":
				prefix = "G"
				break;
			case "Mega":
				prefix = "M"
				break;
			case "Kilo":
				prefix = "K"
				break;
			case "Milli":
				prefix = "m"
				break;
			case "Micro":
				prefix = "μ"
				break;
			case "Nano":
				prefix = "n"
				break;
			case "Pico":
				prefix = "p"
				break;
			case "Femto":
				prefix = "f"
				break;
			case "Atto":
				prefix = "a"
				break;
			case "Zepto":
				prefix = "z"
				break;
			case "Yocto":
				prefix = "y"
				break;
		endswitch
		
		switch(iter)
			case 0:
				axis = "left"
				break;
			case 1:
				axis = "right"
				break;
			case 2:
				axis = "bottom"
				break;
			case 3:
				axis = "top"
				break;
		endswitch

		if(cmpstr(StringFromList(iter,listAxis),"None")!=0)
				Execute ("ModifyGraph tickUnit("+axis+")=1")
		endif

		strswitch(StringFromList(iter,listAxis))
			case "None":
				break;
			case "S11":
				Execute ("Label "+axis+" "+"\"|S\B11\M|\S2\M ("+prefix+"dB)\"")
				break;
			case "S21":
				Execute ("Label "+axis+" "+"\"|S\B21\M|\S2\M ("+prefix+"dB)\"")
				break;
			case "S12":
				Execute ("Label "+axis+" "+"\"|S\B12\M|\S2\M ("+prefix+"dB)\"")
				break;
			case "S22":
				Execute ("Label "+axis+" "+"\"|S\B22\M|\S2\M ("+prefix+"dB)\"")
				break;
			case "ΔS11":
				Execute ("Label "+axis+" "+"\"Δ|S\B11\M|\S2\M ("+prefix+"dB)\"")
				break;
			case "ΔS21":
				Execute ("Label "+axis+" "+"\"Δ|S\B21\M|\S2\M ("+prefix+"dB)\"")
				break;
			case "ΔS12":
				Execute ("Label "+axis+" "+"\"Δ|S\B12\M|\S2\M ("+prefix+"dB)\"")
				break;
			case "ΔS22":
				Execute ("Label "+axis+" "+"\"Δ|S\B22\M|\S2\M ("+prefix+"dB)\"")
				break;
			case "Volts":
				Execute ("Label "+axis+" "+"\"Bias ("+prefix+"V)\"")
				break;
			case "Meters":
				Execute ("Label "+axis+" "+"\""+prefix+"m\"")
				break;
			case "Tesla":
				Execute ("Label "+axis+" "+"\"Field ("+prefix+"T)\"")
				break;
			case "Hz":
				Execute ("Label "+axis+" "+"\"Frequency ("+prefix+"Hz)\"")
				break;
			case "Seconds":
				Execute ("Label "+axis+" "+"\"Time ("+prefix+"s)\"")
				break;
			case "ReImσ_xx":
				Execute ("Label "+axis+" "+"\"{Re,Im}[σ\Bxx\M("+prefix+"S)]\"")
				break;
			case "σ_xx":
				Execute ("Label "+axis+" "+"\"Re[σ\Bxx\M("+prefix+"S)]\"")
				break;
			case "σ_xy":
				Execute ("Label "+axis+" "+"\"Re[σ\Bxy\M("+prefix+"S)]\"")
				break;
			case "Δσ_xx":
				Execute ("Label "+axis+" "+"\"Re[Δσ\Bxx\M("+prefix+"S)]\"")
				break;
			case "Δσ_xy":
				Execute ("Label "+axis+" "+"\"Re[Δσ\Bxy\M("+prefix+"S)]\"")
				break;
			case "ρ_xx":
				Execute ("Label "+axis+" "+"\"ρ\Bxx\M("+prefix+"Ω)\"")
				break;
			case "ρ_xy":
				Execute ("Label "+axis+" "+"\"ρ\Bxy\M("+prefix+"Ω)\"")
				break;
			case "Ω":
				Execute ("Label "+axis+" "+"\""+prefix+"Ω\"")
				break;
			case "Ω/sq":
				Execute ("Label "+axis+" "+"\""+prefix+"Ω/sq\"")
				break;
			case "φ":
				Execute ("Label "+axis+" "+"\""+"φ(S\B21\M) ("+prefix+"radians)\"")
				break;
			case "Δφ":
				Execute ("Label "+axis+" "+"\""+"Δφ(S\B21\M) ("+prefix+"radians)\"")
				break;
			case "ν":
				Execute ("Label "+axis+" "+"\""+prefix+"ν"+"\"")
				break;
			case "Δν":
				Execute ("Label "+axis+" "+"\"Δ"+prefix+"ν"+"\"")
				break;
		endswitch
	endfor
end

Function graphAnnotationsGUI()
	If(exists("root:MatthewGlobals:myV_flag") == 0)
		Variable/g root:MatthewGlobals:myV_flag = 0
	endif
	nvar myV_flag = root:MatthewGlobals:myV_flag
	myV_flag = 0

	myV_flag = graphAnnotationsGUI_Device()
	If(myV_flag)
		return -1
	endif
	
	graphAnnotationsGUI_Power()
	If(myV_flag)
		return -1
	endif
	
	graphAnnotationsGUI_fAndV()
	If(myV_flag)
		return -1
	endif
	
	graphAnnotationsGUI_Field()
	If(myV_flag)
		return -1
	endif
	
	graphAnnotations()
end

Function graphAnnotationsGUI_Device()
	String coolDown = strvarordefault("root:MatthewGlobals:gCoolDown", "")
	String dataDate = strvarordefault("root:MatthewGlobals:gdataDate", "")
	String PNType = strvarordefault("root:MatthewGlobals:gPNType", "P-Type")
	String n = strvarordefault("root:MatthewGlobals:gN", "0")
	String wafer = strvarordefault("root:MatthewGlobals:gwafer", "GaAs")
	String device = strvarordefault("root:MatthewGlobals:gDevice", "")
	String l = strvarordefault("root:MatthewGlobals:gL", "2.5")
	String w = strvarordefault("root:MatthewGlobals:gW", "50")
	String mK = strvarOrDefault("root:MatthewGlobals:gmK", "")
	String wellWidth = strvarOrDefault("root:MatthewGlobals:gWellWidth", "")

	Prompt coolDown, "Cooldown Date"
	Prompt dataDate, "Date Taken"
	Prompt PNType, "P/N Type", popup "P-Type;N-Type"
	Prompt n, "Density (10^10 cm^-2)"
	Prompt wafer, "Wafer Type (GaAs, AlAs, etc)"
	Prompt device, "Device"
	Prompt l, "Length (mm)"
	Prompt w, "Slot Width (μm)"
	Prompt mK, "Temperature (mK)"
	Prompt wellWidth "Well Width (nm)"

	DoPrompt "Device Annotations",coolDown, dataDate, device, wellWidth, PNType, wafer, l, w, mK, n
	
	nvar myV_flag = root:MatthewGlobals:myV_flag
	Variable/g root:MatthewGlobals:myV_flag = v_flag
	If(v_flag)
		myV_flag = 1
		return -1
	endif

	//Checking for MatthewGlobals folder
	If(DataFolderExists("root:MatthewGlobals") == 0)
		NewDataFolder root:MatthewGlobals
	endif
	
	String/g root:MatthewGlobals:gCoolDown = coolDown
	String/g root:MatthewGlobals:gDataDate = dataDate
	String/g root:MatthewGlobals:gDevice = device
	String/g root:MatthewGlobals:gWellWidth = wellWidth
	String/g root:MatthewGlobals:gPNType = PNType
	String/g root:MatthewGlobals:gWafer = wafer
	String/g root:MatthewGlobals:gL = l
	String/g root:MatthewGlobals:gW = w
	String/g root:MatthewGlobals:gmK = mK
	String/g root:MatthewGlobals:gN = n
end

Function graphAnnotationsGUI_Power()
	String pTotal = strvarordefault("root:MatthewGlobals:gPTotal", "70")
	String pVna = strvarordefault("root:MatthewGlobals:gPVna", "30")
	String pFridge = strvarordefault("root:MatthewGlobals:gPFridge", "50")
	String pCryoIn = strvarordefault("root:MatthewGlobals:gPCryoIn", "3")
	String pCryoOut = strvarordefault("root:MatthewGlobals:gPCryoOut", "(3+3+3)")
	String pAmp = strvarordefault("root:MatthewGlobals:gPAmp", "27.5")
	String pCryoAmp = strvarordefault("root:MatthewGlobals:gPCryoAmp", "NA")
	
	Prompt pTotal, "Power (To Device, -dBm)"
	Prompt pVna, "Power (VNA, -dBm)"
	Prompt pFridge, "Power (Fridge Top, -dB)"
	Prompt pCryoIn, "Power (MC In, -dB)"
	Prompt pCryoOut, "Power (MC+1K+RT Out, -dB)"
	Prompt pAmp, "Amp Gain (+dB)"
	Prompt pCryoAmp, "Cryo Amp Gain (+dB or NA)"
	
	DoPrompt "Power Annotations", pTotal, pVna, pFridge, pCryoIn, pCryoOut, pAmp, pCryoAmp
	
	nvar myV_flag = root:MatthewGlobals:myV_flag
	Variable/g root:MatthewGlobals:myV_flag = v_flag
	If(v_flag)
		myV_flag = 1
		return -1
	endif
	
	String/g root:MatthewGlobals:gPTotal = pTotal
	String/g root:MatthewGlobals:gPVna = pVna
	String/g root:MatthewGlobals:gPFridge = pFridge
	String/g root:MatthewGlobals:gPCryoIn = pCryoIn
	String/g root:MatthewGlobals:gPCryoOut = pCryoOut
	String/g root:MatthewGlobals:gPAmp = pAmp
	String/g root:MatthewGlobals:gPCryoAmp = pCryoAmp
end

Function graphAnnotationsGUI_fAndV()
	String f = strvarordefault("root:MatthewGlobals:gF", "")
	String IfBW = strvarordefault("root:MatthewGlobals:gIfBW", "10")
	String t = strvarordefault("root:MatthewGlobals:gT", "160")
	String averaging = strvarordefault("root:MatthewGlobals:gAveraging", "1")
	String normVal = strvarordefault("root:MatthewGlobals:gNormVal", "")
	String normUnits = strvarordefault("root:MatthewGlobals:gNormUnits", "ν")
	String volts = strvarordefault("root:MatthewGlobals:gVolts", "NA")
	String voltsStep = strvarordefault("root:MatthewGlobals:gVoltsStep", "NA")
	String voltsRate = strvarordefault("root:MatthewGlobals:gVoltsRate", "NA")
	String voltsLeak = strvarordefault("root:MatthewGlobals:gVoltsLeak", "NA")
	
	Prompt f, "Frequency (GHz)"
	Prompt IfBW, "IfBW"
	Prompt t, "Sweep Time"
	Prompt averaging, "Averaging Factor"
	Prompt normVal, "Normalization Value (Blank=None)"
	Prompt volts, "Volts"
	Prompt voltsStep, "Volts Step Size"
	Prompt voltsRate, "mV/s"
	prompt normUnits, "Normalization Units", popup "Tesla;1/Tesla;ν;Volts"
	prompt voltsLeak, "Leakage (nA)"

	DoPrompt "VNA, Voltage, and Normalization", f, IfBW, t, averaging, normVal, normUnits, volts, voltsStep, voltsRate, voltsLeak
	
	nvar myV_flag = root:MatthewGlobals:myV_flag
	Variable/g root:MatthewGlobals:myV_flag = v_flag
	If(v_flag)
		myV_flag = 1
		return -1
	endif
	
	String/g root:MatthewGlobals:gF = f
	String/g root:MatthewGlobals:gIfBW = IfBW
	String/g root:MatthewGlobals:gT = t
	String/g root:MatthewGlobals:gAveraging = averaging
	String/g root:MatthewGlobals:gNormVal = normVal
	String/g root:MatthewGlobals:gNormUnits = normUnits
	String/g root:MatthewGlobals:gVolts = volts
	String/g root:MatthewGlobals:gVoltsStep = voltsStep
	String/g root:MatthewGlobals:gVoltsRate = voltsRate
	String/g root:MatthewGlobals:gVoltsLeak = voltsLeak
end

Function graphAnnotationsGUI_Field()
	String field = strvarordefault("root:MatthewGlobals:gField", "0")
	String fieldUnits = strvarordefault("root:MatthewGlobals:gFieldUnits", "Tesla")
	String fieldStep = strvarordefault("root:MatthewGlobals:gFieldStep", "0")
	String fieldStepUnits = strvarordefault("root:MatthewGlobals:gFieldStepUnits", "Tesla")
	String fieldRate = strvarordefault("root:MatthewGlobals:gFieldRate", "0")
	
	Prompt field, "Field"
	Prompt fieldUnits "Field Units", popup "Tesla;1/Tesla;ν"
	Prompt fieldStep, "Field Step Size"
	Prompt fieldStepUnits "Field Step Units", popup "Tesla;1/Tesla;ν"
	Prompt fieldRate "Field Rate"
	
	DoPrompt "Field Annotations", field, fieldUnits, fieldStep,  fieldStepUnits, fieldRate
	
	nvar myV_flag = root:MatthewGlobals:myV_flag
	Variable/g root:MatthewGlobals:myV_flag = v_flag
	If(v_flag)
		myV_flag = 1
		return -1
	endif
	
	String/g root:MatthewGlobals:gField = field
	String/g root:MatthewGlobals:gFieldUnits = fieldUnits
	String/g root:MatthewGlobals:gFieldStep = fieldStep
	String/g root:MatthewGlobals:gFieldStepUnits = fieldStepUnits
	String/g root:MatthewGlobals:gFieldRate = fieldRate
end

Function graphAnnotations()
	svar voltsRate = root:MatthewGlobals:gVoltsRate
	svar volts = root:MatthewGlobals:gVolts
	svar fieldRate = root:MatthewGlobals:gfieldRate
	svar Field = root:MatthewGlobals:gField
	svar PNType = root:MatthewGlobals:gPNType
	svar wellWidth = root:MatthewGlobals:gwellWidth
	svar dataDate = root:MatthewGlobals:gDataDate
	svar device = root:MatthewGlobals:gDevice
	svar n = root:MatthewGlobals:gN
	svar pTotal = root:MatthewGlobals:gPTotal
	svar pVna = root:MatthewGlobals:gPVna
	svar pFridge = root:MatthewGlobals:gPFridge
	svar pCryoIn = root:MatthewGlobals:gPCryoIn 
	svar pCryoOut = root:MatthewGlobals:gPCryoOut 
	svar pAmp = root:MatthewGlobals:gPAmp
	svar pCryoAmp = root:MatthewGlobals:gPCryoAmp
	svar IfBW = root:MatthewGlobals:gIfBW
	svar t = root:MatthewGlobals:gT
	svar volts = root:MatthewGlobals:gVolts
	svar fieldUnits = root:MatthewGlobals:gFieldUnits
	svar field = root:MatthewGlobals:gfield
	svar coolDown = root:MatthewGlobals:gCoolDown
	svar w = root:MatthewGlobals:gW
	svar l = root:MatthewGlobals:gL
	svar averaging = root:MatthewGlobals:gAveraging
	svar f = root:MatthewGlobals:gF
	svar fieldUnits = root:MatthewGlobals:gFieldUnits
	svar mK = root:MatthewGlobals:gmK
	svar normVal = root:MatthewGlobals:gNormVal
	svar normUnits = root:MatthewGlobals:gNormUnits
	svar wafer = root:MatthewGlobals:gWafer
	svar fieldStepUnits = root:MatthewGlobals:gfieldStepUnits
	svar fieldStep = root:MatthewGlobals:gfieldStep
	svar voltsStep = root:MatthewGlobals:gvoltsStep
	svar voltsLeak = root:MatthewGlobals:gVoltsLeak
	
	String FieldUnitsTxt, FieldStepUnitsTxt
		
	if(!cmpstr(fieldUnits,"Tesla",2))
		fieldUnitsTxt = "Tesla"
	elseif(!cmpstr(fieldUnits, "1/Tesla",2))
		fieldUnitsTxt = "Tesla\\S-1\\M"
	else
		fieldUnitsTxt = "\\F'Times New Roman'ν\\]0"
	endif		
	if(!cmpstr(fieldStepUnits,"Tesla",2))
		fieldStepUnitsTxt = "Tesla"
	elseif(!cmpstr(fieldStepUnits, "1/Tesla",2))
		fieldStepUnitsTxt = "Tesla\\S-1\\M"
	else
		fieldStepUnitsTxt = "\\F'Times New Roman'ν\\]0"
	endif

	textBox/C/N=fSTxt/A=LT "\\Z14\\[0Date Taken: "+dataDate
	appendText/N=fSTxt "Device: "+device
	appendText/N=fSTxt "Type: "+PNType+" "+wafer
	appendText/N=fSTxt "Cooldown: "+coolDown
	appendText/N=fSTxt "Slot: "+w +" μm"
	appendText/N=fSTxt "Length: "+l+" mm"
	appendText/N=fSTxt "Well Width: "+wellWidth+" nm"
	appendText/N=fSTxt "n: "+n+" (10\\S10\\M cm\\S-2\\M)"
	appendText/N=fSTxt "P\\BTo Device\\M: -"+pTotal+" dBm"
	appendText/N=fSTxt "P\\BVNA\\M: -"+pVna+" dBm"
	appendText/N=fSTxt "P\\BFridge Top\\M: -"+pFridge+" dB"
	appendText/N=fSTxt "P\\BMC In\\M: -"+pCryoIn+" dB"
	appendText/N=fSTxt "P\\BMC+1K+RT Out\\M: -"+pCryoOut+" dB"
	appendText/N=fSTxt "Amp: +"+pAmp+" dB"
	appendText/N=fSTxt "Cryo Amp: +"+pCryoAmp+" dB"
	appendText/N=fSTxt "IfBW: "+IfBW+ " Hz"
	appendText/N=fSTxt "Frequency: "+f+" GHz"
	appendText/N=fSTxt "t: "+t+" sec"
	appendText/N=fSTxt "Averaging Factor: "+ averaging
	appendText/N=fSTxt "T: "+mK+" mK"
	appendText/N=fSTxt "Bias: "+volts+" Volts"
	appendText/N=fSTxt "Leakage: "+voltsLeak+" nA"
	appendText/N=fSTxt "Bias Step Size: "+voltsStep+" Volts"
	appendText/N=fSTxt "Bias Rate: "+voltsRate+" mV/s"
	appendText/N=fSTxt "Field: "+field+" "+FieldUnitsTxt
	appendText/N=fSTxt "Field Step Size: "+fieldStep+" "+FieldStepUnitsTxt
	appendText/N=fSTxt "Field Rate: "+fieldRate+" Tesla/min"
	
	if(!cmpstr(normVal,"",2))
		appendText/N=fsTxt "Normalization: None"
	elseif(!cmpstr(normUnits, "1/Tesla",2))
		appendText/N=fSTxt "Normalization: "+"Tesla\\S-1\\M"+" = "+normVal
	elseif(!cmpstr(normUnits, "ν",2))
		appendText/N=fSTxt "Normalization: \\F'Times New Roman'"+normUnits+" \\]0= "+normVal
	else
		appendText/N=fSTxt "Normalization: "+normUnits+" \\]0= "+normVal
	endif
	
	textBox/C/N=fSTxt/F=0/B=1/H={0,10,10}

end

Function LoadCFGGUI()
	String cfgPath = strvarordefault("root:MatthewGlobals:gcfgpath","")
	String dateString = strvarordefault("root:MatthewGlobals:gdateString","")
	Prompt cfgPath, "Path"
	Prompt dateString, "Date String"
	DoPrompt "Load CFG File", cfgPath, dateString

	If(v_flag)
		return -1
	endif

	//Checking for MatthewGlobals folder
	If(DataFolderExists("root:MatthewGlobals") == 0)
		NewDataFolder root:MatthewGlobals
	endif
	
	String/g root:MatthewGlobals:gcfgPath = cfgPath
	String/g root:MatthewGlobals:gdateString = dateString

	LoadCFG()
end

Function LoadCFG()
	Svar cfgPath = root:MatthewGlobals:gcfgPath
	Svar dateString = root:MatthewGlobals:gdateString

	LoadWave/J/M/U={0,0,1,0}/D/O/E=1/K=0/N=$("CFG_"+dateString)/P=$cfgPath "CFG.txt"
	rename $("CFG_"+dateString+"0") $("CFG_"+dateString)
	
end

Function dataTimeWaveGUI()
	String cfgName = strvarordefault("root:MatthewGlobals:gcfgName","cfg_YYYYMMDD")
	Prompt cfgName, "Path to CFG Wave"
	DoPrompt "Load Data Taken Time Wave", cfgName
	
	If(v_flag)
		return -1
	endif

	//Checking for MatthewGlobals folder
	If(DataFolderExists("root:MatthewGlobals") == 0)
		NewDataFolder root:MatthewGlobals
	endif
	
	String/g root:MatthewGlobals:gcfgName=cfgName
	
	dataTimeWave()
End

Function dataTimeWave()
	svar cfgName=root:MatthewGlobals:gcfgName
	variable iter1
	wave/t cfg=$cfgName
	make/o/d/n=(DimSize(cfg,0)) startTimes, stopTimes, startLevel, stopLevel
	make/o/t/n=(DimSize(cfg,0)) startTxt
	stopLevel = 0.05
	startLevel = 0.05
	wave startTimes
	wave stopTimes
	SetScale d 0,0,"dat", startTimes
	SetScale d 0,0,"dat", stopTimes
	for(iter1=0;iter1<numpnts(startTimes);iter1++)
	if(iter1==0)
		startTimes[iter1]=dataTimeWave_cfgTime2Secs(cfg[iter1][2],1)
	endif
		startTxt[iter1]=cfg[iter1][1]+"/"+cfg[iter1][0]
		startTimes[iter1]=dataTimeWave_cfgTime2Secs(cfg[iter1][2],0)
		stopTimes[iter1]=dataTimeWave_cfgTime2Secs(cfg[iter1][3],0)
	endfor
End

Function dataTimeWave_cfgTime2Secs(cfgTime,printValues)
	String cfgTime
	Variable printValues
	Variable year, month, day, hour, minute, second
	String AmPm
	
	sscanf cfgTime, "%d/%d/%d %d:%d:%d %s", year, month, day, hour, minute, second, AmPm

	
	if(StringMatch(ampm,"Pm")==1 && hour<12)
		hour=hour+12
	elseif(StringMatch(ampm, "Am")==1 && hour==12)
		hour=0
	endif
	
	if(printValues == 1)
		print (num2str(year)+"/"+num2str(month)+"/"+num2str(day)+" "+num2Str(hour)+":"+num2str(minute)+":"+num2str(second)+" "+ampm)
	endif
	return(date2secs(year,month,day)+3600*hour+60*minute+second)
End

//Adds when data starts taking to device temperature graph
//Meant to work in tandem with loading cfg and processing data start times from it
Function loadCFG_appndStrtTms()
	wave startLevel = startLevel
	wave startTimes = startTimes
	AppendToGraph startLevel vs startTimes
	DoUpdate
	String traceListStr = traceNameList("",";",1)
	String listItem, lastStartLevel
	variable iter1 = 0
	
	//Find startLevel just added to graph
	do
		listItem = stringFromList(iter1, traceListStr)
		if(stringMatch(listItem, "startLevel*") == 1)
			lastStartLevel = listItem
		endif
		iter1 += 1
	while(stringMatch(listItem,"") == 0)
	
	//Fix appearance
	//Need to use Execute or DoUpdate creates race condition?
	Execute "ModifyGraph mode("+lastStartLevel+")=8"
	Execute "ModifyGraph textMarker("+lastStartLevel+")={startTxt,\"default\",0,90,0,-6.00,0.00}"
	Execute "ModifyGraph rgb("+lastStartLevel+")=(0,0,0)"
end

//Adds when data stops taking to device temperature graph
//Meant to work in tandem with loading cfg and processing data start times from it
Function loadCFG_appndStpTms()
	wave stopLevel = stopLevel
	wave stopTimes = stopTimes
	AppendToGraph stopLevel vs stopTimes
	DoUpdate
	String traceListStr = traceNameList("",";",1)
	String listItem, lastStopLevel
	variable iter1 = 0
	
	//Find startLevel just added to graph
	do
		listItem = stringFromList(iter1, traceListStr)
		if(stringMatch(listItem, "stopLevel*") == 1)
			lastStopLevel = listItem
		endif
		iter1 += 1
	while(stringMatch(listItem,"") == 0)
	
	//Fix appearance
	//Need to use Execute or DoUpdate creates race condition?
	Execute "ModifyGraph mode("+lastStopLevel+")=8"
	Execute "ModifyGraph textMarker("+lastStopLevel+")={startTxt,\"default\",0,90,0,-6.00,0.00}"
	Execute "ModifyGraph rgb("+lastStopLevel+")=(0,0,0)"
end

//Power Waves are p<Base><Index>
//Complex Waves are c<Base><Index>
//Mag/Arg Waves are <m;a><Base><Index> (Not useful in Igor 8 and later, use complex.)
//Conductivity Waves are RS<Base><Index> (Not useful in Igor 8 and later, use complex.)
//Normalized Waves have "n" prefixed
//Complex Conductivity Waves are CS<Base><Index>

//Visual GUI From Macro to Load Waves
Function mattLoadGUI()
	String dataPath = strvarordefault("root:MatthewGlobals:gdataPath", "") 
	String nameBase = strvarordefault("root:MatthewGlobals:gnameBase", "f")
	variable x0 = numvarordefault("root:MatthewGlobals:gx0", 0.0003)
	variable xf = numvarordefault("root:MatthewGlobals:gxf", 20)
	String switch0f = strvarordefault("root:MatthewGlobals:gswitch0f", "No")
	String units = strvarordefault("root:MatthewGlobals:gunits", "GHz")
	String normS = strvarordefault("root:MatthewGlobals:gnormS", "None")
	String txtS = strvarordefault("root:MatthewGlobals:gtxtS", ".txt")
	String colReS = strvarordefault("root:MatthewGlobals:gcolReS", "1:2")
	prompt dataPath, "Path"
	prompt nameBase, "Name Base"
	prompt x0, "X Start"
	prompt xf, "X Final"
	prompt switch0f, "Switch x0 & xf Every Other Wave", popup "Yes;No"
	prompt units, "Units", popup "GHz;Tesla;Volts;None"
	prompt normS, "Normalizer (Complex) or None"
	prompt txtS, "File Extension", popup ".txt;.csv;.s2p;No Extension"
	DoPrompt "Load Data to Waves",dataPath, nameBase, x0, xf, switch0f, units, normS, txtS

	If(v_flag)
		return -1
	endif

	//This is for loading files without .txt
	String extS
	if(!cmpstr(txtS, ".txt",2))
		extS = txtS
	elseif(!cmpstr(txtS, ".csv",2))
		extS = txtS
	elseif(!cmpstr(txtS, ".s2p",2))
		extS = txtS
	else
		extS = "????"
	endif
	
	//Checking for MatthewGlobals folder
	If(DataFolderExists("root:MatthewGlobals") == 0)
		NewDataFolder root:MatthewGlobals
	endif
	

	//Create globals of prompted entries for future entry
	String/g root:MatthewGlobals:gdataPath = dataPath
	String/g root:MatthewGlobals:gnameBase = nameBase
	variable/g root:MatthewGlobals:gx0 = x0
	variable/g root:MatthewGlobals:gxf = xf
	String/g root:MatthewGlobals:gswitch0f = switch0f
	String/g root:MatthewGlobals:gunits = units
	String/g root:MatthewGlobals:gnormS = normS
	String/g root:MatthewGlobals:gtxtS = txtS

	//Create Waves Off All Indexed Files in Range
	//Note on fileList is for changing to support non .txt files
	String fileList
	variable nFiles
	fileList = indexedfile($dataPath, -1, extS)
	fileList = sortlist(fileList,";",16)
	nFiles = itemsinlist(fileList)
	make/o/t/n=(nFiles) root:MatthewGlobals:fileName
	make/o/t/n=(nFiles) root:MatthewGlobals:nameBaseW
	make/o/t/n=(nFiles) root:MatthewGlobals:unitW
	make/o/n=(nFiles) root:MatthewGlobals:x0W
	make/o/n=(nFiles) root:MatthewGlobals:xfW
	wave/t fileName=root:MatthewGlobals:fileName
	wave/t nameBaseW=root:MatthewGlobals:nameBaseW
	wave/t unitW=root:MatthewGlobals:unitW
	wave x0W=root:MatthewGlobals:x0W
	wave xfW=root:MatthewGlobals:xfW
	if(strlen(fileList) == 0)
		print "**********************************************\r"
		print "No files found to load waves!\r"
		print "Macro aborted.\r"
		print "**********************************************\r"
		Abort("No files found to load waves!  Macro aborted.")	
	endif
	fileName = stringfromlist(p, fileList)
	unitW = units
	x0W = x0
	xfW = xf
	if(!cmpstr(switch0f, "Yes",2))
		mattLoad_switch0fFunc(x0W, xfW)
	endif
	nameBaseW = nameBase
	
	mattLoadGUI2()
end
	
Function mattLoadGUI2()
	String loadP = strvarordefault("root:MatthewGlobals:gloadP","Yes")
	String loadnP = strvarordefault("root:MatthewGlobals:gloadnP","Yes")
//	String LoadSig = strvarordefault("root:MatthewGlobals:gloadSig","Yes")
//	String LoadnSig = strvarordefault("root:MatthewGlobals:gloadnSig","Yes")
//	String loadAM	 = strvarordefault("root:MatthewGlobals:gloadAM","Yes")
//	String loadnAM	 = strvarordefault("root:MatthewGlobals:gloadnAM","Yes")
	String LoadCSig = strvarordefault("root:MatthewGlobals:gloadCSig","Yes")
	String LoadnCSig = strvarordefault("root:MatthewGlobals:gloadnCSig","Yes")
	Prompt loadP, "Power", popup "Yes;No"
	Prompt loadnP, "Normalized Power", popup "Yes;No"
//	Prompt loadSig, "Real Conducitivity", popup "Yes;No"
//	Prompt loadnSig, "Normalized real Conducitivity", popup "Yes;No"
//	Prompt loadAM, "Arguement/Magnitude", popup "Yes;No"
//	Prompt loadnAM, "Normalized Arguement/Magnitude", popup "Yes;No"
	Prompt loadCSig, "Complex Conducitivity", popup "Yes;No"
	Prompt loadnCSig, "Normalized Complex Conducitivity", popup "Yes;No"
//	DoPrompt "Waves to Load (Complex always Loaded)",loadP, loadnP, loadSig, loadnSig, loadAM, loadnAM, loadCSig, loadnCSig
	DoPrompt "Waves to Load (Complex always Loaded)",loadP, loadnP, loadCSig, loadnCSig
	
	If(v_flag)
		return -1
	endif
	
	String/g root:MatthewGlobals:gloadP = loadP
//	String/g root:MatthewGlobals:gloadSig = loadSig
//	String/g root:MatthewGlobals:gloadAM = loadAM
	String/g root:MatthewGlobals:gloadCSig = loadCSig
	String/g root:MatthewGlobals:gloadnP = loadnP
//	String/g root:MatthewGlobals:gloadnSig = loadnSig
//	String/g root:MatthewGlobals:gloadnAM = loadnAM
	String/g root:MatthewGlobals:gloadnCSig = loadnCSig
	
	wave/t fileName=root:MatthewGlobals:fileName
	wave/t nameBaseW=root:MatthewGlobals:nameBaseW
	wave/t unitW=root:MatthewGlobals:unitW
	wave x0W=root:MatthewGlobals:x0W
	wave xfW=root:MatthewGlobals:xfW
	//Index Files and Load Window
	//Kill previous windows if they exist
	dowindow/k Files_to_Load
	dowindow/k loadFiles
	//Create named windows
	edit fileName, nameBaseW, x0W, xfW, unitW
	dowindow/c Files_to_Load
	mattLoadFiles()
end

Function mattLoadWaves()
	//Recieved Variables
	svar dataPath = root:MatthewGlobals:gdataPath
	wave/t fileName = root:MatthewGlobals:fileName
	wave/t namebaseW = root:MatthewGlobals:nameBaseW
	svar nameBase=root:MatthewGlobals:gnameBase
	wave x0W = root:MatthewGlobals:x0W
	wave xfW = root:MatthewGlobals:xfW
	wave/t unitW = root:MatthewGlobals:unitW
	svar normS = root:MatthewGlobals:gnormS//Name of normalizing wave
	svar type = root:MatthewGlobals:gtype//Output waves in Power, Complex, or Mag/Arg
	svar fldr = root:MatthewGlobals:gfldr
	wave cpwDims = root:MatthewGlobals:cpwDims
	svar loadP = root:MatthewGlobals:gloadP
	svar loadSig = root:MatthewGlobals:gloadSig
	svar loadAM = root:MatthewGlobals:gloadAM
	svar loadCSig = root:MatthewGlobals:gloadCSig
	svar loadnP = root:MatthewGlobals:gloadnP
	svar loadnSig = root:MatthewGlobals:gloadnSig
	svar loadnAM = root:MatthewGlobals:gloadnAM
	svar loadnCSig = root:MatthewGlobals:gloadnCSig
	String tempNameTxt
	String tempName, tempNameN
	variable iter //My Generic Loop Counter
	String myBool = "Yes" //Generic Yes/No boolean
	String myString1, myString2 //Generic Temporary Strings
	variable x0, xf //For Command Line Print Display
	String waveString //For cleanup of unused loaded waves
	String printString
	wave indexW=root:MatthewGlobals:indexW

	//For figuring out which columns have Re and Im components
	String ReS
	String ImS
	ReS = "root:tempWave" + num2str(indexW[3])
	ImS = "root:tempWave" + num2str(indexW[3]+1)
	
	//Checking for MatthewGlobals folder
	If(DataFolderExists("root:MatthewGlobals") == 0)
		NewDataFolder root:MatthewGlobals
	endif

	//Make Data Folders if Necessary
	if(DataFolderExists("Power") == 0 && cmpstr(loadP,"Yes")==0)
		NewDataFolder Power
	endif
	if(DataFolderExists("Complex") == 0)
		NewDataFolder Complex
	endif
//	if(DataFolderExists("MagArg") == 0 && cmpstr(loadAM,"Yes")==0)
//		NewDataFolder MagArg
//	endif
//		if(DataFolderExists(":MagArg:Mag") == 0 && cmpstr(loadAM,"Yes")==0)
//			NewDataFolder :MagArg:Mag
//		endif
//		if(DataFolderExists(":MagArg:Arg") == 0 && cmpstr(loadAM,"Yes")==0)
//			NewDataFolder :MagArg:Arg
//		endif
//	if(DataFolderExists("ReSigxx") == 0 && cmpstr(loadSig,"Yes")==0)
//		NewDataFolder ReSigxx
//	endif
	if(DataFolderExists("CSigxx") == 0 && cmpstr(loadCSig,"Yes")==0)
		NewDataFolder CSigxx
	endif

	print "**********************************************\r"
	for(iter = 0; iter < numpnts(x0W); iter+=1)
		tempName = nameBaseW[iter]
		tempNameN = getDataFolder(1)
		cd root:MatthewGlobals:
		LoadWave/q/g/L={0,indexW[2],0,indexW[3],0}/o/j/d/N=tempWave/P=$dataPath fileName[iter]
		wave Re = $("tempWave"+num2str(indexW[3]))
		wave Im = $("tempWave"+num2str(indexW[3]+1))
		cd tempNameN

		//Load Complex Wave
		//Nomenclature c<BASE><INDEX>
		CD Complex
		tempName = "c"+nameBaseW[iter]
		make/c/o/n=(numpnts(Re)) $(tempName)
		wave/c cWave = $(tempName)
		cWave = cmplx(Re, Im)
		setscale/i x x0W[iter],xfW[iter],unitW[iter],cWave
		CD ::

		//Make Power Wave
		//Nomenclature p<BASE><INDEX>
		If(!cmpstr(loadP, "Yes",2))
			CD Power
			tempName = "p" + nameBaseW[iter]	
			make/o/n=(numpnts(Re)) $(tempName)
			wave pWave = $(tempName)
			pWave = 10*log(Re^2 + Im^2)
			setscale/i x x0W[iter],xfW[iter],unitW[iter],pWave
			CD ::
		endif

		//NO LONGER USEFUL IN IGOR 8, USE COMPLEX WAVES	
		//Make Magnitude/Argument Waves
		//Nomenclature {m,a}<BASE><INDEX>
//		If(cmpstr(loadAM, "Yes") == 0)
//			CD :MagArg:Mag
//			tempName = "m" + nameBaseW[iter]
//			make/o/n=(numpnts(Re)) $(tempName)
//			wave mWave = $(tempName)
//			mWave = sqrt(Re^2 + Im^2)
//			setscale/i x x0W[iter],xfW[iter],unitW[iter],mWave
//			CD ::Arg
//			tempName = "a" + nameBaseW[iter]
//			make/o/n=(numpnts(Re)) $(tempName)
//			wave aWave = $(tempName)
//			aWave = atan2(Im, Re)
//			setscale/i x x0W[iter],xfW[iter],unitW[iter],aWave
//			CD :::
//		endif

		//Make Re(Sigxx) Waves
		//Nomenclature RS<BASE><INDEX>
//		If(cmpstr(loadSig, "Yes") == 0)
//			CD ReSigxx
//			tempName = "RS" + nameBaseW[iter]
//			make/o/n=(numpnts(Re)) $(tempName)
//			wave RSWave = $(tempName)
//			RSWave = -1e6*cpwDims[1]*ln(10)*10*log(Re^2 + Im^2)/(20*cpwDims[0]*50)
//			setscale/i x x0W[iter],xfW[iter],unitW[iter],RSWave
//			CD ::
//		endif
		
		//Make Complex Conductivities Waves
		//Nomenclature CS<BASE><INDEX>
		If(!cmpstr(loadCSig, "Yes",2))
			CD CSigxx
			tempName = "CS" + nameBaseW[iter]
			make/o/c/n=(numpnts(Re)) $(tempName)
			wave/c CSWave = $(tempName)
			//cpwDims[1]==width, cpwDims[0]=length
			CSWave = -1e6*(cpwDims[1]/(2*50*cpwDims[0]))*cmplx(ln(Re^2+Im^2),atan2(Im,Re))
			setscale/i x x0W[iter],xfW[iter],unitW[iter],CSWave
			CD ::
		endif
	endfor 

	//Clean up temporary waves
	//Clean up temporary waves
	killwaves Re
	killwaves Im
		
	//Checks to makes sure normalizing wave exists
	if(cmpstr(normS,"None") != 0 && exists(normS) != 1)
		printf "* Normalizing Wave '%s' does not exist!\r" normS
		print "* No normalized waves loaded!\r"
		myBool = "No"
	elseif(cmpstr(normS,"None") != 0 && exists(normS) == 1)
		myBool = "Yes"
	endif
	
	//*****Load Normalized Waves*****
	//Nomenclature n<c,p,m,a,RS><BASE>_<INDEX>
//	if(cmpstr(normS,"None") != 0 && cmpstr(myBool, "Yes") == 0)
	if(cmpstr(normS,"None") != 0 && exists(normS) == 1)
		//Make Data Folders if Necessary
		if(DataFolderExists("nPower") == 0 && cmpstr(loadnP,"Yes")==0)
			NewDataFolder nPower
		endif
		if(DataFolderExists("nComplex") == 0)
			NewDataFolder nComplex
		endif
//		if(DataFolderExists("nMagArg") == 0 && cmpstr(loadnAM,"Yes")==0)
//			NewDataFolder nMagArg
//		endif
//		if(DataFolderExists(":nMagArg:nMag") == 0 && cmpstr(loadnAM,"Yes")==0)
//			NewDataFolder :nMagArg:nMag
//		endif
//		if(DataFolderExists(":nMagArg:nArg") == 0 && cmpstr(loadnAM,"Yes")==0)
//			NewDataFolder :nMagArg:nArg
//		endif
//		if(DataFolderExists("nReSigxx") == 0 && cmpstr(loadnSig,"Yes")==0)
//			NewDataFolder nReSigxx
//		endif
	if(DataFolderExists("nCSigxx") == 0 && cmpstr(loadnCSig,"Yes")==0)
		NewDataFolder nCSigxx
	endif
		
		//Load Normalized Waves	
		for(iter = 0; iter < numpnts(x0W); iter+=1)
			wave/c normWave = $normS
			//Complex
			CD nComplex
			tempName = "c" + nameBaseW[iter]
			tempNameN = "nc" + nameBaseW[iter]
			duplicate/o ::Complex:$tempName $tempNameN
			wave/c ncWave = $(tempNameN)
			ncWave /= normWave
			CD ::

			//Power
			If(!cmpstr(loadnP, "Yes",2))
				CD nPower
				tempName = "p" + nameBaseW[iter]
				tempNameN = "np" + nameBaseW[iter]
				duplicate/o ::Power:$tempName $tempNameN
				wave npWave = $(tempNameN)
				npWave = 10*log(Real(ncWave)^2+Imag(ncWave)^2)
				CD ::
			endif
	
			//NO LONGER USEFUL IN IGOR 8, USE COMPLEX		
			//Argument/Magnitude
//			If(cmpstr(loadnAM, "Yes") == 0)
//				CD :nMagArg:nMag
//				tempName = "m" + nameBaseW[iter]
//				tempNameN = "nm" + nameBaseW[iter]
//				duplicate/o :::MagArg:Mag:$tempName $tempNameN
//				wave nmWave = $(tempNameN)
//				nmWave = sqrt(Real(ncWave)^2+Imag(ncWave)^2)
//				CD ::nArg	
//				tempName = "a" + nameBaseW[iter]
//				tempNameN = "na" + nameBaseW[iter]
//				duplicate/o :::MagArg:Arg:$tempName $tempNameN
//				wave naWave = $(tempNameN)
//				naWave = atan2(Imag(ncWave), Real(ncwave))
//				CD :::
//			endif
			
			//Re(Sigxx)
//			If(cmpstr(loadnSig, "Yes") == 0)
//				CD nReSigxx
//				tempName = "RS" + nameBaseW[iter]
//				tempNameN = "nRS" + nameBaseW[iter]
//				duplicate/o ::ReSigxx:$tempName $tempNameN
//				wave nRSWave = $(tempNameN)
//				nRSWave = -1e6*cpwDims[1]*ln(10)*10*log(Real(ncWave)^2 + Imag(ncWave)^2)/(20*cpwDims[0]*50)
//				CD ::
//			endif
			
			//Cmplx(Sigxx)
			If(!cmpstr(loadnCSig, "Yes",2))
				CD nCSigxx
				tempName = "nc" + nameBaseW[iter]
				tempNameN = "nCS" + nameBaseW[iter]
				duplicate/o ::nComplex:$tempName $tempNameN
				wave/c nCWave = ::nComplex:$(tempName)
				wave/c nCSWave = $(tempNameN)
				//cpwDims[1]==width, cpwDims[0]=length
				nCSWave = -1e6*(cpwDims[1]/(2*50*cpwDims[0]))*cmplx(ln(Real(nCWave)^2+Imag(nCWave)^2),atan2(Imag(nCWave),Real(nCWave)))
				setscale/i x x0W[iter],xfW[iter],unitW[iter],nCSWave
				CD ::
			endif
		endfor 
	endif	

	//Sets range so command print out has low to high displayed
	if(x0W[0] < xfW[0])
		x0 = x0W[0]
		xf = xfW[0]
	else
		x0 = xfW[0]
		xf = x0W[0]
	endif

	//Print to History actions taken
	printf "* Waves: %s to %s (Increments of %g)\r", nameBaseW[0], nameBaseW[numpnts(x0W)-1], indexW[1]
	printf "* Normalizing Wave: %s\r", normS
	printf "* Range: [%g, %g] %s\r", x0, xf, unitW[0]	
	print "**********************************************"	

end

//Switches x0 and xf values when sweeping back and forth
Function mattLoad_switch0fFunc(x0W, xfW)
	wave x0W, xfW
	variable iter
	variable tempX
	for(iter = 1; iter < numpnts(x0W); iter+=2)
		tempX = x0W[iter]
		x0W[iter] = xfW[iter]
		xfW[iter] = tempX
	endfor
end

Function mattLoadFiles():panel
	if(StringMatch(WinList("loadFilesPanel","","WIN:64"),"loadFilesPanel")==1)
		KillWindow loadFilesPanel
	endif
	newpanel/k=1/w=(700,100,900,345)/n=loadFilesPanel as "Load Files"
	//Load Button
	button loadButton size={150,25},pos={25,5},proc=mattLoad_loadButtonFunc,title="Load Files",labelback=(1,26214,0)
	
	//CPW Dimensions Variables
	If(exists("root:MatthewGlobals:cpwDims") != 1)
		make/o/n=2 root:MatthewGlobals:cpwDims
		wave cpwDims = root:MatthewGlobals:cpwDims
		cpwDims[0] = 2500
		cpwDims[1] = 30
	else
		wave cpwDims = root:MatthewGlobals:cpwDims
	endif
	
	//Index Button
	button appendIndex size={120,20},pos={50,55},proc=mattLoad_appendIndexFunc,title="Append Indices",labelback=(1,26214,0)
	If(exists("root:MatthewGlobals:indexW") != 1)
		make/o/n=4 root:MatthewGlobals:indexW
		wave indexW = root:MatthewGlobals:indexW
		indexW[0] = 0
		indexW[1] = 1
		indexW[2] = 0
		indexW[3] = 0
	else
		wave indexW = root:MatthewGlobals:indexW
	endif
	
	setvariable indexStart size={160,20}, value=indexW[0],pos={15,85},noproc,title="Starting Index",bodywidth=70
	setvariable indexInc size={160,20}, value=indexW[1],pos={15,110},noproc,title="Increment",bodywidth=70
	setvariable firstRow size={160,20}, value=indexW[2],pos={15,135},noproc,title="First Row With Data",bodywidth=70
	setvariable firstCol size={160,20}, value=indexW[3],pos={15,160},noproc,title="First Col With Data",bodywidth=70
	setvariable cpwLen size={160,20}, value=cpwDims[0],pos={15,185},noproc,title="CPW Length (microns)",bodywidth=70
	setvariable cpwWid size={160,20}, value=cpwDims[1],pos={15,210},noproc,title="CPW Width (microns)",bodywidth=70
	
	modifyPanel cbRGB = (25000, 40000, 60000)
end

Function mattLoad_loadButtonFunc(loadButton):buttonControl
	String loadButton
	mattLoadWaves()	
end

Function mattLoad_appendIndexFunc(appendIndex):buttonControl
	String appendIndex
	wave/t nameBaseW = root:MatthewGlobals:nameBaseW
	wave indexW = root:MatthewGlobals:indexW
	variable indexN
	String nameBaseTemp
	String zeros = ""
	Variable iter, int2, numZero
	Variable maxIndex = (numpnts(nameBaseW)+indexW[0])*indexW[1]
	String maxIndexS = num2str(maxIndex)
	for(iter = 0; iter < numpnts(nameBaseW); iter+=1)
		indexN = iter*indexW[1] + indexW[0]
		nameBaseTemp = nameBaseW[iter]
		nameBaseW[iter] = nameBaseTemp + preAppendZeros(num2str(indexN))
//		numZero = 3 - strlen(num2str(indexN))
//		for(int2 = 0; int2 < numZero; int2+=1)
//			zeros = zeros + "0"
//		endfor
//		nameBaseW[iter] = nameBaseTemp + zeros + num2str(indexN)
//		zeros = ""
	endfor
end

Menu "Matthew"
	subMenu "Colourscale Plots"
		"Make Colour Scale Plot", /Q, colourPlotGUI()
//Never finished, did not work on Graphene long enough to bother
//Planned to duplicate image of bias vs field with pixels that land on fillings set to black.
//	"Fit Filling to CSP", fitFillingCSPGUI() 
		"Colour Scale Legend", /Q, CSLabelGUI()
		"Colour Scale Sliders", /Q, cspSldr_addZSliders()
	end
	subMenu "Graph Styles"
		"Default Axis Style", /Q, defaultGraph()
		"Axis Labels", /Q, AxisLabelsGUI()
		"Axis Scale Sliders (time, value)", /Q, scaleSldr_addXSliders()
		"Graph Annotations", /Q, graphAnnotationsGUI()
		"No Menu Annotations", /Q, GraphAnnotations()
	end
	subMenu "Load From Text"
		"Load CFG", /Q, LoadCFGGUI()
		subMenu "CFG Processing"
			"Quick Load and Graph", /Q, //In progress, for merging loading CFG, rBridge, and plotting temperatures+startTimes
			"Load CFG Data Time Waves",/Q, dataTimeWaveGUI()
			"Append Start Times to Graph",/Q,loadCFG_appndStrtTms()
			"Append Stop Times to Graph",/Q,loadCFG_appndStpTms()
//		"Append Stop Times to Graph",/Q,addDataStopToGraph() //Not really needed, would modify or duplicate loadCFG_appndStrtTms()
		end
		"Load Data to Waves", /Q, mattLoadGUI()
//		"Load Helium Level", /Q, HeLevelLoadGUI() //Meant for dill fridge, abandoned as fridge is VERY predictable in LHe rate.
		"Load LS211", /Q, LS211GUI()
		"Load Resistance Bridge", /Q, rBridgeGUI()
		"Load Sonnet Files to Waves", /Q, loadSonnetGUI()
	end
	subMenu "Utility"
//	"Differential Solve RLCPW", /Q, difSolvHypWaveGUI() //For RLCPW, works, simple iterative numerical approach
		"Delete Unused Waves", /Q, cleanWavesGUI()
//	"Notch Slider", /Q, addNotchSliders() //Not sure where code is for this, tied up in some RLCPW experiment?
		"Plasmon Frequency", /Q, plasmonfGUI()
		"SeparateLRWaves", /Q, SeparateLRWavesGUI()
		"Sliding Normalization", /Q, SlidingNormGUI()
//		"Remove VNA Bad Points", /Q, fixVNAPtsGUI() //Not Needed anymore with better labVIEW code
	end
//	subMenu "Deprecated"
//		"Norm to Wave", /Q, norm2WaveGUI() //Built in to load files and can use listOps
//		"Conductivity", /Q, conductGUI() //Commented out in file
//		"Subtract a Point", /Q, subtractAPtGUI() //Commented out in file
//		"Phase from Cmp Waves", /Q, makePhaseGUI() //Commented out in file
//	end
end

//No longer needed with better labVIEW code
//Create Menu Item
//This function modifies when wave[i] > 3*wave[i-1]
//Then does wave[i+1] = wave[i-1]
//Does this for outer 3 points
//Function fixVNAPtsGUI()
//	String nameBase = strvarordefault("root:MatthewGlobals:gnameBase", "f")
//	String append0s = strvarordefault("root:MatthewGlobals:gappend0s", "Yes")
//	Variable index0 = numvarordefault("root:MatthewGlobals:gindex0", 1)
//	Variable indexF = numvarordefault("root:MatthewGlobals:gindexF", 10)
//	Variable nmpt = numvarordefault("root:MatthewGlobals:gnmpt", 1601)
//	Prompt nameBase, "Base Name"
//	prompt append0s, "Do indices have 0s preappended?", popup "Yes;No"
//	Prompt index0, "First Index"
//	Prompt indexF, "Last Index"
//	Prompt nmpt, "Rescale to Number of Points"
//	DoPrompt "Fix VNA Bad Points", nameBase, append0s, index0, indexF, nmpt
//	
//	If(v_flag)
//		return -1
//	endif
//	
//	//Checking for MatthewGlobals folder
//	If(DataFolderExists("root:MatthewGlobals") == 0)
//		NewDataFolder root:MatthewGlobals
//	endif
//	
//	String/g root:MatthewGlobals:gnameBase = nameBase
//	Variable/g root:MatthewGlobals:gindex0 = index0
//	Variable/g root:MatthewGlobals:gindexF = indexF
//	String/g root:MatthewGlobals:gappend0s = append0s
//	Variable/g root:MatthewGlobals:gnmpt = nmpt
//	
//	fixVNAPts()
//end
//
//Function fixVNAPts()
//	svar nameBase = root:MatthewGlobals:gnameBase
//	nvar index0 = root:MatthewGlobals:gindex0
//	nvar indexF = root:MatthewGlobals:gindexF
//	svar append0s = root:MatthewGlobals:gappend0s
//	nvar nmpt = root:MatthewGlobals:gnmpt
//	Variable int, intZ, intL
//	Variable midP, lenW
//	Variable numZero
//	String nameW
//	String zeros
//	String printString
//	
//	
//	print "***************************************************"
//	for(int = index0; int <= indexF; int+=1)
//		//Generate pre-Appended Zeros if Needed
//		zeros = ""
//		If(StringMatch(append0s,"Yes") == 1)
//			numZero = 3 - strlen(num2str(int))
//			for(intZ = 0; intZ < numZero; intZ+=1)
//				zeros = zeros + "0"
//			endfor
//		endif
//				
//		//Load Wave
//		nameW = nameBase + zeros + num2str(int)
//		Wave dataW = $nameW
//		printString =  "Fixing: " + nameW
//		print printString
//		
//		//Fix bad points at end and start of data
//		lenW = numpnts(dataW)
//		for(intL = 0; intL <= 3; intL+=1)
//			If(abs(dataW[intL]) > 2.5*abs(dataW[intL+1]))
//				dataW[intL] = dataW[intL+1]
//			endif
//			If(2.5*abs(dataW[lenW+intL-3]) > abs(dataW[lenW+intL-4]))
//				dataW[lenW+intL-3] = dataW[lenW+intL-4]
//			endif
//		endfor 
//		DeletePoints (lenW-1), (lenW-nmpt), dataW
//
//	
//	endfor
//	print "***************************************************"
//	
//end

//Depecrated, fixed by getting better at labview code for the VNA
//Prompts Values and Calls Operation Function
//Function subtractAPtGUI()
//	String nameBase = strvarordefault("root:MatthewGlobals:gnameBase", "f")
//	String append0s = strvarordefault("root:MatthewGlobals:gappend0s", "Yes")
//	Variable index0 = numvarordefault("root:MatthewGlobals:gindex0", 1)
//	Variable indexF = numvarordefault("root:MatthewGlobals:gindexF", 10)
//	String firstLastAvg = strvarordefault("root:MatthewGlobals:gfirstLastAvg", "Average")
//	String switch0f = strvarordefault("root:MatthewGlobals:gswitch0f", "Yes")
//	Variable specPt = numvarordefault("root:MatthewGlobals:gspecPt", 0)
//	String specVal = strvarordefault("root:MatthewGlobals:gspecVal", "Value")
//	Prompt nameBase, "Base Name"
//	prompt append0s, "Do indices have 0s preappended?", popup "Yes;No"
//	Prompt index0, "First Index"
//	Prompt indexF, "Last Index"
//	Prompt firstLastAvg, "Use First, Last, specific, or Average Point?", popup "First;Last;Specific;Average"
//	Prompt switch0f, "Alternate using first and last point?", popup "Yes;No"
//	Prompt specPt, "Specific Point"
//	Prompt specVal, "Is Specific Index or Value?", popup "Index;Value"
//	DoPrompt "Subtract a Point in Wave", nameBase, append0s, index0, indexF, firstLastAvg, switch0f, specPt, specVal
//	
//	If(v_flag)
//		return -1
//	endif
//	
//	//Checking for MatthewGlobals folder
//	If(DataFolderExists("root:MatthewGlobals") == 0)
//		NewDataFolder root:MatthewGlobals
//	endif
//	
//	String/g root:MatthewGlobals:gnameBase = nameBase
//	Variable/g root:MatthewGlobals:gindex0 = index0
//	Variable/g root:MatthewGlobals:gindexF = indexF
//	String/g root:MatthewGlobals:gappend0s = append0s
//	String/g root:MatthewGlobals:gfirstLastAvg = firstLastAvg
//	String/g root:MatthewGlobals:gswitch0f = switch0f
//	Variable/g root:MatthewGlobals:gspecPt = specPt
//	String/g root:MatthewGlobals:gspecVal = specVal
//	
//	subAPt()
//	
//end
//
////Operation Function
//Function subAPt()
//	svar nameBase = root:MatthewGlobals:gnameBase
//	nvar index0 = root:MatthewGlobals:gindex0
//	nvar indexF = root:MatthewGlobals:gindexF
//	svar append0s = root:MatthewGlobals:gappend0s
//	svar firstLastAvg = root:MatthewGlobals:gfirstLastAvg
//	svar switch0f = root:MatthewGlobals:gswitch0f
//	nvar specPt = root:MatthewGlobals:gspecPt
//	svar specVal = root:MatthewGlobals:gspecVal
//	Variable int //My Loop Counter
//	Variable int2 //My Second Loop Counter
//	String nameW //Name of Wave Operating On
//	String nameSub //Subtracted Wave Name
//	Variable subI = 0 //Index Subtracting
//	String printString
//	String zeros = ""
//	Variable numZero
//	
//	print "***************************************************"
//	for(int = index0; int <= indexF; int+=1)
//		//Generate pre-Appended Zeros if Needed
//		If(StringMatch(append0s,"Yes") == 1)
//			numZero = 3 - strlen(num2str(int))
//			for(int2 = 0; int2 < numZero; int2+=1)
//				zeros = zeros + "0"
//			endfor
//		endif
//		//Generate Wave Names to be Used and Duplicate Wave
//		nameW = nameBase + Zeros + num2str(int)
//		nameSub = nameBase + "Sub" + Zeros + num2str(int)
//		printString = "Wave: " + nameW + " Subtracted to: " + nameSub
//		print printString
//		Duplicate/o $nameW $nameSub
//		wave oldW = $nameW
//		wave subW = $nameSub
//		
//		//Set Whether First or Last Index is Used in Math for First/Last Point
//		If(StringMatch(switch0f,"Yes") == 1 && mod(int-index0,2) == 0)
//			If(StringMatch(firstLastAvg,"First") == 1)
//				subI = 0
//			else
//				subI = numpnts(subW) - 1
//			endif
//		elseIf(StringMatch(switch0f,"Yes") == 1 && mod(int-index0,2) != 0)
//			If(StringMatch(firstLastAvg,"First") == 1)
//				subI = numpnts(subW) - 1
//			else
//				subI = 0
//			endif
//		elseIf(StringMatch(switch0f, "No") == 1)
//			If(StringMatch(firstLastAvg, "First") == 1)
//				subI = 0
//			else
//				subI = numpnts(subW) - 1
//			endif
//		endif
//		
//		//Do the Subtraction
//		for(int2 = 0; int2 < numpnts(subW); int2+=1)
//			//Find Average Value if Subtraction by that Method
//			If(StringMatch(firstLastAvg, "Average") == 1)
//				WaveStats/Q oldW
//				subW[int2] = oldW[int2] - V_avg
//			//Subtract a Specific Specified Index or Value
//			elseIf(StringMatch(firstLastAvg, "Specific") == 1)
//				If(StringMatch(specVal, "Index") == 1)
//					subW[int2] = oldW[int2] - oldW[specPt]
//				else
//					subW[int2] = oldW[int2] - oldW(specPt)
//				endif
//			else
//				subW[int2] = oldW[int2] - oldW[subI]
//			endif
//		endfor	
//		zeros = ""
//	endfor
//	print "***************************************************"
//	
//end	

//Use listOps or take advantage of mattLoad code
//Function norm2WaveGUI()
//	String nameBase = strvarordefault("root:MatthewGlobals:gnameBase", "f")
//	String append0s = strvarordefault("root:MatthewGlobals:gappend0s", "Yes")
//	Variable index0 = numvarordefault("root:MatthewGlobals:gindex0", 1)
//	Variable indexF = numvarordefault("root:MatthewGlobals:gindexF", 10)
//	String switch0f = strvarordefault("root:MatthewGlobals:gswitchof", "Yes")
//	String normDir0 = strvarordefault("root:MatthewGlobals:gnormDir0", "Yes")
//	String normWave = strvarordefault("root:MatthewGlobals:gnormWave", "")
//	Prompt nameBase, "Base Name"
//	prompt append0s, "Do indices have 0s preappended?", popup "Yes;No"
//	Prompt index0, "First Index"
//	Prompt indexF, "Last Index"
//	Prompt switch0f, "Alternate Index Direction?", popup "Yes;No"
//	Prompt normDir0, "Norm in Direction of First Index?", popup "Yes;No"
//	Prompt normWave, "Normalize to:"
//	DoPrompt "Normalize Waves", nameBase, append0s, index0, indexF, switch0f, normDir0, normWave
//	
//	If(v_flag)
//		return -1
//	endif
//	
//	//Checking for MatthewGlobals folder
//	If(DataFolderExists("root:MatthewGlobals") == 0)
//		NewDataFolder root:MatthewGlobals
//	endif
//	
//	String/g root:MatthewGlobals:gnameBase = nameBase
//	String/g root:MatthewGlobals:gappend0s = append0s
//	Variable/g root:MatthewGlobals:gindex0 = index0
//	Variable/g root:MatthewGlobals:gindexF = indexF
//	String/g root:MatthewGlobals:gswitch0f = switch0f
//	String/g root:MatthewGlobals:gnormDir0 = normDir0
//	String/g root:MatthewGlobals:gnormWave = normWave
//	
//	norm2Wave()
//	
//end
//
//Function norm2Wave()
//	svar nameBase = root:MatthewGlobals:gnameBase
//	nvar index0 = root:MatthewGlobals:gindex0
//	nvar indexF = root:MatthewGlobals:gindexF
//	svar append0s = root:MatthewGlobals:gappend0s
//	svar switch0f = root:MatthewGlobals:gswitch0f
//	svar normDir0 = root:MatthewGlobals:gnormDir0
//	svar normWave = root:MatthewGlobals:gnormWave
//	svar Zeros = root:MatthewGlobals:gZeros
//	Variable int //My Loop Counter
//	Variable int2 //My Second Loop Counter
//	Variable iter1, iter2, numZero
//	String nameW
//	String nameNorm
//	String printString
//	Wave normy = $normWave
//	Zeros = ""
//
//	print "***************************************************"
//	for(int = index0; int <= indexF; int+=1)
//		//Generate pre-Appended Zeros if Needed
//		If(StringMatch(append0s,"Yes") == 1)
//			zeros = ""
//			numZero = 3 - strlen(num2str(indexF))
//			for(iter1 = 0; iter1 < numZero; iter1+=1)
//				zeros = zeros + "0"
//			endfor
//		endif
//		//Generate Wave Names to be Used and Duplicate Wave
//		nameW = nameBase + Zeros + num2str(int)
//		nameNorm = nameBase + "N" + Zeros + num2str(int)
//		printString = "Wave: " + nameNorm + " Normalized to: " + normWave
//		print printString
//		Duplicate/o $nameW $nameNorm
//		wave oldW = $nameW
//		wave normW = $nameNorm
//		
//		//Do the Operation
//		for(int2 = 0; int2 < numpnts(normW); int2+=1)
//			If(StringMatch(switch0f,"Yes") == 1 && mod(int-index0,2) == 0)
//				If(StringMatch(normDir0,"Yes") == 1)
//					normW[int2] = normW[int2] - normy[int2]
//				else
//					normW[int2] = normW[int2] - normy[numpnts(normy)-int2]
//				endif
//			elseIf(StringMatch(switch0f,"Yes") == 1 && mod(int-index0,2) == 1)			
//				If(StringMatch(normDir0,"Yes") == 0)
//					normW[int2] = normW[int2] - normy[numpnts(normy)-int2]
//				else
//					normW[int2] = normW[int2] - normy[int2]
//				endif
//			elseIf(StringMatch(switch0f,"Yes") == 0)		
//				normW[int2] = normW[int2] - normy[int2]
//			endif
//		endfor
//	endfor
//	print "***************************************************"
//end

//Deprecated code to create conductivity waves
//Prompts Values and Calls Operation Function
//Function conductGUI()
//	String nameBase = strvarordefault("root:MatthewGlobals:gnameBase", "f")
//	String append0s = strvarordefault("root:MatthewGlobals:gappend0s", "Yes")
//	Variable index0 = numvarordefault("root:MatthewGlobals:gindex0", 1)
//	Variable indexF = numvarordefault("root:MatthewGlobals:gindexF", 10)
//	Variable wid = numvarordefault("root:MatthewGlobals:gwid", 30)
//	Variable len = numvarordefault("root:MatthewGlobals:glen", 10)
//	Variable Z0 = numvarordefault("root:MatthewGlobals:gZ0", 50)
//	Variable vnadB = numvarordefault("root:MatthewGlobals:gvnadB", 50)
//	Prompt nameBase, "Base Name"
//	prompt append0s, "Do indices have 0s preappended?", popup "Yes;No"
//	Prompt index0, "First Index"
//	Prompt indexF, "Last Index"
//	Prompt wid, "Slot Width in microns"
//	Prompt len, "CC Length in mm"
//	Prompt Z0, "Characterstic Impedance"
//	Prompt vnadB, "Attenuation Offset"
//	DoPrompt "Create Conductivity Waves", nameBase, append0s, index0, indexF, wid, len, Z0, vnadB
//	
//	If(v_flag)
//		return -1
//	endif
//	
//	//Checking for MatthewGlobals folder
//	If(DataFolderExists("root:MatthewGlobals") == 0)
//		NewDataFolder root:MatthewGlobals
//	endif
//	
//	String/g root:MatthewGlobals:gnameBase = nameBase
//	String/g root:MatthewGlobals:gappend0s = append0s
//	Variable/g root:MatthewGlobals:gindex0 = index0
//	Variable/g root:MatthewGlobals:gindexF = indexF
//	Variable/g root:MatthewGlobals:gwid = wid
//	Variable/g root:MatthewGlobals:glen = len
//	Variable/g root:MatthewGlobals:gZ0 = Z0
//	Variable/g root:MatthewGlobals:gvnadB = vnadB
//	String/g root:MatthewGlobals:gzeros = ""
//	
//	conductCalc()
//	
//end
//
//Function conductCalc()
//	svar nameBase = root:MatthewGlobals:gnameBase
//	svar append0s = root:MatthewGlobals:gappend0s
//	nvar index0 = root:MatthewGlobals:gindex0
//	nvar indexF = root:MatthewGlobals:gindexF
//	nvar wid = root:MatthewGlobals:gwid
//	nvar len = root:MatthewGlobals:glen
//	nvar Z0 =root:MatthewGlobals:gZ0
//	nvar vnadB = rroot:MatthewGlobals:gvnadB
//	svar Zeros = root:MatthewGlobals:gZeros
//	Variable int1 //My Loop Counter
//	Variable int2 //My Second Loop Counter
//	String nameOld
//	String nameCon
//	String printString
//	Zeros = ""
//	Variable mag = 1
//	Variable numZero
//
//	print "***************************************************"
//	For(int1 = index0; int1 <= indexF; int1+=1)
//		//Generate pre-Appended Zeros if Needed
//		If(StringMatch(append0s,"Yes") == 1)
//			numZero = 3 - strlen(num2str(int1))
//			for(int2 = 0; int2 < numZero; int2+=1)
//				zeros = zeros + "0"
//			endfor
//		endif
//
//		//Load and Create Waves
//		nameOld = nameBase + "_" + Zeros + num2str(int1)
//		nameCon = nameBase + "_Con" + Zeros + num2str(int1)
//		Duplicate/o $nameOld $nameCon
//		Wave oldW = $nameOld
//		Wave newW = $nameCon
//
//		//Create Conductivity Wave
//		For(int2 = 0; int2 < numpnts(newW); int2+=1)
//			If((oldW[int2]-vnadB) > 0)
//				mag = 1
//			else
//				mag = -1
//			endif
//			newW[int2] = (-wid*1000/(Z0*len))*ln(mag*(oldW[int2]+vnadB))
//		endfor
//		printString = nameOld + " to Conductivity Wave " + nameCon
//		Print printString
//		zeros = ""
//	endfor
//	print "***************************************************"
//end
//
//Function makePhaseGUI()
//	String nameBase = strvarordefault("root:MatthewGlobals:gnameBase", "f")
//	String append0s = strvarordefault("root:MatthewGlobals:gappend0s", "Yes")
//	Variable index0 = numvarordefault("root:MatthewGlobals:gindex0", 1)
//	Variable indexF = numvarordefault("root:MatthewGlobals:gindexF", 10)
//	variable x0 = numvarordefault("root:MatthewGlobals:gx0", 0.0003)
//	Variable xF = numvarordefault("root:MatthewGlobals:gxF", 20)
//	String units = strvarordefault("root:MatthewGlobals:gunits", "Tesla")
//	String switch0F = strvarordefault("root:MatthewGlobals:gswitch0F", "No")
//
//	Prompt nameBase, "Base Name"
//	prompt append0s, "Do indices have 0s preappended?", popup "Yes;No"
//	Prompt index0, "First Index"
//	Prompt indexF, "Last Index"
//	Prompt x0, "X Start"
//	Prompt xF, "X Final"
//	Prompt units, "Units of Wave", popup "Tesla;Volts;GHz"
//	prompt switch0f, "Switch x0 & xF Every Other Wave", popup "Yes;No"
//	DoPrompt "Phase in Degrees from Complex Waves", nameBase, append0s, index0, indexF, x0, xF, units, switch0F
//	
//	//Checking for MatthewGlobals folder
//	If(DataFolderExists("root:MatthewGlobals") == 0)
//		NewDataFolder root:MatthewGlobals
//	endif
//
//	String/g root:MatthewGlobals:gnameBase = nameBase
//	String/g root:MatthewGlobals:gappend0s = append0s
//	Variable/g root:MatthewGlobals:gindex0 = index0
//	Variable/g root:MatthewGlobals:gindexF = indexF
//	Variable/g root:MatthewGlobals:gx0 = x0
//	Variable/g root:MatthewGlobals:gxF = xF
//	String/g root:MatthewGlobals:gunits = units
//	String/g root:MatthewGlobals:gswitch0F = switch0F
//	String/g root:MatthewGlobals:gzeros = ""
//	
//	makePhaseFunc()
//end
//
//Function makePhaseFunc()
//	svar nameBase = root:MatthewGlobals:gnameBase
//	svar append0s = root:MatthewGlobals:gappend0s
//	nvar index0 = root:MatthewGlobals:gindex0
//	nvar indexF = root:MatthewGlobals:gindexF
//	nvar x0 = root:MatthewGlobals:gx0
//	nvar xF = root:MatthewGlobals:gxF
//	svar units = root:MatthewGlobals:gunits
//	svar switch0F= root:MatthewGlobals:gswitch0F
//	Variable xTemp //Here for switch0F
//	Variable int //My Loop Counter
//	Variable int2 //My Second Loop Counter
//	String nameOld
//	String namePhase
//	String printString
//	String zeros = ""
//	Variable numZero
//
//	print "***************************************************"
//	For(int = index0; int <= indexF; int+=1)
//		//Generate pre-Appended Zeros if Needed
//		If(StringMatch(append0s,"Yes") == 1)
//			numZero = 3 - strlen(num2str(int))
//			for(int2 = 0; int2 < numZero; int2+=1)
//			zeros = zeros + "0"
//		endfor
//		endif
//		
//		//Load and Create Waves
//		nameOld = nameBase + "_" + Zeros + num2str(int)
//		namePhase = nameBase + "_phase" + Zeros + num2str(int)
//		Make/o/n=(numpnts($nameOld)) $namePhase
//		Wave oldW = $nameOld
//		Wave newW = $namePhase
//
//		//Swaps x0 and xF if needed for scaling and scale wave
//		If(cmpstr(switch0F, "Yes") == 0 && (int-index0) > 0)
//			xTemp = x0
//			x0 = xF
//			xF = xTemp
//		endif
//		setscale/i x x0,xF,units,$namePhase
//		
//		//Create Conductivity Wave
//		For(int2 = 0; int2 < numpnts(newW); int2+=1)
//			newW[int2] = (180/(2*pi))*atan2(Imag(oldW[int2]), Real(oldW[int2]))
//		endfor
//		printString = nameOld + " to Phase Wave " + namePhase
//		Print printString
//		zeros = ""
//	endfor
//	print "***************************************************"
//end

Function plasmonfGUI()
	Variable density = numvarordefault("root:MatthewGlobals:gdensity", 5)
	Variable mass = numvarordefault("root:MatthewGlobals:gmass", 1)
	Variable ksc = numvarordefault("root:MatthewGlobals:gksc", 1)
	Variable kin = numvarordefault("root:MatthewGlobals:gkin", 1)
	Variable dsc = numvarordefault("root:MatthewGlobals:gdsc", 750)
	Variable din = numvarordefault("root:MatthewGlobals:gdin", 500)
	Variable waveL = numvarordefault("root:MatthewGlobals:gwaveL", 30)
	Variable numq = numvarordefault("root:MatthewGlobals:gnumq", 4)
	Prompt density, "Density (1e10 cm^-2)"
	Prompt mass, "Relative mass"
	Prompt ksc, "Dielectric Semi-Conductor"
	Prompt kin, "Dielectric Insulator"
	Prompt dsc, "Thickness Semi-Condcuctor (um)"
	Prompt din, "Thickness Insulator (nm)"
	Prompt waveL, "Wave Length (um)"
	prompt numq, "Number of wave vectors"
	DoPrompt "Plasmon Frequency Calculator", density, mass, ksc, kin, dsc, din, waveL, numq
	
	If(v_flag)
		return -1
	endif
		
	//Checking for MatthewGlobals folder
	If(DataFolderExists("root:MatthewGlobals") == 0)
		NewDataFolder root:MatthewGlobals
	endif
	
	Variable/g root:MatthewGlobals:gdensity = density
	Variable/g root:MatthewGlobals:gmass = mass
	Variable/g root:MatthewGlobals:gksc = ksc
	Variable/g root:MatthewGlobals:gkin = kin
	Variable/g root:MatthewGlobals:gdsc = dsc
	Variable/g root:MatthewGlobals:gdin = din
	Variable/g root:MatthewGlobals:gwaveL = waveL
	Variable/g root:MatthewGlobals:gnumq = numq
	
	plasmonf()
	
end

//Dahl and Sham
//Conducting boundaries and neglects retardation effects
Function plasmonf()
	nvar n = root:MatthewGlobals:gdensity
	nvar mass = root:MatthewGlobals:gmass
	nvar ksc = root:MatthewGlobals:gksc
	nvar kin = root:MatthewGlobals:gkin
	nvar dsc = root:MatthewGlobals:gdsc
	nvar din = root:MatthewGlobals:gdin
	nvar waveL = root:MatthewGlobals:gwaveL
	nvar numq = root:MatthewGlobals:gnumq
	
	Variable iter
	Variable ele = 1.60218e-19
	Variable m = 9.10938e-31
	Variable eps = 8.85419e-12
	Variable q
	Variable wp
	
	for(iter = 0; iter < numq; iter+=1)
		q = (iter+1)*pi/(waveL*1e-6)
		wp = sqrt(n*1e14*ele^2*q/(mass*m*eps*(ksc/tanh(q*dsc*1e-6)+kin/tanh(q*din*1e-9))))
		print "Plasmon Frequency "+num2str(iter+1)+": "+num2str(wp*1e-9)+" GHz"
	endfor

end

//LoadWave/J/D/W/K=0/V={","," $",0,0}/R={English,2,2,2,2,"Year/Month/DayOfMonth",40} "Macintosh HD:Users:engellab1:Documents:Matthew Freeman:Igor Data:GaAs:M11_10_11p1_A:20191011:RBridge.txt"
//LoadWave/q/g/L={0,indexW[1],0,indexW[3],0}/o/j/d/N=tempWave/P=$dataPath fileName[iter]
Function rBridgeGUI()
	String rBPath	= strvarordefault("root:MatthewGlobals:grBPath", "cfgYYYYMMDD")
	String rBName	= strvarordefault("root:MatthewGlobals:grBName", "rBridge.txt")
	Prompt rBPath, "Path"
	Prompt rBName, "Name of File"
	DoPrompt "Load Resistance Bridge Temperature File", rBPath, rBName

	If(v_flag)
		return -1
	endif

	//Checking for MatthewGlobals folder
	If(DataFolderExists("root:MatthewGlobals") == 0)
		NewDataFolder root:MatthewGlobals
	endif
	
	String/g root:MatthewGlobals:grBPath = rBPath
	String/g root:MatthewGlobals:grBName = rBName


	rBridgeGUI2()
end

Function RBridgeGUI2()


	rBridge()
end

Function rBridge()
	svar rBPath = root:MatthewGlobals:grBPath
	svar rBName = root:MatthewGlobals:grBName
	Variable iter
	String waveN
	
	//Check for RBridge folder
	If(DataFolderExists(":RBridge") == 0)
		NewDataFolder :RBridge
	endif
	
	cd :RBridge
//	If(waveexists(root:MatthewGlobals:gRBNames)==0)
		//Print "You shouldn't be here"
		make/n=24/t/o root:MatthewGlobals:gRBNames
		wave/t RBNames=root:MatthewGlobals:gRBNames
		RBNames[0] = "StillDate"
		RBNames[1] = "StillKelvin"
		RBNames[2] = "StillResistance"
		RBNames[3] = "CPDate"
		RBNames[4] = "CPKelvin"
		RBNames[5] = "CPResistance"
		RBNames[6] = "MCDate"
		RBNames[7] = "MCKelvin"
		RBNames[8] = "MCResistance"
		RBNames[9] = "OneKDate"
		RBNames[10] = "OneKKelvin"
		RBNames[11] = "OneKResistance"
		RBNames[12] = "SorbDate"
		RBNames[13] = "SorbKelvin"
		RBNames[14] = "SorbResistance"
		RBNames[15] = "Aux5Date"
		RBNames[16] = "Aux5Kelvin"
		RBNames[17] = "Aux5Resistance"
		RBNames[18] = "Aux6Date"
		RBNames[19] = "Aux6Kelvin"
		RBNames[20] = "Aux6Resistance"
		RBNames[21] = "Aux7Date"
		RBNames[22] = "Aux7Kelvin"
		RBNames[23] = "Aux7Resistance"
//	else
//		wave/t RBNames=root:MatthewGlobals:gRBNames
//	endif
	for(iter=0; iter<=23; iter+=1)
		waveN = RBNames[iter]
		LoadWave/Q/O/J/D/W/K=0/V={","," $",0,0}/R={English,2,2,2,2,"Year/Month/DayOfMonth",40}/L={0,0,0,iter,1}/N=$waveN/P=$rBPath rBName
		If(waveexists($(waveN+"0"))==1)
			duplicate/O $(waveN+"0") $(waveN)
			killwaves $(waveN+"0")
		endif
	endfor
	cd ::
	Print "***************************************"
	Print "Loaded Resistance Bridge Temperatures"
	Print "***************************************"
	
end

//When sweeping field or voltage it is time consuming to sweep back to the start to take data.
//Better still to get data sweeping back to the start point.
//This code seperates odd and even numbered waves while renumbering them.
//e.g. B_001,B_002,B_003,B_004 -> B_L001,B_R001,B_L002,B_R002
Function separateLRWaves()
	svar nameBase = root:MatthewGlobals:gnameBaseSLR
	svar firstDir = root:MatthewGlobals:gfirstDir
	nvar index0 = root:MatthewGlobals:gindex0
	nvar indexF = root:MatthewGlobals:gindexF
	nvar indexNew0 = root:MatthewGlobals:gindexNew0
	variable int, zint
	string oldName = "tempOld"
	string newName = "tempNew"
	String PN
	String printString = oldName+" renamed "+newName
	String Zeros
	variable numWaves = indexF - index0 + 1
	variable num0s
	String newIndexS, indexS
	variable indexNewF
	
	//Check if # waves are odd for getting new final index right
	if(mod(numWaves, 2) == 0)
		indexNewF = indexNew0 - 1 + numWaves/2
	else
		indexNewF = indexNew0 - 1 + (numWaves+1)/2
	endif
		
	print "********************************"
	for(int = 1; int <= numWaves; int+=1)
//		//Get # of 0s to prefix on index for oldName
//		num0s = 3 - strlen(num2str(int+index0-1))
////		num0s = strlen(num2str(numWaves)) - strlen(num2str(int+index0-1))
//		Zeros = ""
//		for(zint = 0; zint < num0s; zint+=1)
//			Zeros = Zeros + "0"
//		endfor
		
		indexS = nameBase+preAppendZeros(num2str(index0+int-1))
		oldName = nameBase + indexS
//		oldName = nameBase + Zeros + num2str(index0+int-1)

		if(cmpstr(firstDir, "Positive") != 0 && mod(int,2) == 1)
			PN = "L"
		elseif(cmpstr(firstDir, "Positive") != 0 && mod(int,2) == 0)
			PN = "R"
		elseif(cmpstr(firstDir, "Negative") != 0 && mod(int,2) == 1)
			PN = "R"
		elseif(cmpstr(firstDir, "Negative") != 0 && mod(int,2) == 0)
			PN = "L"
		endif	
	
		//Rename even then odd to be new start index + 1,2,3,...
//		Zeros = ""
		if(mod(int,2) == 0)
			newIndexS = preAppendZeros(num2str(indexNew0-1+int/2))
			newName = nameBase+PN+newIndexS
//			newIndexS = num2str(indexNew0-1+int/2)
//			num0s = 3 - strlen(newIndexS)
////			num0s = strlen(num2str(indexNewF)) - strlen(newIndexS)
//			for(zint = 0; zint < num0s; zint+=1)
//				Zeros = Zeros + "0"
//			endfor
//			newName = nameBase+PN+Zeros+newIndexS
		else
			newIndexS = preAppendZeros(num2str(indexNew0-1+(int+1)/2))
			newName  = nameBase+PN+newIndexS
//			newIndexS = num2str(indexNew0-1+(int+1)/2)
//			num0s = 3 - strlen(newIndexS)	
////			num0s = strlen(num2str(indexNewF)) - strlen(newIndexS)	
//			for(zint = 0; zint < num0s; zint+=1)
//				Zeros = Zeros + "0"
//			endfor
//			newName = nameBase+PN+Zeros+newIndexS
		endif
	duplicate/o $oldName $newName
	printString = oldName + " duplicated to " + newName
	print printString
	endfor
	print "********************************\r"

end

Function SeparateLRWavesGUI()//nameBase, firstDir, index0, indexF, indexNew0)
	String nameBase = strvarordefault("root:MatthewGlobals:gnameBaseSLR", "f")
	String firstDir = strvarordefault("root:MatthewGlobals:gfirstDir", "Positive")
	variable index0 = numvarordefault("root:MatthewGlobals:gindex0", 1)
	variable indexF = numvarordefault("root:MatthewGlobals:gindexF", 10)
	variable indexNew0 = numvarordefault("root:MatthewGlobals:gindexNew0", 1)
	prompt nameBase, "Base Name"
	prompt firstDir, "Direction of Sweep at First Index (Below)", popup "Positive;Negative"
	prompt index0, "First Index"
	prompt indexF, "Last Index"
	prompt indexNew0, "Start Index for Separated Waves"
	DoPrompt "Separate Left and Right Waves", nameBase, firstDir, index0, indexF, indexNew0
	
	If(v_flag)
		return -1
	endif

	String/g root:MatthewGlobals:gnameBaseSLR = nameBase
	String/g root:MatthewGlobals:gfirstDir = firstDir
	variable/g root:MatthewGlobals:gindex0 = index0
	variable/g root:MatthewGlobals:gindexF = indexF
	variable/g root:MatthewGlobals:gindexNew0 = indexNew0

	separateLRWaves()

end

//Lloyd likes to use the Macros menu for everything and wanted to use my CSP sliders
Menu "Macros"
	"CSP Z Sliders",/Q,addZSliders()
end

Function cspSldr_addZSliders()
	controlbar 100
	Variable zMaxVal,zMinVal,rvrs,clr_pos,absMax
	String colour,rvrs_S, imageDirectory
	PopupMenu ImageList title="Image",pos={670,10},bodyWidth=100,value=ImageNameList("",";"),fSize=12,proc=cspSldr_ImageMenu
	ControlInfo ImageList
	imageDirectory = GetDataFolder(1,GetWavesDataFolderDFR(ImageNameToWaveRef("",S_value)))
	ImageStats $(imageDirectory+S_value)
	sscanf StringFromList(10,imageinfo("",S_value,0)), "RECREATION:ctab= {%f,%f,%s",zMinval,zMaxVal,colour
	splitString/e="([[:alpha:]]+),([[:digit:]]+)" colour, colour, rvrs_S
	rvrs=str2num(rvrs_S)
	clr_pos=WhichListItem(colour,cTabList())+1
	//Remove auto colour range.
	if(strsearch(imageinfo("",S_value,0),"*",0)>0)
		colour="Grays"
		clr_pos=1
		rvrs=0
		ModifyImage $S_value ctab={V_min,V_max,$colour,rvrs}
		zMaxVal=V_max
		zMinVal=V_min
	endif
	//Define initial range of sliders to largest z value of selected image.
	If(abs(V_min) > abs(V_max))
		absMax = abs(V_min)
	else
		absMax = abs(V_max)
	endif
	PopupMenu colourList title="Colour",value=cTabList(),fSize=12,popValue=colour,proc=cspSldr_colourTab,bodyWidth=150,pos={722,30},mode=clr_pos
	Slider zMax pos={10,10},size={400,20},vert=0,proc=cspSldr_zMax,limits={-2*absMax,2*absMax,0},value=zMaxVal
	Slider zMin pos={10,50},size={400,20},vert=0,proc=cspSldr_zMin,limits={-2*absMax,2*absMax,0},value=zMinVal
	Button killZSliders title="Remove Z Sliders",pos={580,75},size={120,20},proc=cspSldr_killZSliders
	//Button Animate title="Animate",size={80,20},proc=cspSldr_animate
	PopupMenu reverseColours title="Reverse Colours", value="No;Yes",fSize=12,bodyWidth=50,pos={678,50},proc=cspSldr_reverseColours,mode=(rvrs+1)
	SetVariable zMaxRange title="Max Range",proc=cspSldr_zMaxRange,size={150,20},value=_NUM:ceil(2*V_max),fSize=12,pos={410,10}
	SetVariable zMinRange title="Min Range",proc=cspSldr_zMinRange,size={150,20},value=_NUM:ceil(2*V_max),fSize=12,pos={410,50}
End

Function cspSldr_reverseColours(pa) : PopupMenuControl
	Struct WMPopupAction &pa
		switch( pa.eventCode )
			case 2: // mouse up
				Variable popNum = pa.popNum
				String popStr = pa.popStr
				controlInfo colourList
				String clr=S_value
				controlInfo ImageList
				ModifyImage $S_value ctab={,,$clr,popNum-1}
				break
			case -1: // control being killed
				break
			endswitch
			
		return 0
end

Function cspSldr_colourTab(pa) : PopupMenuControl
	Struct WMPopupAction &pa
	
	switch( pa.eventCode )
		case 2: // mouse up
			Variable popNum = pa.popNum
			String popStr = pa.popStr
			ControlInfo reverseColours
			Variable clrRvrs=V_Value-1
			ControlInfo ImageList
			ModifyImage $S_value ctab={,,$popStr,clrRvrs}
			break
		case -1: // control being killed
			break
		endswitch
		
		return 0
end

Function cspSldr_ImageMenu(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa

	switch( pa.eventCode )
		case 2: // mouse up
			Variable popNum = pa.popNum
			String popStr = pa.popStr
			Variable zMaxVal,zMinVal,rvrs,clr_pos,absMax
			String colour, rvrs_S, imageDirectory, popStrNoNum
			sscanf StringFromList(10,imageinfo("",popStr,0)), "RECREATION:ctab= {%f,%f,%s",zMinVal,zMaxVal,colour
			splitString/e="([[:alpha:]]+),([[:digit:]]+)" colour, colour, rvrs_S
			rvrs=str2num(rvrs_S)
			clr_pos=WhichListItem(colour,cTabList())+1
			imageDirectory = GetDataFolder(1,GetWavesDataFolderDFR(ImageNameToWaveRef("",popStr)))
			if(strsearch(popStr,"#",0)<0)
				ImageStats $(imageDirectory+popStr)
			else
				//popStr=popStr[0,strsearch(popStr,"#",0)-1]
				ImageStats $(imageDirectory+popStr[0,strsearch(popStr,"#",0)-1])
			endif
			//Insure a colour table is selected.
			if(strsearch(imageinfo("",popStr,0),"*",0)>0)
				clr_pos = 1
				rvrs=0
				ModifyImage $popStr ctab={V_min,V_max,Grays,0}
				zMaxVal=V_max
				zMinVal=V_min
			endif
			If(abs(V_min) > abs(V_max))
				absMax = abs(V_min)
			else
				absMax = abs(V_max)
			endif
			PopupMenu colourList mode=clr_pos
			PopupMenu reverseColours mode=(rvrs+1)
			Slider zMax value=zMaxVal,limits={-2*absMax,2*absMax,0}
			Slider zMin value=zMinVal,limits={-2*absMax,2*absMax,0}
			SetVariable zMaxRange value=_NUM:ceil(2*V_max)
			SetVariable zMinRange value=_NUM:ceil(2*V_max)
			break
		case -1: // control being killed
			break
	endswitch
	
	return 0
End


Function cspSldr_zMax(sa) : SliderControl
	STRUCT WMSliderAction &sa

	switch( sa.eventCode )
		case -3: // Control received keyboard focus
		case -2: // Control lost keyboard focus
		case -1: // Control being killed
			break
		default:
			if( sa.eventCode & 1 ) // value set
				Variable curval = sa.curval
				//String wname = WaveName("", 0, 1)
				//ModifyImage $wname ctab={,curval,RedWhiteBlue,1}
				ControlInfo ImageList
				ModifyImage $S_value ctab={,curval,}
			endif
			break
	endswitch

	return 0
End

Function cspSldr_zMin(sa) : SliderControl
	STRUCT WMSliderAction &sa

	switch( sa.eventCode )
		case -3: // Control received keyboard focus
		case -2: // Control lost keyboard focus
		case -1: // Control being killed
			break
		default:
			if( sa.eventCode & 1 ) // value set
				Variable curval = sa.curval
				//String wname = WaveName("", 0, 1)
				//ModifyImage $wname ctab={curval,,RedWhiteBlue,1}
				ControlInfo ImageList
				ModifyImage $S_value ctab={curval,,}
			endif
			break
	endswitch

	return 0
End

Function cspSldr_killZSliders(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			KillControl zMax
			KillControl zMin
			ControlBar 0
			KillControl killZSliders
			killControl zMaxRange
			killControl zMinRange
			killControl ImageList
			//killcontrol animate
			killControl colourList
			killControl reverseColours
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function cspSldr_zMaxRange(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva

	switch( sva.eventCode )
		case 1: // mouse up
		case 2: // Enter key
		case 3: // Live update
			Variable dval = sva.dval
			String sval = sva.sval
			ControlInfo zMax
			If(abs(dval) < abs(V_value))
				Slider zMax value=dval,limits={-dval,dval,0}
			else 
				Slider zMax limits={-dval,dval,0}
			endif
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function cspSldr_zMinRange(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva

	switch( sva.eventCode )
		case 1: // mouse up
		case 2: // Enter key
		case 3: // Live update
			Variable dval = sva.dval
			String sval = sva.sval
			ControlInfo zMin
			If(abs(dval) < abs(V_value))
				Slider zMin value=dval,limits={-dval,dval,0}
			else 
				Slider zMin limits={-dval,dval,0}
			endif
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function cspSldr_animate(ba) : ButtonControl
	STRUCT WMButtonAction &ba
	
	switch( ba.eventCode )
		case 2: // mouse up
			Variable mx,mn,newVal
			Variable eggTimer=0
			Variable interval=10 //seconds to complete
			Variable delay=0.25 //time between updates
			ControlInfo zMax
			mx=V_Value
			ControlInfo zMin
			mn=V_Value
			Variable rate=(mx-mn)/interval
			ControlInfo ImageList
			do
				newVal=mn+rate*eggTimer
				Slider zMax value=newVal
				ModifyImage $S_value ctab={,newVal,RedWhiteBlue,1}
				DoUpdate
				eggTimer += delay
				Sleep/s delay
			while(eggTimer < interval)
			ModifyImage $S_value ctab={,mx,RedWhiteBlue,1}
			break
		case -1:  // control being killed
			break
	endswitch
	
	return 0
End

Function scaleSldr_addXSliders()
	ControlBar 100
	Variable mini, maxi, ymini, ymaxi
	Variable x_Min, x_Max, y_Min, y_Max
	GetAxis/Q bottom
	mini = V_min
	maxi = V_Max
	GetAxis/Q left
	ymini = V_min
	ymaxi = V_max
	SetAxis/A
	DoUpdate
	GetAxis/Q bottom
	x_Min = V_min
	x_Max = V_max
	GetAxis/Q left
	y_Min = V_min
	y_Max = V_max
	SetAxis bottom, mini, maxi
	SetAxis left, ymini, ymaxi
	
	DoUpdate
	Slider xMax pos={10,10},size={300,20},vert=0,proc=scaleSldr_xMax,limits={x_Min,x_Max,0},value=maxi,ticks=0
	Slider xMin pos={10,60},size={300,20},vert=0,proc=scaleSldr_xMin,limits={x_Min,x_Max,0},value=mini,ticks=0
	Slider yMax pos={535,10},size={300,20},vert=0,proc=scaleSldr_yMax,limits={0,y_Max,0},value=ymaxi
	Slider yMin pos={535,50},size={300,20},vert=0,proc=scaleSldr_yMin,limits={0,y_Max,0},value=ymini
	Button killXSliders title="X Remove Sliders Y",pos={310,35},size={215,20},proc=scaleSldr_killXSliders
	SetVariable yMaxVal title="yMax",proc=scaleSldr_yMaxVal,size={100,20},value=_NUM:y_Max,fSize=12,pos={835,20}
	SetVariable yMinVal title="yMin",proc=scaleSldr_yMaxVal,size={100,20},value=_NUM:y_Min,fSize=12,pos={835,60}

	variable minYear, minMonth, minDay, minHour, minMin
	variable maxYear, maxMonth, maxDay, maxHour, maxMin
	String minYMD, maxYMD
	minYMD = secs2Date(x_Min,-2,",")
	maxYMD = secs2Date(x_Max,-2,",")
	String expr="([[:digit:]]+),([[:digit:]]+),([[:digit:]]+)"
	String yearString, monthString, dayString
	splitString/E=(expr) maxYMD, yearString, monthString, dayString
	maxYear = str2num(yearString)
	maxMonth = str2num(monthString)
	maxDay = str2num(dayString)
	splitString/E=(expr) minYMD, yearString, monthString, dayString
	minYear = str2num(yearString)
	minMonth = str2num(monthString)
	minDay = str2num(dayString)
	
	minHour = floor((x_Min - date2Secs(minYear,minMonth,minDay))/3600)
	minMin = floor((x_Min - date2Secs(minYear,minMonth,minDay))/60 - minHour*60)
	maxHour = floor((x_Max - date2Secs(maxYear,maxMonth,maxDay))/3600)
	maxMin = floor((x_Max - date2Secs(maxYear,maxMonth,maxDay))/60 - maxHour*60)
	
	SetVariable xMaxYear title="",proc=scaleSldr_xRange,size={55,20}, value=_NUM:maxYear, fSize=12, pos={310,10}
	SetVariable xMaxMonth title="",value=_NUM:maxMonth,fSize=12, pos={365,10},size={40,20},proc=scaleSldr_xRange
	SetVariable xMaxDay title="",value=_NUM:maxDay,fSize=12, pos={405,10},size={40,20},proc=scaleSldr_xRange
	SetVariable xMaxHour title="",value=_NUM:maxHour,fSize=12, pos={445,10},size={40,20},proc=scaleSldr_xRange
	SetVariable xMaxMin title="",value=_NUM:maxMin,fSize=12, pos={485,10},size={40,20},proc=scaleSldr_xRange

	SetVariable xMinYear title="",proc=scaleSldr_xRange,size={55,20}, value=_NUM:minYear, fSize=12, pos={310,60}
	SetVariable xMinMonth title="",value=_NUM:minMonth,fSize=12, pos={365,60},size={40,20},proc=scaleSldr_xRange
	SetVariable xMinDay title="",value=_NUM:minDay,fSize=12, pos={405,60},size={40,20},proc=scaleSldr_xRange
	SetVariable xMinHour title="",value=_NUM:minHour,fSize=12, pos={445,60},size={40,20},proc=scaleSldr_xRange
	SetVariable xMinMin title="",value=_NUM:minMin,fSize=12, pos={485,60},size={40,20},proc=scaleSldr_xRange
End

Function scaleSldr_xRange(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva
	
	switch( sva.eventCode )
		case 2: // Enter key
		case 3: // Live update
			Variable dval = sva.dval
			String sval = sva.sval
			
			controlInfo xMaxYear
			variable maxYear = v_value
			controlInfo xMaxMonth
			variable maxMonth = v_value
			controlInfo xMaxDay
			variable maxDay = v_value
			controlInfo xMaxHour
			variable maxHour = v_value
			controlInfo xMaxMin
			variable maxMin = v_value
			
			controlInfo xMinYear
			variable minYear = v_value
			controlInfo xMinMonth
			variable minMonth = v_value
			controlInfo xMinDay
			variable minDay = v_value
			controlInfo xMinHour
			variable minHour = v_value
			controlInfo xMinMin
			variable minMin = v_value
			
			variable maxRange = date2secs(maxYear,maxMonth,maxDay)+maxHour*3600+maxMin*60
			variable minRange = date2secs(minYear,minMonth,minDay)+minHour*3600+minMin*60
			Slider xMax limits={minRange,maxRange,0}
			Slider xMin limits={minRange,maxRange,0}
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End
		
Function scaleSldr_yMaxVal(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva

	switch( sva.eventCode )
		case 1: // mouse up
		case 2: // Enter key
		case 3: // Live update
			Variable dval = sva.dval
			String sval = sva.sval
			controlInfo yMaxVal
			variable yMax = v_value
			controlInfo yMinVal
			variable yMin = v_value
			Slider yMax limits={yMin,yMax,0}
			Slider yMin limits={yMin,yMax,0}
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function scaleSldr_xMaxVal(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva

	switch( sva.eventCode )
		case 1: // mouse up
		case 2: // Enter key
		case 3: // Live update
			Variable dval = sva.dval
			String sval = sva.sval
			GetAxis/Q left
				Slider xMax value=dval,limits={V_min,dval,0}
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function scaleSldr_xMax(sa) : SliderControl
	STRUCT WMSliderAction &sa

	switch( sa.eventCode )
		case -3: // Control received keyboard focus
		case -2: // Control lost keyboard focus
		case -1: // Control being killed
			break
		default:
			if( sa.eventCode & 1 ) // value set
				Variable curval = sa.curval
				//String wname = WaveName("", 0, 1)
				//ModifyImage $wname ctab={curval,,RedWhiteBlue,1}
				ControlInfo xMin
				SetAxis bottom, V_value, curval
			endif
			break
	endswitch

	return 0
End

Function scaleSldr_xMin(sa) : SliderControl
	STRUCT WMSliderAction &sa

	switch( sa.eventCode )
		case -3: // Control received keyboard focus
		case -2: // Control lost keyboard focus
		case -1: // Control being killed
			break
		default:
			if( sa.eventCode & 1 ) // value set
				Variable curval = sa.curval
				//String wname = WaveName("", 0, 1)
				//ModifyImage $wname ctab={curval,,RedWhiteBlue,1}
				ControlInfo xMax
				SetAxis bottom, curval, V_value
			endif
			break
	endswitch

	return 0
End

Function scaleSldr_yMax(sa) : SliderControl
	STRUCT WMSliderAction &sa

	switch( sa.eventCode )
		case -3: // Control received keyboard focus
		case -2: // Control lost keyboard focus
		case -1: // Control being killed
			break
		default:
			if( sa.eventCode & 1 ) // value set
				Variable curval = sa.curval
				//String wname = WaveName("", 0, 1)
				//ModifyImage $wname ctab={curval,,RedWhiteBlue,1}
				ControlInfo yMin
				SetAxis left, V_value, curval
//				SetAxis right, V_value, curval
			endif
			break
	endswitch

	return 0
End

Function scaleSldr_yMin(sa) : SliderControl
	STRUCT WMSliderAction &sa

	switch( sa.eventCode )
		case -3: // Control received keyboard focus
		case -2: // Control lost keyboard focus
		case -1: // Control being killed
			break
		default:
			if( sa.eventCode & 1 ) // value set
				Variable curval = sa.curval
				//String wname = WaveName("", 0, 1)
				//ModifyImage $wname ctab={curval,,RedWhiteBlue,1}
				ControlInfo yMax
				SetAxis left, curval, V_value
//				SetAxis right, curval, V_value
			endif
			break
	endswitch

	return 0
End
Function scaleSldr_killXSliders(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			KillControl xMax
			KillControl xMin
			KillControl yMax
			KillControl yMin
			
			ControlBar 0
			
			KillControl killXSliders
			
			KillControl yMaxVal
			killControl yMinVal
			
			KillControl xMaxVal
			killControl xMaxYear
			killControl xMaxMonth
			killControl xMaxDay
			killControl xMaxHour
			killControl xMaxMin
			KillControl xMaxVal
			killControl xMinYear
			killControl xMinMonth
			killControl xMinDay
			killControl xMinHour
			killControl xMinMin
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

//To create a set of waves with a sliding normalization between two different filling factors
Function SlidingNormGUI()
//	doAlert/T="Sliding Normalization Notes" 0,"Creates sibling folders to current directory."
	string nuLowWave  = strvarordefault("root:MatthewGlobals:gnuLowWave","")
	string nuHighWave  = strvarordefault("root:MatthewGlobals:gnuHighWave","")
	variable index0 = numvarordefault("root:MatthewGlobals:gindex0",0)
	variable indexf = numvarordefault("root:MatthewGlobals:gindexf",0)
	string zerosQ = strvarordefault("root:MatthewGlobals:gzerosQ","Yes")
	variable numDigits = numvarordefault("root:MatthewGlobals:gnumDigits",3)
	variable slot = numvarordefault("root:MatthewGlobals:gslot",30)
	variable len = numvarordefault("root:MatthewGlobals:glen",2.5)
	variable dens = numvarordefault("root:MatthewGlobals:gdens",5)
	string nameBaseS = strvarordefault("root:MatthewGlobals:gnameBaseS","")
	prompt nuLowWave,"nu = Low Wave"
	prompt nuHighWave,"nu = High Wave"
	prompt index0,"First Index"
	prompt indexf,"Last Index"
	prompt zerosQ,"Preappended Zeros?",popup("Yes;No")
	prompt numDigits,"Number of Digits"
	prompt slot,"Slot Width (μm)"
	prompt len,"Slot length (mm)"
	prompt dens,"Density (10^14 cm^-2)"
	prompt nameBaseS,"Base :Directory:Name"
	doPrompt "Sliding Complex Normalization",nuLowWave,nuHighWave,index0,indexf,zerosQ,numDigits,slot,len,dens,nameBaseS
	
	string/g root:MatthewGlobals:gnuLowWave = nuLowWave
	string/g root:MatthewGlobals:gnuHighWave = nuHighWave
	variable/g root:MatthewGlobals:gindex0 = index0
	variable/g root:MatthewGlobals:gindexf = indexf
	string/g root:MatthewGlobals:gzerosQ = zerosQ
	variable/g root:MatthewGlobals:gnumDigits = numDigits
	variable/g root:MatthewGlobals:gslot = slot
	variable/g root:MatthewGlobals:glen = len
	variable/g root:MatthewGlobals:gdens = dens
	string/g root:MatthewGlobals:gnameBaseS = nameBaseS
		
	If(v_flag)
		return -1
	endif
	
	SlidingNormGUI2()
	
end

Function SlidingNormGUI2()
	variable nuLow = numvarordefault("root:MatthewGlobals:gnuLow",1)
	variable nuHigh = numvarordefault("root:MatthewGlobals:gnuHigh",2)
	string initNu = strvarordefault("root:MatthewGlobals:ginitNu","Filling")
	variable nuX0 = numvarordefault("root:MatthewGlobals:gnuX0",1)
	variable nuStep = numvarordefault("root:MatthewGlobals:gnuStep",0.01)
	prompt nuLow, "ν Low"
	prompt nuHigh, "ν High"
	prompt initNu,"Wave step in Filling or 1/B?", popup("Filling;1/B")
	prompt nuX0, "Initial Filling or 1/B"
	prompt nuStep, "Step size in filling or 1/B"
	doPrompt "Sliding Normalization",nuLow,nuHigh,initNu,nuX0,nuStep
	
	variable/g root:MatthewGlobals:gnuLow = nuLow
	variable/g root:MatthewGlobals:gnuHigh = nuHigh
	String/g root:MatthewGlobals:ginitNu = initNu
	variable/g root:MatthewGlobals:gnuX0 = nuX0
	variable/g root:MatthewGlobals:gnuStep = nuStep
	
	If(v_flag)
		return -1
	endif
	
	SlidingNorm()
end

Function SlidingNorm()
	variable iter = 0
	nvar index0 = root:MatthewGlobals:gindex0
	nvar indexf = root:MatthewGlobals:gindexf
	svar nuLowString = root:MatthewGlobals:gnuLowWave
	svar nuHighstring = root:MatthewGlobals:gnuHighWave
	wave/c nuLowW = $nuLowString
	wave/c nuHighW = $nuHighString
	svar zerosQ = root:MatthewGlobals:gzerosQ
	nvar numDigits = root:MatthewGlobals:gnumDigits
	nvar slot = root:MatthewGlobals:gslot
	nvar len = root:MatthewGlobals:glen
	nvar dens = root:MatthewGlobals:gdens
	svar nameBase = root:MatthewGlobals:gnameBaseS
	svar initNu = root:MatthewGlobals:ginitNu
	nvar nuX0 = root:MatthewGlobals:gnuX0
	nvar nuStep = root:MatthewGlobals:gnuStep
	nvar nuHigh = root:MatthewGlobals:gnuHigh
	nvar nuLow = root:MatthewGlobals:gnulow

	variable h = 6.62607004e-34
	variable ele = 1.60217662e-19
	variable nu
	String index
	variable sigConv = -1e6*(slot*1e-6/(50*len*1e-3))  //uS
	
	//Make some data folders to store the waves
	if(DatafolderExists("nsc") == 0)
		newdatafolder :nsc
	endif
	if(datafolderexists("nsSig") == 0)
		newdatafolder :nsSig
	endif
	
	for(iter=index0;iter<=indexf;iter++)
		//Calculate nu for the wave to normalized.
		if(!cmpstr(initNu,"1/B",2))
			nu = dens*1e14*h*(nuX0+nustep*iter)/ele
		else
			nu = nuX0+nustep*iter
		endif
		nu = round(nu*1000)/1000
		
		//Preappended 0s
		index=preAppendZeros(num2str(iter), numDigits=numDigits)
//		index=num2str(iter)
//		if(strlen(index)<numDigits)
//			do
//				index = "0" + index
//			while(strlen(index)<numDigits)
//		endif
		
		//Make the normalized complex wave
		duplicate/o/c $(nameBase+index) $(":nsc:nsc_"+index)
		wave/c normMe = $(":nsc:nsc_"+index)
		normMe /=((nuHigh-nu)*nuLowW+(nu-nuLow)*nuHighW)
		
		//Make the normalized conductivity wave, also complex
		duplicate/o/c normMe $(":nsSig:nsCS_"+index)
		wave/c sig = $(":nsSig:nsCS_"+index)
		sig = sigConv*cmplx(ln(cabs(normMe)),atan2(Imag(normMe),real(normMe)))
	endfor
end

//Unfinished code for loading Helium 3 temperatures.
//Worked, but do not remember how I ran it, likely from command line?
Function LoadTemperaturesHe3()
	svar gDStamp
	svar gBoolLoadF
	svar	gTPath
	svar gTName
	svar gFPath
	svar gFName
	
	variable int //My index counter
	string killString
	
	//Load Temperature Files
	LoadWave/Q/J/K=0/A=dataRaw/P=$gTPath gTName
	wave dataRaw1
	wave dataRaw2
	wave dataRaw3
	wave dataRaw4
	wave dataRaw5

	//Rename and cleanup unused temperature waves
	string He3n = "He3" + gdStamp
	string oneKn = "oneK" + gdStamp
	string He3HighTn = "He3HighT" + gdStamp
	string Sorbn = "Sorb" + gdStamp
	string Dn = "D" + gdStamp
	duplicate/O dataRaw1 $He3n
	duplicate/O dataRaw2 $oneKn
	duplicate/O dataRaw3 $Sorbn
	duplicate/O dataRaw4 $He3HighTn
	duplicate/O dataRaw5 $Dn
	
	for(int = 0; int <= 5; int+=1)
		killString = "dataRaw" + num2str(int)
		if(exists(killString) == 1)
			killwaves $killString
		endif
	endfor
	
	//Load Temperature Data
	wave He3 = root:$He3n
	wave oneK = root:$oneKn
	wave He3HighT = root:$He3HighTn
	wave Sorb = root:$sorbn
	wave D = root:$Dn
	string wName = "Temperatures" + gdStamp
	string wTitle = "Temperatures " + gdStamp
	
	//Load data times waves
	if(!cmpstr(gboolLoadF, "Yes",2))
		LoadWave/J/D/W/A/O/K=0/L={0,1,0,0,3}/P=$gfPath gfName
//		LoadWave/O/A/J/K=0/L={1,2,0,1,3}/P=$gfPath gfName
		String fNames = "dataName" + gdStamp
		String dataStart = "dataStart" + gdStamp
		String dataStop = "dataStop" + gdStamp
		wave File=root:File
		wave tStart=root:tStart
		wave tStop=root:tStop
		duplicate/t/O File $fNames
		duplicate/O tStart $dataStart
		duplicate/O tStop $dataStop
					
//	for(int = 0; int <= 16; int+=1)
//		killString = "dataRaw" + num2str(int)
//		if(exists(killString) == 1)
//			killwaves $killString
//		endif
//	endfor
		
		//Load data times waves
		wave startW = root:$dataStart
		wave stopW = root:$dataStop
		wave/t fNamesW = root:$fNames
		
		//Create wave for displaying on graph
		String fValS = fNames + "S"
		String fValSE = fNames + "E"
		print fvals
		print fvalse
		make/o/n=(numpnts(fNamesW)) $fValS
		make/o/n=(numpnts(fNamesW)) $fValSE
		wave fValW = $fValS
		wave fValE = $fValSE
		variable mkrHeight = 2		
		variable/g gmkrVal = mkrHeight
		fValW = gmkrVal
		fValE = gmkrVal
	endif
	//Display Temperature Data
	string displayName = wName
	display/n=$wName He3HighT vs D as displayName
	appendtograph oneK vs D
	appendtograph Sorb vs D
	appendtograph He3 vs D
	//Adds data names and control bar for maker height
	if(!cmpstr(gboolLoadF, "Yes",2))
		//ControlBar 35 //Want to make variable marker height
		appendtograph fValW vs startW
		appendtograph fValE vs stopW
		ModifyGraph mode($fValS)=8,rgb($fValS)=(0,0,65535)
		ModifyGraph textMarker($fValS)={$fNames,"default",0,0,1,0.00,0.00}
		ModifyGraph mode($fValSE)=1,marker($fValSE)=10
	endif
	//DoWindow/T $wName, wTitle
	ModifyGraph lsize=2,rgb($He3n)=(0,0,65535),rgb($oneKn)=(2,39321,1)
	ModifyGraph rgb($sorbn)=(0,0,0)
	Legend/C/N=text0/J/F=0/H={0,5,10}/B=1 "\\s("+sorbn+") "+sorbn+"\r\\s("+oneKn+") "+ oneKn+"\r\\s("+He3HighTn+") "+He3HighTn+"\r\\s("+He3n+") "+He3n
//	Legend/C/N=text0/F=0/H={0,5,10}/A=MC/B=1
	SetAxis left 0,6
	Label left "Kelvin"
	Label bottom "Time"
	ModifyGraph grid(bottom)=2,tick=2,mirror=1,standoff=0
	ModifyGraph manTick(bottom)={3600,1,0,0,hr},manMinor(bottom)={3,2}
end

//Looks like old code I was going to use for changing startLevel value on temperature graph
//Commented out as, clearly, I only just started it.
//Function mkrFunc(ctrlName):SetVariableControl
//	String ctrlName
//	ControlInfo mkrHeight
//	print v_value
////	wave fValW = root:$S_Value
////	fValW = V_Value
//	
//end	

Function LoadTemperaturesHe3GUI()
	String dStamp = strvarordefault("gDStamp", "")
	String boolLoadF = strvarordefault("gBoolLoadF", "No")
	String tPath = strvarordefault("gTPath", "")
	String tName = strvarordefault("gTName", "")
	String fPath = strvarordefault("gFPath", "")
	String fName =strvarordefault("gFName", "")	
	prompt dStamp, "Date Stamp"
	prompt boolLoadF, "Load Data Time File?", popup "Yes;No"
	prompt tPath, "Path to Temperature Data File"
	prompt tName, "Name of Temperature Data File"
	prompt fPath, "Path to Data Time File"
	prompt fName, "Name of Data Time File"
	DoPrompt "Load Temperature Files", dStamp, boolLoadF, tPath, tName, fPath, fName
	
	If(v_flag)
		return -1
	endif
	
	//Set Globals for Future Use
	String/g gDStamp = dStamp
	String/g gBoolLoadF = boolLoadF
	String/g gTPath = tPath
	String/g gTName = tName
	String/g gFPath = fPath
	String/g gFName = fName
	
	//Call function to load everything
	LoadTemperaturesHe3()
end

Function LS211GUI()
	String LSName = strvarordefault("root:MatthewGlobals:gLSName", "")
	String LSPath	= strvarordefault("root:MatthewGlobals:gLSPath", "")
	String LSGraph = strvarordefault("root:MatthewGlobals:gLSGraph", "Yes")
	Prompt LSPath, "Path"
	Prompt LSName, "Name of File"
	Prompt LSGraph, "Display Graph", popup "Yes;No"
	DoPrompt "Load LS211 Temperature File", LSPath, LSName, LSGraph

	If(v_flag)
		return -1
	endif

	//Checking for MatthewGlobals folder
	If(DataFolderExists("root:MatthewGlobals") == 0)
		NewDataFolder root:MatthewGlobals
	endif
	
	String/g root:MatthewGlobals:gLSName = LSName
	String/g root:MatthewGlobals:gLSPath = LSPath
	String/g root:MatthewGlobals:gLSGraph = LSGraph

	LS211()
end

Function LS211()
	svar LSPath = root:MatthewGlobals:gLSPath
	svar LSName = root:MatthewGlobals:gLSName
	svar LSGraph = root:MatthewGlobals:gLSGraph
	//Check for RBridge folder
	If(DataFolderExists(":LS211") == 0)
		NewDataFolder :LS211
	endif
	cd :LS211
	LoadWave/Q/O/J/D/W/K=0/V={","," $",0,0}/R={English,2,2,2,2,"Year/Month/DayOfMonth",40}/N=LS211/P=$LSPath LSName
	wave LS2110=LS2110
	wave LS2111=LS2111
	duplicate/O LS2110 LS211Date
	duplicate/O LS2111 LS211Kelvin
	killwaves LS2110, LS2111
	If(!cmpstr(LSGraph,"Yes",2))
		wave LS211Kelvin = LS211Kelvin
		wave LS211Date = LS211Date
		Display LS211Kelvin vs LS211Date
		ModifyGraph grid(bottom)=2,tick=2,mirror=1
		Label bottom "Time and Date"
		Label left "Kelvin"
		ModifyGraph lsize=3
		//TextBox/C/N=text0/F=0/B=1/A=LC LSName
	endif
	cd ::
	Print "***************************"
	Print "Loaded LS211 Temperature"
	Print "***************************"
end

//Sonnet, sadly, dumps multi-trace data in two columns with a space after each trace.
//Igor is less than agreeable to this, Igor likes different trace, different column(s).
//So I use FReadLine to grab data one line at a time and split up each trace into waves.
Function loadSonnetGUI()
	String pathSonFile = strvarordefault("root:MatthewGlobals:gpathSonFile","")
	String sonFileName = strvarordefault("root:MatthewGlobals:gsonFileName","")
	Variable uS0 = numvarordefault("root:MatthewGlobals:guS0", 0)
	Variable uSStep = numvarordefault("root:MatthewGlobals:guSStep", 1)
	Variable numWave = numvarordefault("root:MatthewGlobals:gnumWave", 10)
	Variable pnts = numvarordefault("root:MatthewGlobals:gpnts", 200)
	Prompt pathSonFile, "Path to Sonnet File"
	Prompt sonFileName, "Name of Sonnet File"
	Prompt uS0, "First Conductivity (uS)"
	Prompt uSStep, "Step Size (uS)"
	Prompt numWave, "Number of Waves in File"
	Prompt pnts, "Number of Points per Wave"
	doPrompt "Load from Sonnet File",pathSonFile,sonFileName,pnts,uS0,uSStep,numWave
	
	if(v_flag)
		return	-1
	endif
		
	//Checking for MatthewGlobals folder
	If(DataFolderExists("root:MatthewGlobals") == 0)
		NewDataFolder root:MatthewGlobals
	endif
	
	String/g root:MatthewGlobals:gpathSonFile = pathSonFile
	String/g root:MatthewGlobals:gsonFileName = sonFileName
	Variable/g root:MatthewGlobals:gpnts = pnts
	Variable/g root:MatthewGlobals:guS0 = uS0
	Variable/g root:MatthewGlobals:guSStep = uSStep
	Variable/g root:MatthewGlobals:gnumWave = numWave
	
	loadSonnet()

end

Function loadSonnet()
	svar pathSonFile = root:MatthewGlobals:gpathSonFile
	svar sonFileName = root:MatthewGlobals:gsonFileName
	nvar pnts = root:MatthewGlobals:gpnts
	nvar uS0 = root:MatthewGlobals:guS0
	nvar uSStep = root:MatthewGlobals:guSStep
	nvar numWave = root:MatthewGlobals:gnumWave
	
	Variable refNum, iterWave,iterPnts
	Variable lineNum = 3
	String lineStr = ""
	String uS
	Variable freq, dB
	
	Open/R/P=$pathSonFile refNum as sonFileName
	
	for(iterWave=0;iterWave<numWave;iterWave++)
		FReadLine refNum, lineStr //Skip Header Line 1
		FReadLine refNum, lineStr //Skip Header Line 2
		
		//Current uS
		uS = num2str(uS0+uSStep*iterWave)
		//I do like preappended 0s.
		if(strlen(uS)<4)
			do
				uS = "0"+uS
			while(strlen(uS)<4)
		endif
		
		//Make new wave to hold data and load it.
		make/o/n=(pnts) $("MOS_"+uS)
		wave dataWave = $("MOS_"+uS)
		setscale/p x 0.1,0.1,"dB",dataWave //Set the scale.
		
		//Read data into wave "pnts" number of lines.
		for(iterPnts=0;iterPnts<pnts;iterPnts++)
			FReadLine refNum, lineStr
			sscanf lineStr, "%f,%f", freq, dB
			dataWave[iterPnts] = dB
		endfor

		//Skip blank line at end of data.
		FReadLine refNum, lineStr
	endfor
	Close refNum
end

Function difSolvHypWaveGUI()
	String RccW = strvarordefault("root:MatthewGlobals:gRccW","")
	String RcgW = strvarordefault("root:MatthewGlobals:gRcgW","")
	Variable Xmin = numvarordefault("root:MatthewGlobals:gXmin",50)
	Variable Xmax = numvarordefault("root:MatthewGlobals:gXmax",200)
	Variable dX = numvarordefault("root:MatthewGlobals:gdX",0.00001)
	Variable len = numvarordefault("root:MatthewGlobals:glen",0.0025)
	Prompt RccW, "Rcc"
	Prompt RcgW, "Rcg"
	Prompt Xmin, "Xmin"
	Prompt Xmax, "Xmax"
	Prompt dX, "dX"
	Prompt len, "Length"
	DoPrompt "Solve Hyperbolic for Waves",RccW,RcgW,Xmin,Xmax,dX,len
		
	If(v_flag)
		return -1
	endif
	
	If(DataFolderExists("root:MatthewGlobals") == 0)
		NewDataFolder root:MatthewGlobals
	endif
	
	String/g root:MatthewGlobals:gRccW = RccW
	String/g root:MatthewGlobals:gRcgW = RcgW
	Variable/g root:MatthewGlobals:gXmin = Xmin
	Variable/g root:MatthewGlobals:gXmax = Xmax
	Variable/g root:MatthewGlobals:gdX = dX
	Variable/g root:MatthewGlobals:glen = len
	
end

Function difSolvHypWave()
	svar RccS = root:MatthewGlobals:gRccW
	svar RcgS = root:MatthewGlobals:gRcgW
	wave RccW = $(RccS)
	wave RcgW = $(RcgS)
	nvar Xmin = root:MatthewGlobals:gXmin
	nvar Xmax = root:MatthewGlobals:gXmax
	nvar dX = root:MatthewGlobals:gdX
	nvar len = root:MatthewGlobals:glen
	Variable i
	Variable RccCoth, RcgTanh
	Variable diff, minX, minDif, Z0, G, R
	Variable Rcc, Rcg, iter2
	duplicate/o RccW $(RccS+"_Z0")
	duplicate/o RccW $(RccS+"_R")

	For(iter2=0;iter2<numpnts(RccW);iter2+=1)
		Rcc = RccW[iter2]
		Rcg = RcgW[iter2]	
		For(i=Xmin;i<Xmax;i+=dX)
				RccCoth = Rcc/tanh(i*len/2)
				RcgTanh = 2*Rcg*tanh(i*len)
				diff = abs(RccCoth-RcgTanh)
				If(i == Xmin)
					minX = i
					minDif = diff
				elseif(diff < minDif)
					minX = i
					minDif = diff
				endif
		endfor
	endfor
	
	Z0 = Rcg*tanh(minX*len)
	R = minX*Z0
	G = minX/Z0
	Print (num2str(Rcc/tanh(minX*len))+" - "+num2str(2*Rcg*tanh(minX*len/2))+ " = "+num2str(minDif))
	Print ("X = "+num2str(minX))
	Print ("Z0(Ohms) = "+num2str(Z0))
	Print ("R(1/m) = "+num2str(R))
	Print ("G(1/m) = "+num2str(G))
	Print ("R(1/sq) = "+num2str(R*75e-6))
	Print ("G(1/sq) = "+num2str(G*2*50e-6))
end

Function difSolvHypGUI()
	Variable Rcc = numvarordefault("root:MatthewGlobals:gRcc",0)
	Variable Rcg = numvarordefault("root:MatthewGlobals:gRcg",0)
	Variable Xmin = numvarordefault("root:MatthewGlobals:gXmin",0)
	Variable Xmax = numvarordefault("root:MatthewGlobals:gXmax",0)
	Variable dX = numvarordefault("root:MatthewGlobals:gdX",0)
	Variable len = numvarordefault("root:MatthewGlobals:glen",100)
	Prompt Rcc, "Rcc"
	Prompt Rcg, "Rcg"
	Prompt Xmin, "Xmin"
	Prompt Xmax, "Xmax"
	Prompt dX, "dX"
	Prompt len, "Length"
	DoPrompt "Solve Hyperbolic",Rcc,Rcg,Xmin,Xmax,dX,len
		
	If(v_flag)
		return -1
	endif
	
	If(DataFolderExists("root:MatthewGlobals") == 0)
		NewDataFolder root:MatthewGlobals
	endif
	
	Variable/g root:MatthewGlobals:gRcc = Rcc
	Variable/g root:MatthewGlobals:gRcg = Rcg
	Variable/g root:MatthewGlobals:gXmin = Xmin
	Variable/g root:MatthewGlobals:gXmax = Xmax
	Variable/g root:MatthewGlobals:gdX = dX
	Variable/g root:MatthewGlobals:glen = len
	
	difSolvHyp()

end

Function difSolvHyp()
	nvar Rcc = root:MatthewGlobals:gRcc
	nvar Rcg = root:MatthewGlobals:gRcg
	nvar Xmin = root:MatthewGlobals:gXmin
	nvar Xmax = root:MatthewGlobals:gXmax
	nvar dX = root:MatthewGlobals:gdX
	nvar len = root:MatthewGlobals:glen
	Variable i
	Variable RccCoth, RcgTanh
	Variable diff, minX, minDif, Z0, G, R
	
	For(i=Xmin;i<Xmax;i+=dX)
			RccCoth = Rcc/tanh(i*len/2)
			RcgTanh = 2*Rcg*tanh(i*len)
			diff = abs(RccCoth-RcgTanh)
			If(i == Xmin)
				minX = i
				minDif = diff
			elseif(diff < minDif)
				minX = i
				minDif = diff
			endif
	endfor
	Z0 = Rcg*tanh(minX*len)
	R = minX*Z0
	G = minX/Z0
	Print (num2str(Rcc/tanh(minX*len))+" - "+num2str(2*Rcg*tanh(minX*len/2))+ " = "+num2str(minDif))
	Print ("X = "+num2str(minX))
	Print ("Z0(Ohms) = "+num2str(Z0))
	Print ("R(1/m) = "+num2str(R))
	Print ("G(1/m) = "+num2str(G))
	Print ("R(1/sq) = "+num2str(R*75e-6))
	Print ("G(1/sq) = "+num2str(G*2*50e-6))
end

//Returns string of form 0012, 015, etc.
//Default is 3 digits.  Returns 1 and 2 digit numbers unchanged.
//If indexStr.len < numDigits, returns unchanged.
Function/S preAppendZeros(indexStr, [numDigits])
	string indexStr
	variable numDigits
	
	//Default state is 3 digits.
	If(paramIsDefault(numDigits))
		numDigits = 3
	endif

	//For giggles, let's do this with recursion.
	If(strlen(indexStr) < numDigits)
		return preAppendZeros("0"+indexStr, numDigits=numDigits)
	else
		Return indexStr
	endif
end
