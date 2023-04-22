$sb = {
	$members = 'city_road\Advatek-group'
    #Add-LocalGroupMember -Group 'Performance Monitor Users' -Member $members
    Add-LocalGroupMember -Group 'Administrators' -Member $members
    #Remove-LocalGroupMember -Group 'Administrators' -Member $members
}

#Invoke-Command -ScriptBlock $sb -Computername M019989, M015510, M014730, M017526, Mo19991, M017474

Invoke-Command -ScriptBlock $sb -Computername MEHFORUM, MEHSAN3, MEHSAN4, MEHHEYEX, MEHIMAGENET6