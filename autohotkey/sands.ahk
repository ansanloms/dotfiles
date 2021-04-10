; https://edvakf.hatenadiary.org/entry/20101027/1288168554
; https://blog.phoshigaki.net/2018/10/usautohotkeyscripts.html

*Space::
	if (isSpaceRepeat == true){
		if (A_PriorKey != "Space"){
			KeyWait, Space
			SendInput {Shift Up}
			isSpaceRepeat := false
		}

		Return
	}

	SendInput {Shift Down}
	isSpaceRepeat := true

	Return

*Space Up::
	SendInput {Shift Up}
	isSpaceRepeat := false
	if (A_PriorKey == "Space") {
		SendInput {Space}
	}

	Return
