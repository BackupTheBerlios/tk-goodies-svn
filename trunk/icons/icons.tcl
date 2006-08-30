#    Copyright (C) 2006 Matteo 'bugant' Centenaro
#
#    This program is free software; you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation; either version 2 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program (probably in a file named "LICENSE");
#    if not, write to:
#
#    Free Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

package require Img
package require xml

namespace eval ::icons {
	variable library [file dirname [info script]]
	variable version 0.1

	variable array icons
	variable basedir
	variable theme
	variable confFile "icons.xml"
}

package provide icons $::icons::version

# init icons
#
# @param theme icons' theme name
# @param conf [optional] path to the configuration file
# @return returns 0 on success; -1 on error.
proc ::icons::init {theme {conf ""}} {
	set ::icons::theme $theme
	if {$conf eq ""} {
		set conf [file join $::icons::library $::icons::confFile]
	}

	set parser [::xml::parser -elementstartcommand ::icons::startTag]
	set fconf [open $conf]
	$parser parse [read $fconf]
	close $fconf

	if {![file isdirectory $::icons::basedir]} {
		puts "bad icon theme '$theme': cannot find directory $::icons::basedir"
		return -1
	}

	return 0
}

proc ::icons::createImage {name size} {
	set path $::icons::icons($name)
	set path [file join $::icons::basedir $size $path]
	if {[catch {image create photo $name -file $path} err]} {
		puts "Couldn't create icon $name from file $path: $err"
		# let's get the default icon
		if {[catch {image create photo $name -file [file join $::icons::basedir $size $::icons::icons(image_missing)]} err]} {
			puts "Couldn't load the default missing icon, too bad."
			return -1
		}
	}
	return
}

# ::icons::initTheme clear all previous settings
# to let you strat loading a new theme
proc ::icons::_init {} {
	# clear path
	set ::icons::basedir ""

	# clear old icons
	array unset ::icons::icons
	array set ::icons::icons [list]
}

# procs used to parse xml config file
proc ::icons::startTag {name attlist args} {
	switch -exact -- $name {
		"icons" {
			::icons::conf $attlist $args
		}
		"icon" {
			::icons::parseIcon $attlist $args
		}
	}
}

# configure icons settings
proc ::icons::conf {attlist args} {
	foreach [list name value] $attlist {
		switch -exact -- $name {
			"basedir" {
				set ::icons::basedir [string trim $value]
				if {[string range $::icons::basedir 0 0] ne "/"} {
					set ::icons::basedir [file join $::icons::library $::icons::basedir]
				}
				set ::icons::basedir [file join $::icons::basedir $::icons::theme]
			}
		}
	}
}

# read configuration for an icon
proc ::icons::parseIcon {attlist args} {
	set iconName ""
	set iconContext ""
	set iconImg ""
	
	foreach [list name value] $attlist {
		switch -- $name {
			"name" {
				set iconName [string trim $value]
			}
			"context" {
				set iconContext [string trim $value]
			}
			"img" {
				set iconImg $value
			}
		}
	}

	set ::icons::icons($iconName) [file join $iconContext $iconImg]
}
