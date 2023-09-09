param(
    [string]$path = $pwd, 
    [bool]$recurse = $false
)
if ($recurse) {
    foreach($i in Get-ChildItem -Recurse -Path $path -Filter "*.cpp") {
        $temp = Get-Content $i.fullname
        Out-File -filepath $i.fullname -inputobject $temp -encoding utf8 -force
    }
    foreach($i in Get-ChildItem -Recurse -Path $path -Filter "*.h") {
        $temp = Get-Content $i.fullname
        Out-File -filepath $i.fullname -inputobject $temp -encoding utf8 -force
    }
} else {
    foreach($i in Get-ChildItem -Path $path -Filter "*.cpp") {
        $temp = Get-Content $i.fullname
        Out-File -filepath $i.fullname -inputobject $temp -encoding utf8 -force
    }
    foreach($i in Get-ChildItem -Path $path -Filter "*.h") {
        $temp = Get-Content $i.fullname
        Out-File -filepath $i.fullname -inputobject $temp -encoding utf8 -force
    }
}