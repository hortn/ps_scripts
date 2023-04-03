function save_info_to_xlsx{

$group_name = 'group_name_here'# Задаем переменную с именем группы
$group_member_user = (Get-ADGroupMember -Identity $group_name | Where-Object {$PSItem.objectClass -eq 'user'} ).Name # логины членов группы, где объект - пользователь
$group_member_nested_groups = (Get-ADGroupMember -Identity $group_name | Where-Object {$PSItem.objectClass -eq 'group'} ).Name # логины членов группы, где объект - вложенная группа


$Full_User_info = $group_member_user| # получаем нужные параметры по всем юзерам.
    Get-ADUser -Properties DisplayName, SamAccountName, Department, Division, Title, Enabled  | # в Get-ADUser не указан параметр поиска, т.к. мы передаем из конвейера в первый пазиционный параметр логин(т.е. в -Identity )
        Select-Object -Property DisplayName, SamAccountName, Department, Division, Title, Enabled  | Where-Object {$_.Department -ne $null}  -ErrorAction SilentlyContinue # тут селект и фильтр + SilentlyContinue(т.е. в случае ошибок говорим - заткнись и продожай;) )

$Nested_group_info = $group_member_nested_groups | Get-ADGroup -Properties Description, SamAccountName | Select-Object -Property  Description, SamAccountName
for ($i=0; $i -lt $Nested_group_info.Count; $i++){

  $Nested_group_info[$i] |  Add-Member NoteProperty -Name DisplayName -Value $Nested_group_info[$i].Description

 }

 if($Nested_group_info -ne $null){
 
 $total_group_info = $Full_User_info + $Nested_group_info
 
 }
 else{ 
 
 $total_group_info = $Full_User_info

 }



# если Excel Не установлен, все это работать не будет. Логично же -comobject Excel.Application
$ExcelObj = New-Object -comobject Excel.Application
$ExcelWorkBook = $ExcelObj.Workbooks.Open("C:\temp\group.xlsx") # Вызвали метод Open - открыли файл. файл уже должен быть создан
$ExcelWorkSheet = $ExcelWorkBook.Sheets.Item("AD_User_List") # вот с таким именем листа
# Задаем имена столбцов
$ExcelWorkSheet.Columns.Item(1).Rows.Item(1) = 'Департамент'
$ExcelWorkSheet.Columns.Item(2).Rows.Item(1) = 'Отдел'
$ExcelWorkSheet.Columns.Item(3).Rows.Item(1) = 'ФИО'
$ExcelWorkSheet.Columns.Item(4).Rows.Item(1) = 'Должность'
$ExcelWorkSheet.Columns.Item(5).Rows.Item(1) = 'Логин'
$ExcelWorkSheet.Columns.Item(6).Rows.Item(1) = 'активна?'


# бежим в цикле for по каждому элементу в массиве, пока счетчик $i меньше либо равен кол-ву элементов в $total_group_info
# счетчик $ii - нужен для указания индекса элементов в массиве. $temp 
$ii=0
for($i=2;$i -le $total_group_info.Count;$i++){
$ii++
$temp = $total_group_info[$ii]
$ExcelWorkSheet.Columns.Item(1).Rows.Item($i) = $temp.Department
$ExcelWorkSheet.Columns.Item(2).Rows.Item($i) = $temp.Division
$ExcelWorkSheet.Columns.Item(3).Rows.Item($i) = $temp.DisplayName
$ExcelWorkSheet.Columns.Item(4).Rows.Item($i) = $temp.Title
$ExcelWorkSheet.Columns.Item(5).Rows.Item($i) = $temp.SamAccountName
$ExcelWorkSheet.Columns.Item(6).Rows.Item($i) = $temp.Enabled -replace 'True','УЗ Активна' -replace 'False','УЗ отключена'
}

$ExcelWorkBook.Save() # схоронили файл
$ExcelWorkBook.close($true) # вызвали метод close - закрыть файл

}



function info_to_grid {

$group_name = 'group_name_here' #Задаем переменную с именем группы
$group_member_user = (Get-ADGroupMember -Identity $group_name | Where-Object {$PSItem.objectClass -eq 'user'} ).Name # логины членов группы, где объект - пользователь
$group_member_nested_groups = (Get-ADGroupMember -Identity $group_name | Where-Object {$PSItem.objectClass -eq 'group'} ).Name # логины членов группы, где объект - вложенная группа


$User_info = $group_member_user|
Get-ADUser -Properties DisplayName, SamAccountName, Department, Division, Title, Enabled |
Select-Object -Property DisplayName, SamAccountName, Department, Division, Title, Enabled




$Nested_group_info = $group_member_nested_groups | Get-ADGroup -Properties Description, SamAccountName | Select-Object -Property Description, SamAccountName
for ($i=0; $i -lt $Nested_group_info.Count; $i++){

$Nested_group_info[$i] | Add-Member NoteProperty -Name DisplayName -Value $Nested_group_info[$i].Description

}

if($Nested_group_info -ne $null){

$total_group_info = $User_info + $Nested_group_info

}
else{

$total_group_info = $User_info

}

$total_group_info | Out-GridView -Title $group_name -OutputMode Multiple -ErrorAction SilentlyContinue

}