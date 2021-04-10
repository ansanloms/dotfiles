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

	if (IME_GET()) {
		SendInput {Shift Down}
		isSpaceRepeat := true
	} else {
		Send {Space}
	}

	Return

*Space Up::
	if (IME_GET()) {
		SendInput {Shift Up}
		isSpaceRepeat := false
		if (A_PriorKey == "Space") {
			SendInput {Space}
		}
	}

	Return
