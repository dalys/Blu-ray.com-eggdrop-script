######################################################################################
# Blu-ray.com script made by dalys that search the website                           #
# http://www.blu-ray.com for movie titles and fetch info                             #
######################################################################################
#
# Bugs/Suggestions/Whatever contact: dalys@chokladboll.se
#
# <dalys> !bluray the dark knight
# <bot> "The Dark Knight (Blu-ray)" Release date: Dec 09, 2008 (Year: 2008  Length: 152 mins Rating: Rated PG-13 Studio: Warner Bros.)
#
# <dalys> !bluray -details the dark knight
# <bot> Details for The Dark Knight (Blu-ray) Video: Video codec: VC-1/Video resolution: 1080p/Aspect ratio: 2.40:1 Audio: English: Dolby TrueHD 5.1/English: Dolby Digital 5.1/English: Dolby Digital 2.0/French: Dolby Digital 5.1 Subs: English SDH, English, French, Spanish Disc: 50GB Blu-ray Disc/Two-disc set/Digital copy
#
#
# Requirements: http.tcl 
#
# Tested on eggdrop 1.6.18 & 1.6.19
#
# 1.2 2010-02-01
# - Blu-ray.com has been updated (with a better search function it seems)
#   and so has the script.
# - Moved the project to github.
#
# 1.1 2008-10-26
# - Fixed a broken regexp due to changes in blu-ray.com's html code
# - Replaced the replacevar function with regsub (replacevar was not part of standard TCL)
#   Thanks to speechles for taking his time and helping out with the above!
#
# 1.0 2008-10-05
# First release.
#
#
# Known issues: 
# - Found one title with the release date set to "2009", which the script will mistake
# for the year the movie was made which is also just four digits.
# 


#### CONFIG ####


# Channels were script can be used (the only config line you HAVE to change)
set bluray_availchans "#chan1 #chan2 #chan3 #chan4"

# Channels were the result will be sent in PM
set bluray_quitechans "#chan2 #chan4"

# Output style
#
# IRC markup: bold = \002, underline = \037, reverse(italic in some clients) =  \026
# Example: %title is coming out \002%releasedate\002!
#
# Normal search (!bluray <title>)
# Variables available: %title %studio %year %releasedate %rating %length
# Default: "\"%title\" Release date: \002%releasedate\002 \(Year: %year Length: %length Rating: %rating Studio: %studio\)"
set bluray_outputstyle "\"%title\" Release date: \002%releasedate\002 \(Year: %year Length: %length Rating: %rating Studio: %studio\)"
#
#
# Detailed search (!bluray -details <title>)
# Variables available: %detailsvideo %detailsaudio %detailssubs %detailsdisc
# Default: "Details for %title \002Video:\002 %detailsvideo \002Audio:\002 %detailsaudio \002Subs:\002 %detailssubs \002Disc:\002 %detailsdisc"
set bluray_detail_outputstyle "Details for %title \002Video:\002 %detailsvideo \002Audio:\002 %detailsaudio \002Subs:\002 %detailssubs \002Disc:\002 %detailsdisc"


# Timeout, in ms (default: "20000")
set bluray_timeout "20000"

# What commands to respond to (default: !bluray !bd !br)

bind pub - !bluray bluray_pub
bind pub - !blu-ray bluray_pub
bind pub - !bd bluray_pub
bind pub - !br bluray_pub


#### END OF CONFIG ####



#### DO NOT EDIT BELOW, UNLESS YOU ACTUALLY KNOW WHAT YOU ARE DOING ####

set bluray_version "1.2"
package require http 

