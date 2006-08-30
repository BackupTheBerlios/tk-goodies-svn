# Copyright (c) 2006:
#
# Matteo 'bugant' Centenaro <bugant@users.berlios.de>
#
#  All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
# 3. Neither the name of the project nor the names of its contributors
#    may be used to endorse or promote products derived from this software
#    without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE PROJECT AND CONTRIBUTORS ``AS IS'' AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED.  IN NO EVENT SHALL THE PROJECT OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
# OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
# HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
# LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
# OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
# SUCH DAMAGE.

package require icons

namespace eval ::dialogs {
	variable version 0.1

	variable iconsTheme "Tango"
	variable infoFont [list lucidasans 10]
	variable alertFont [list lucidasans 12 bold]

	variable alertIconSize "64x64"
	variable alertBtnSize "22x22"

	# dialogs' type:
	#    [list value "icon name"]
	# alert dialogs
	variable typeAlertError [list 0 "dialog_error"]
	variable typeAlertWarning [list 1 "dialog_warning"]
	variable typeAlertInfo [list 2 "dialog_information"]
	variable typeAlertQuestion [list 3 "dialog_question"]
	variable typeAlertAuth [list 4 "dialog_password"]
}

package provide dialogs $::dialogs::version

# ::dialogs::setIconsTheme set the icons'
# theme to be used on alerts window
#
# @param theme the theme to be used
proc ::dialogs::setIconsTheme {theme} {
	set ::dialogs::iconsTheme $theme
}

# ::dialogs::getIconsTheme get the current
# icons' theme.
#
# @return returns the currently used icons theme
proc ::dialogs::getIconsTheme {} {
	return $::dialogs::iconsTheme
}

