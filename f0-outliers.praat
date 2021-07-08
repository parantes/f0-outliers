# f0_outliers.praat
# -----------------
#
# Pablo Arantes <pabloarantes@protonmail.com>
# = Purpose =
# Identify extreme values in Pitch objects.
#
# = How it works =
# Given two consecutive f0 values, the second is flagged as a potential
# f0 extraction error if two condition are met:
# 1. f0 excursion size (measured in octaves) is greater than a value
#    defined by the user;
# 2. the two values are separated in time by less than a value (measured
#    in seconds) defined by the user.
#
#
# created: 2018-06-28

form Find outliers in Pitch objects
	comment "Single file": a Pitch object must be selected from the Objects list.
	comment "Multiple files": user provides a folder containing Pitch files.
	comment Directory containing Pitch files:
	sentence Folder /path/to/picth/
	choice Mode: 1
		button Multiple files
		button Single file
	real Excursion_size_(octaves) 0.6
	real Excursion_time_(s) 0.1
	boolean Create_F0_velocity_PitchTier 1
endform

# Rename GUI variables
size = excursion_size
time = excursion_time

if mode = 1
	# Multiple files mode
	list = Create Strings as file list: "fileList", folder$ + "*.Pitch"
	files = Get number of strings
	if files < 1
		exitScript: "Found no Pitch files at ", folder$, "."
	endif
else
	# Single file mode
	files = 1
	sel =  numberOfSelected()
	if sel <> 1
		exitScript: "Select just one Pitch object."
	else
		sel$ = selected$()
		sel$ = extractWord$(sel$, "")
		if sel$ <> "Pitch"
			exitScript: "Select a Pitch object from the Objects list"
		else
			pitch = selected("Pitch")
		endif
	endif
endif

# Process all files in file list
for file to files
	if mode = 1
		selectObject: list
		file$ = Get string: file
		pitch = Read from file: folder$ + file$
	endif

	# Pitch object name
	sel$ = selected$("Pitch")

	# PitchTier information
	ptier = Down to PitchTier
	points = object[ptier].nx
	start = object[ptier].xmin
	end = object[ptier].xmax

	# Suspect values counter
	suspects = 0

	for point to (points - 1)
		# Excursion size
		f_cur = object[ptier, point + 1]
		f_prev = object[ptier, point]

		# Excursion time
		selectObject: ptier
		t_cur = Get time from index: point + 1
		t_prev = Get time from index: point

		# Delta f0
		df[point] = log2(f_cur) - log2(f_prev)

		# Delta time
		dt[point] = t_cur - t_prev

		# Running time
		running[point] = t_cur

		# Suspect values
		if (abs(df[point]) > size) and (dt[point] < time)
			suspects += 1
			size[suspects] = df[point]
			exc_dur[suspects] = dt[point]
			time[suspects] = running[point]
		endif
	endfor


	# Create TextGrid where suspect values are marked if they exist
	if suspects >= 1
		outliers = Create TextGrid: start, end, "suspects", "suspects"
		for s to suspects
			Insert point: 1, time[s], "s " + fixed$(size[s], 2) + newline$ +
			... "t " + fixed$(exc_dur[s], 3) + newline$ +
			... "v " + fixed$(size[s] / exc_dur[s], 2)
		endfor
		if mode = 1
			Save as text file: folder$ + sel$ + "_out.TextGrid"
		endif
		if mode = 1
			removeObject: outliers
		endif
	endif

	# Create delta F0 PitchTier if this option is selected
	if create_F0_velocity_PitchTier = 1
		# Erase PitchTier content
		selectObject: ptier
		Remove points between: start, end
		# Add f0 velocity points
		for point to (points - 1)
			Add point: running[point], abs(df[point])
		endfor
		if mode = 1
			Save as text file: folder$ + sel$ + ".PitchTier"
			removeObject: ptier
		endif
	else
		removeObject: ptier
	endif

	# Inform user about the number of suspected outliers
	if mode = 1
		removeObject: pitch
	else
		writeInfo: ""
		appendInfoLine: "Found ", suspects, " suspect values on ", sel$, "."
		appendInfoLine: "---"
	endif

endfor

if mode = 1
	removeObject: list
	writeInfo: ""
endif
appendInfoLine: "Run on ", date$()
