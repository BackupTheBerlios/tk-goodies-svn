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
	set name [string trim $name]
	set size [string trim $size]

	set path $::icons::icons($name)
	set path [file join $::icons::basedir $size $path]
	set name "$name$size"
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