proc bluray_pub {nick uhost hand chan text} {
	global bluray_availchans bluray_quitechans bluray_timeout bluray_outputstyle bluray_detail_outputstyle
	
	set bluray_keywords $text
	set bluray_output $bluray_outputstyle
	set bluray_detail_output $bluray_detail_outputstyle

	if {([lsearch -exact $bluray_availchans $chan] == -1) && ($chan != "privmsg")} {return}
	if {([lsearch -exact $bluray_quitechans $chan] != -1) || ($chan == "privmsg")} {set chan $nick}

	if {[string match $text ""]} {
		puthelp "PRIVMSG $chan :Usage: !bluray \[-details\] <movie title>"
		return
	}
	if {[regexp {^\-details$} [lindex $text 0]] && ![regexp {.+} [lindex $text 1]]} {
                puthelp "PRIVMSG $chan :Usage: !bluray \[-details\] <movie title>"
                return
        } elseif {[regexp {^\-details$} [lindex $text 0]] && [regexp {.+} [lindex $text 1]] } { 
		set bluray_keywords [lrange $text 1 end] 
		} else { set bluray_keywords [lrange $text 0 end] }
 
	
	set bluray_keywords [string map { " " "+" "%" "+" "&" "+" "*" "+" "." "+"} $bluray_keywords]
	
	set bluray_url "http://www.blu-ray.com/search/?quicksearch=1&section=movies&keyword=$bluray_keywords&sortby=popularity"
	catch {set page [::http::geturl $bluray_url -timeout $bluray_timeout]} error
	if {[string match -nocase "*couldn't open socket*" $error]} {
		puthelp "PRIVMSG $chan :Error: Could not open socket to blu-ray.com, please try again later."
		::http::cleanup $page
		return
	}
	if {[::http::status $page] == "timeout" } {
		puthelp "PRIVMSG $chan :Error: Timed out connecting to blu-ray.com, please try again later."
		::http::cleanup $page
		return
	}

	set html [::http::data $page]
	::http::cleanup $page

	set html [string map { "\r\n" "" "\n" "" "\\n" "" } $html]
	
	if {[regexp {<h3>(.*?)</h3></a>} $html match bluray_title] } {

		if {[regexp {^\-details.*$} [lindex $text 0]]} {
		    if {[regexp {</td>\s*<td\swidth=\"85\%\">\s*<a\shref=\"(.{30,100}?)\"\sclass=\"noline\"><h3>} $html match bluray_detailurl]} {

			        catch {set detailpage [::http::geturl $bluray_detailurl -timeout $bluray_timeout]} error
       				if {[string match -nocase "*couldn't open socket*" $error]} {
			                puthelp "PRIVMSG $chan :Error: Could not open socket to blu-ray.com, please try again later."
			                ::http::cleanup $detailpage
			                return
			        }
			        if {[::http::status $detailpage] == "timeout" } {
			                puthelp "PRIVMSG $chan :Error: Timed out connecting to blu-ray.com, please try again later."
			                ::http::cleanup $detailpage
			                return
			        }


			set detailhtml [::http::data $detailpage]
			::http::cleanup $detailpage
			set detailhtml [string map { "\n" "" "\\n" "" } $detailhtml]

			if {[regexp {<h3>Video</h3><br>(.*?)<br>\s*<br>\s*<h3>Audio</h3>} $detailhtml match bluray_detail_video]} {
				set bluray_detail_video [string map {"<br>" "/"} $bluray_detail_video]
				set bluray_detail_video [string trimleft $bluray_detail_video]
				set bluray_detail_video [string trimright $bluray_detail_video]
				set bluray_detail_video [string trimleft $bluray_detail_video /]
                                set bluray_detail_video [string trimright $bluray_detail_video /]
			} else { set bluray_detail_video "N/A" }


			if {[regexp {<div\sid=\"shortaudio\">(.*?)(\s*</div>\s*<div\s*id=\"longaudio\"|\.\.\.\s<a\shref=\"#\")} $detailhtml match bluray_detail_audio]} {
				set bluray_detail_audio [string map {"<br>" "/"} $bluray_detail_audio]
                                set bluray_detail_audio [string trimleft $bluray_detail_audio]
                                set bluray_detail_audio [string trimright $bluray_detail_audio]
                                set bluray_detail_audio [string trimleft $bluray_detail_audio /]
                                set bluray_detail_audio [string trimright $bluray_detail_audio /]

			} else { set bluray_detail_audio "N/A" }


			if {[regexp {<div\sid=\"shortsubs\">(.*?)\s*</div>\s*<div\s*id=\"longsubs\"} $detailhtml match bluray_detail_subs]} {
                                set bluray_detail_subs [string trimleft $bluray_detail_subs]
                                set bluray_detail_subs [string trimright $bluray_detail_subs]

			} else { set bluray_detail_subs "N/A" }



                        if {[regexp {<h3>Disc[s]*</h3><br>(.*?)<br>\s*</td>\s*<td\swidth=\"221px\"} $detailhtml match bluray_detail_disc]} {
                                set bluray_detail_disc [string map {"<br>" "/"} $bluray_detail_disc]
                                set bluray_detail_disc [string trimleft $bluray_detail_disc]
                                set bluray_detail_disc [string trimright $bluray_detail_disc]
                                set bluray_detail_disc [string trimleft $bluray_detail_disc /]
                                set bluray_detail_disc [string trimright $bluray_detail_disc /]

                        } else { set bluray_detail_disc "N/A" }

 
                        regsub -all -nocase "%detailsvideo" $bluray_detail_output $bluray_detail_video bluray_detail_output
                        regsub -all -nocase "%detailsaudio" $bluray_detail_output $bluray_detail_audio bluray_detail_output
                        regsub -all -nocase "%detailssubs" $bluray_detail_output $bluray_detail_subs bluray_detail_output
                        regsub -all -nocase "%title" $bluray_detail_output $bluray_title bluray_detail_output
                        regsub -all -nocase "%detailsdisc" $bluray_detail_output $bluray_detail_disc bluray_detail_output


                        puthelp "PRIVMSG $chan :$bluray_detail_output"



			} else { puthelp "PRIVMSG $chan :Could not fetch the detail url" } 

		} elseif {[regexp {<br><small style=\"color: #666666\">(.*?)</small><br>} $html match bluray_info] } {
			
			set bluray_infosplit [split $bluray_info "|"]


			set bluray_info_year "N/A"
			set bluray_info_studio "N/A"
			set bluray_info_releasedate "N/A"
			set bluray_info_rating "N/A"
			set bluray_info_length "N/A"
			for { set i 0 } { $i < 5 } { incr i } {
				
				set bluray_currentinfo [string trimleft [lindex $bluray_infosplit $i]]
				set bluray_currentinfo [string trimright $bluray_currentinfo]

				if {[regexp {^[0-9]{1,4}$} $bluray_currentinfo]} {
				set bluray_info_year $bluray_currentinfo

				}
				if {[regexp {^[0-9]{1,5}\smins$} $bluray_currentinfo]} {
					set bluray_info_length $bluray_currentinfo
				}
				if {[regexp {((Q[0-9]\s|[A-z]{3}\s[0-9]{2},\s)[0-9]{4}|No\sRelease\sDate)} $bluray_currentinfo]} {
					set bluray_info_releasedate $bluray_currentinfo
				}
				if {[regexp {^.*(R|r)ated.*$} $bluray_currentinfo]} {
					set bluray_info_rating $bluray_currentinfo
				}
				if {![regexp {^[0-9]{4}$} $bluray_currentinfo] && ![regexp {^[0-9]*\smins$} $bluray_currentinfo] && ![regexp {^[A-z]{3}\s[0-9]{1,2},\s[0-9]{4}} $bluray_currentinfo] && ![regexp {^.*(R|r)ated.*$} $bluray_currentinfo] && ![regexp {((Q[0-9]\s|[A-z]{3}\s[0-9]{2},\s)[0-9]{4}|No\sRelease\sDate)} $bluray_currentinfo] && [regexp {[A-z0-9]{2,60}} $bluray_currentinfo]} {
					set bluray_info_studio $bluray_currentinfo
				}
			
			}


			regsub -all -nocase "%title" $bluray_output $bluray_title bluray_output 
			regsub -all -nocase "%studio" $bluray_output $bluray_info_studio bluray_output 
			regsub -all -nocase "%year" $bluray_output $bluray_info_year bluray_output 
			regsub -all -nocase "%length" $bluray_output $bluray_info_length bluray_output 
			regsub -all -nocase "%rating" $bluray_output $bluray_info_rating bluray_output 
			regsub -all -nocase "%releasedate" $bluray_output $bluray_info_releasedate bluray_output


			puthelp "PRIVMSG $chan :$bluray_output"


			} else { puthelp "PRIVMSG $chan :Could not retrieve info about $bluray_title" }

	} else {

	    if {[regexp {alt=\"United\sKingdom\"\stitle=\"United\sKingdom\"\s\/><br><br>(.{100,250}?)<br><br><h5>} $html match bluray_noresult] } {
		    set bluray_noresult [string map {"<b>" "\002" "</b>" "\002"} $bluray_noresult]
                	puthelp "PRIVMSG $chan :$bluray_noresult"
		} else {
               		 puthelp "PRIVMSG $chan :Could not fetch any search result or error message. The script is probably outdated."
	        	}

		}
	

}
	
putlog "Blu-ray.com script $bluray_version by dalys LOADED" 