# ::dialogs::alert build a modal alert dialog
# window and pop it out setting a local grab.
#
# @param w window's name
# @param title window's title
# @param type window's type (on of ::dialogs::typeAlert*)
# @param btSel default button to be selected
# @params buttons array describing buttons you'd like
#	to display. Array's keys is the each button's position
#	index (0 is the left most one) and each element is
#	a list containint button's text and icons.
# @param alertTxt this is the alert message you want to
#	have to the user. It's emphasized (bold) system font,
#	provides a short, simple summary of the error or condition
#	that summoned the alert.
# @param infoTxt [optional] informative text appears in a smaller font
#	and provides a fuller description of the situation, its
#	consequences, and ways to get out of it.
# @return Returns selected button's value (i.e. its index).
proc ::dialogs::alert {w type btSel buttons alertTxt {infoTxt ""}} {
	catch {destroy $w}
	set focus [focus]
	set grab [grab current .]

	array set btsa $buttons

	toplevel $w -relief solid -class TkSDialog
	wm title $w ""
	wm iconname $w ""
	wm protocol $w WM_DELETE_WINDOW {#}
	wm transient $w [winfo toplevel [winfo parent $w]]

	set typeValue [lindex $type 0]
	set typeIcon [lindex $type 1]

	::icons::init $::dialogs::iconsTheme
	::icons::createImage $typeIcon $::dialogs::alertIconSize

	set ico [label $w.ico -image $typeIcon]
	set aTxt [message $w.altxt -font $::dialogs::alertFont -text $alertTxt -width 384]
	set iTxt [message $w.intxt -font $::dialogs::infoFont -text $infoTxt -width 384]

	set bts [frame $w.bts]

	foreach val [lsort [array names btsa]] {
		set curr $btsa($val)
		set txt [lindex $curr 0]
		set icoName [lindex $curr 1]

		if {$icoName ne ""} {
			::icons::createImage $icoName $::dialogs::alertBtnSize
		}

		set bt [button $bts.bt$val -text $txt -compound left \
			-command "\
				set ::dialogs::ret $val;\
				destroy $w\
			"
		]

		if {$icoName ne ""} {
			$bt configure -image $icoName
		}

		bind $bt <Return> {%W invoke}
		grid $bt -column $val -row 0 -padx [list 12 0] -sticky se

		if {$icoName eq ""} {
			grid configure $bt -sticky nse
		}
	}
	grid columnconfigure $bts 0 -weight 1

	# grid elements following guidilens
	# from Apple HIG:
	# http://developer.apple.com/documentation/UserExperience/Conceptual/OSXHIGuidelines/index.html

	grid $ico $aTxt
	grid ^ $iTxt
	grid $bts - -sticky news

	grid configure $ico -padx [list 24 8] -pady 15 -sticky n
	grid configure $aTxt -padx [list 8 24] -pady [list 15 4] -sticky w
	grid configure $iTxt -padx [list 8 24] -pady [list 4 5] -sticky w
	grid configure $bts -padx 24 -pady [list 5 20]

	wm withdraw $w
	update idletasks

	# center the window

	set parent [winfo parent $w]
	set width [winfo reqwidth $w]
	set height [winfo reqheight $w]
	set x [expr { ( [winfo x $parent] + ([winfo reqwidth  $parent] / 2)  - ($width   / 2)) }]
	set y [expr { ( [winfo y $parent] + ([winfo reqheight $parent] / 2)  - ($height /  2)) }]
	if {$y <= 0} {
		set y [winfo y $parent]
	}
	wm geometry $w +${x}+${y}
	update

	wm deiconify $w
	wm resizable $w false false
	tkwait visibility $w
	focus -force $w
	grab $w

	tkwait window $w
	
	focus -force $focus
	if {$grab ne ""} {grab $grab}
	update idletasks

	return $::dialogs::ret
}

# ::dialog::error display an error alert when a
# user-requested operation cannot be sucessfully
# completed.
# By default it contains an
# error icon, an alert message and its details
# and an ok button (button's text will be translated
# using mc if available).
#
# @param parent dialog's parent window
# @param alertMsg short simple summary of the error
# @param infoMsg [optional] complete error mesagge and information
#	on how to get out of it
# @param buttons [optional] buttons to be displayed in the dialog;
#	by default only one button will be shown (Ok) but you can ovveride
#	this by providing your own configuration (see ::dialogs::alert
#	for detailed info on how to configure buttons).
# @return returns selected button's index.
proc ::dialogs::error {parent alertMsg {infoMsg ""} {buttons ""}} {
	set now [clock seconds]
	if {$parent ne "."} {set parent "$parent."}
	set w $parent$now

	# try to respect i18n, if possible
	if {[catch {set btTxt [mc "Ok"]}]} {
		set btTxt "Ok"
	}

	if {$buttons ne ""} {
		if {[catch {array set bts $buttons}]} {
			set buttons ""
		}
	}

	# error will show only an
	# Ok button by default
	if {$buttons eq ""} {
		array set bts [list]
		set btok [list $btTxt "ok"]
		set bts(0) $btok
	}

	return [::dialogs::alert $w $::dialogs::typeAlertError 0 [array get bts] \
		$alertMsg $infoMsg]
}

# ::dialog::warning present a confirmation alert when the
# user's command may destroy their data, create a security
# risk or such.
# By default it contains a warning icon, an alert message,
# its details and two buttons: cancel and ok (ok button's
# text will be provided by the user, if the user dosen't specify it
# ok will be used, as for ::dialogs::error mc will used
# to translate "fixed" (i.e. not provided by the user) 
# text buttons).
#
# @param parent dialog's parent window
# @param alertMsg short simple summary of the error
# @param infoMsg [optional] complete error mesagge and information
#	on how to get out of it
# @param okTxt [optional] ok button's text, please provide a verb
#	or a short verb phrase describing the action to be confirmed;
# @param buttons [optional] buttons to be displayed in the dialog;
#	by default two buttons will be shown (Cencel and Ok) but you can ovveride
#	this by providing your own configuration (see ::dialogs::alert
#	for detailed info on how to configure buttons). On using this
#	you'll invalidate any okTxt parameter.
# @return returns selected button's index.
proc ::dialogs::warning {parent alertMsg {infoMsg ""} {okTxt ""} {buttons ""}} {
	set now [clock seconds]
	if {$parent ne "."} {set parent "$parent."}
	set w $parent$now

	if {$buttons ne ""} {
		if {[catch {array set bts $buttons}]} {
			set buttons ""
		}
	}

	if {$buttons eq ""} {
		# try to respect i18n, if possible
		if {$okTxt eq ""} {
			if {[catch {set okTxt [mc "Ok"]}]} {
				set okTxt "Ok"
			}
		}

		if {[catch {set cancTxt [mc "Cancel"]}]} {
			set cancTxt "Cancel"
		}

		set btcanc [list $cancTxt "cancel"]
		set btok [list $okTxt "ok"]

		array set bts [list]
		set bts(0) $btcanc
		set bts(1) $btok
	}

	return [::dialogs::alert $w $::dialogs::typeAlertWarning 0 [array get bts] \
		$alertMsg $infoMsg]
}

# ::dialog::info present an information alert, use it when the
# user must know the information presented before continuing,
# or has specifically requested the information.
# Present less important information by other means such as a
# statusbar message.
# By default it contains an information icon, a message,
# its details and an ok button.
#
# @param parent dialog's parent window
# @param alertMsg short simple summary of the error
# @param infoMsg [optional] complete error mesagge and information
#	on how to get out of it
# @param buttons [optional] buttons to be displayed in the dialog;
#	by default one button will be shown (Ok) but you can ovveride
#	this by providing your own configuration (see ::dialogs::alert
#	for detailed info on how to configure buttons).
# @return returns selected button's index.
proc ::dialogs::info {parent alertMsg {infoMsg ""} {buttons ""}} {
	set now [clock seconds]
	if {$parent ne "."} {set parent "$parent."}
	set w $parent$now

	if {$buttons ne ""} {
		if {[catch {array set bts $buttons}]} {
			set buttons ""
		}
	}

	if {$buttons eq ""} {
		# try to respect i18n, if possible
		if {[catch {set okTxt [mc "Ok"]}]} {
			set okTxt "Ok"
		}

		set btok [list $okTxt "ok"]

		array set bts [list]
		set bts(0) $btok
	}

	return [::dialogs::alert $w $::dialogs::typeAlertInfo 0 [array get bts] \
		$alertMsg $infoMsg]
}

# ::dialog::confirmsave present a save confirmation alert.
# Save confirmation alerts help ensure that users do not
# lose document changes when they close applications.
# This makes closing applications a less dangerous operation.
# By default it contains a warning icon, an alert message,
# its details and three buttons: Close without Saving, Cancel
# and Save.
#
# @param parent dialog's parent window
# @param alertMsg short simple summary of the error
# @param infoMsg [optional] complete error mesagge and information
#	on how to get out of it
# @param buttons [optional] buttons to be displayed in the dialog;
#	by default three buttons will be shown but you can ovveride
#	this by providing your own configuration (see ::dialogs::alert
#	for detailed info on how to configure buttons).
# @return returns selected button's index.
proc ::dialogs::confirmsave {parent alertMsg {infoMsg ""} {buttons ""}} {
	set now [clock seconds]
	if {$parent ne "."} {set parent "$parent."}
	set w $parent$now

	if {$buttons ne ""} {
		if {[catch {array set bts $buttons}]} {
			set buttons ""
		}
	}

	if {$buttons eq ""} {
		# try to respect i18n, if possible
		if {[catch {set saveTxt [mc "Save"]}]} {
			set saveTxt "Save"
		}

		if {[catch {set cancTxt [mc "Cancel"]}]} {
			set cancTxt "Cancel"
		}

		if {[catch {set exitTxt [mc "Close without Saving"]}]} {
			set exitTxt "Close without Saving"
		}

		set btexit [list $exitTxt ""]
		set btcanc [list $cancTxt "cancel"]
		set btok [list $saveTxt "document_save"]

		array set bts [list]
		set bts(0) $btexit
		set bts(1) $btcanc
		set bts(2) $btok
	}

	return [::dialogs::alert $w $::dialogs::typeAlertWarning 0 [array get bts] \
		$alertMsg $infoMsg]
}

# ::dialog::auth Authentication alerts prompt the user
# for information necessary to gain access to protected
# resources, such as their username or password.
#
# @param parent dialog's parent window
# @param alertMsg short simple summary of the error
# @param infoMsg [optional] complete error mesagge and information
#	on how to get out of it
# @param userName [optional] default user name to be setted on the user
#	field.
# @param loginTxt [optional] ok button text ("Login" will be the default)
# @param buttons [optional] buttons to be displayed in the dialog;
#	by default two buttons will be shown but you can ovveride
#	this by providing your own configuration (see ::dialogs::alert
#	for detailed info on how to configure buttons).
# @return returns selected button's index.
proc ::dialogs::auth {parent alertMsg {infoMsg ""} {userName ""} {loginTxt ""} {buttons ""}} {
	set now [clock seconds]
	if {$parent ne "."} {set parent "$parent."}
	set w $parent$now

	if {$buttons ne ""} {
		if {[catch {array set bts $buttons}]} {
			set buttons ""
		}
	}

	if {$buttons eq ""} {
		# try to respect i18n, if possible
		if {$loginTxt ne ""} {
			set log $loginTxt
		} else {
			set log "Login"
		}

		if {[catch {set okTxt [mc "$log"]}]} {
			set okTxt "$log"
		}

		if {[catch {set cancTxt [mc "Cancel"]}]} {
			set cancTxt "Cancel"
		}

		set btcanc [list $cancTxt "cancel"]
		set btok [list $okTxt ""]

		array set bts [list]
		set bts(0) $btcanc
		set bts(1) $btok
	}

	set type $::dialogs::typeAlertAuth
	catch {destroy $w}
	set focus [focus]
	set grab [grab current .]
	array set btsa [array get bts]
	array unset bts

	toplevel $w -relief solid -class TkSDialog
	wm title $w ""
	wm iconname $w ""
	wm protocol $w WM_DELETE_WINDOW {#}
	wm transient $w [winfo toplevel [winfo parent $w]]

	set typeValue [lindex $type 0]
	set typeIcon [lindex $type 1]

	::icons::init $::dialogs::iconsTheme
	::icons::createImage $typeIcon $::dialogs::alertIconSize

	set ico [label $w.ico -image $typeIcon]
	set aTxt [message $w.altxt -font $::dialogs::alertFont -text $alertMsg -width 384]
	set iTxt [message $w.intxt -font $::dialogs::infoFont -text $infoMsg -width 384]

	set auth [frame $w.auth]

	if {[catch {set userTxt [mc "Username"]}]} {
		set userTxt "Username"
	}
	if {[catch {set pwdTxt [mc "Password"]}]} {
		set pwdTxt "Password"
	}

	set luser [label $auth.luser -text "$userTxt: "]
	set user [entry $auth.user -bg white -font $::dialogs::alertFont -textvariable ::dialogs::u]
	set lpwd [label $auth.lpwd -text "$pwdTxt: "]
	set pwd [entry $auth.pwd -bg white -font $::dialogs::alertFont -show "·" -textvariable ::dialogs::p]

	grid $luser $user -sticky w -pady 5
	grid $lpwd $pwd -sticky w
	grid configure $luser $lpwd -sticky e

	set bts [frame $w.bts]

	foreach val [lsort [array names btsa]] {
		set curr $btsa($val)
		set txt [lindex $curr 0]
		set icoName [lindex $curr 1]

		if {$icoName ne ""} {
			::icons::createImage $icoName $::dialogs::alertBtnSize
		}

		set bt [button $bts.bt$val -text $txt -compound left \
			-command "\
				set ::dialogs::ret $val;\
				destroy $w\
			"
		]

		if {$icoName ne ""} {
			$bt configure -image $icoName
		}

		bind $bt <Return> {%W invoke}
		grid $bt -column $val -row 0 -padx [list 12 0] -sticky se

		if {$icoName eq ""} {
			grid configure $bt -sticky nse
		}
	}
	grid columnconfigure $bts 0 -weight 1

	# grid elements following guidilens
	# from Apple HIG:
	# http://developer.apple.com/documentation/UserExperience/Conceptual/OSXHIGuidelines/index.html

	grid $ico $aTxt
	grid ^ $iTxt
	grid $auth - -sticky news
	grid $bts - -sticky news

	grid configure $ico -padx [list 24 8] -pady 15 -sticky n
	grid configure $aTxt -padx [list 8 24] -pady [list 15 4] -sticky w
	grid configure $iTxt -padx [list 8 24] -pady [list 4 5] -sticky w
	grid configure $auth -padx 24 -pady 5 -sticky we
	grid configure $bts -padx 24 -pady [list 5 20]

	wm withdraw $w
	update idletasks

	# center the window

	set parent [winfo parent $w]
	set width [winfo reqwidth $w]
	set height [winfo reqheight $w]
	set x [expr { ( [winfo x $parent] + ([winfo reqwidth  $parent] / 2)  - ($width   / 2)) }]
	set y [expr { ( [winfo y $parent] + ([winfo reqheight $parent] / 2)  - ($height /  2)) }]
	if {$y <= 0} {
		set y [winfo y $parent]
	}
	wm geometry $w +${x}+${y}
	update

	wm deiconify $w
	wm resizable $w false false
	tkwait visibility $w
	focus -force $user
	grab $w

	if {$userName ne ""} {
		$user insert 0 $userName
		focus -force $pwd
	}

	tkwait window $w
	
	focus -force $focus
	if {$grab ne ""} {grab $grab}
	update idletasks

	if {$::dialogs::ret == 1} {
		set ret [list "$::dialogs::u" "$::dialogs::p"]
		unset ::dialogs::u
		unset ::dialogs::p
		return $ret
	} else {
		unset ::dialogs::u
		unset ::dialogs::p
		return [list]
	}
}
