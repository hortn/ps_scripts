function get_acc_state {
param ([array]
[ValidateNotNullorEmpty()]
[parameter(mandatory = $true)]
$user
)

$acc_info = $user |Get-ADUser -Properties * | Select-Object Enabled, LockedOut, SamAccountName

foreach ($temp in $acc_info){

if ($temp.Enabled -ne $true){
[array]$info += "$($temp.SamAccountName) -disabled"
}

elseif ($temp.LockedOut){
[array]$info += "$($temp.SamAccountName) -locked"
}

else{
[array]$info += "$($temp.SamAccountName) -OK"
}
}
return $info
}




#example
get_acc_state user1, user2, user3, user...n

#or use array in first param