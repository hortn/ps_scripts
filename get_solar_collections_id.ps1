function get_cred {

    $cred = Get-Credential -Message "Давайте введем логин и пароль для аутентификации, при обращении к серверу SOLAR"
    if ($null -eq $cred) {
        Write-Host "Вы не ввели логин и пароль!!! Давайте еще разок. " -ForegroundColor Red -BackgroundColor Black
        Write-Host "Нажмите enter чтобы попробовать еще раз или закройте окно для выхода" -ForegroundColor Red -BackgroundColor Black
        pause
        get_cred
    }
    try {
        $auth = $cred.UserName + ':' + $cred.GetNetworkCredential().Password
        $encoded = [System.Text.Encoding]::UTF8.GetBytes($auth)
        $auth_info = [System.Convert]::ToBase64String($encoded)
        $Global:headers = @{"Authorization" = "Basic $($auth_info)" }
        [bool]$Global:CredOn = $true
    
    }
    
    catch {
    
        Write-Host "Что-то пошло ни так. Проверьте правильно ли вы вводите логин\пароль" -ForegroundColor Red -BackgroundColor Black
        Write-Host "Нажмите enter чтобы попробовать еще раз или закройте окно для выхода" -ForegroundColor Red -BackgroundColor Black
        pause
        get_cred
    }
    
    
}
    
    
function get_collections_counts {
    param (
        [switch]$text,
        [switch]$attributes
    )
    
    if ($text.IsPresent) {
        $collection = "text"
    }
    
    elseif ($attributes.IsPresent) {
        $collection = "attributes"
    }
    
    $json_count = (Invoke-WebRequest -Uri "https://solar_host:8983/solr/$collection/select?indent=true&q.op=OR&q=*%3A*&rows=0" -Method Get -Headers $Global:headers).content
    $obj_count = ConvertFrom-Json $json_count
    return $obj_count.response.numFound
    
    
    
}
    
Function get_collection_item {
    param (
        [switch]$text,
        [switch]$attributes
    )
    
    if ($text.IsPresent) {
        $collection = "text"
        $outfile = "C:\temp\call_id_text"
    }
    
    elseif ($attributes.IsPresent) {
        $collection = "attributes"
        $outfile = "C:\temp\call_id_attributes"
    }
    
    $item_count = get_collections_counts $collection
    
    for ($i = 0; $i -lt $item_count; $i += 1000000) {
    
        $json = (Invoke-WebRequest -Uri "https://solar_host:8983/solr/text/select?fl=call_id&indent=true&q.op=OR&q=*%3A*&rows=1000000&start=$i" -Method Get -Headers $headers).content
        $obj = ConvertFrom-Json $json
        $obj.response.docs.call_id | Out-File $outfile -Append
    
    
        Clear-Variable -Name "json", "obj"
        [System.GC]::Collect()
        start-sleep -Seconds 10
    }
    
}
    
function get_started {
    
    
    
    if ($Global:CredOn -ne $true) {
        Write-Host "Давайте введем логин и пароль для аутентификации, при обращении к серверу SOLAR" -ForegroundColor Green
        get_cred
    }
    
    Write-Host "__________Что хотите сделать?__________"
    Write-Host "1. - Посмотреть кол-во записей в коллекциях 'text' и 'attributes'."
    Write-Host "2. - Выгрузить в файл все id из коллекции 'text'."
    Write-Host "3. - Выгрузить в файл все id из коллекции 'attributes'."
    Write-Host "4. - Выгрузить в файл все id из коллекций 'text' и 'attributes'."
    Write-Host "5. - Выход."
    
    Switch (Read-Host "Выбрали? Введите значение!") {
        1 {
            Write-Host "Коллекция 'text':" -ForegroundColor Green
            get_collections_counts -text
            Write-Host "Коллекция 'attributes':" -ForegroundColor Green
            get_collections_counts -attributes
            start-sleep -Seconds 3
            get_started 
        }
    
        2 {
            Write-Host "Начинаем выгрузку коллекции 'text'. Дождитесь сообщения о завершении."
            get_collection_item -text
            Write-Host "Выгрузка завершена. Файл расположен тут - 'C:\temp\call_id_text'. " -ForegroundColor Green
            start-sleep -Seconds 3
            get_started 
        }
    
        3 {
            Write-Host "Начинаем выгрузку коллекции 'attributes'.. Дождитесь сообщения о завершении."
            get_collection_item -attributes
            Write-Host "Выгрузка завершена. Файл расположен тут - 'C:\temp\call_id_attributes'. " -ForegroundColor Green
            start-sleep -Seconds 3
            get_started 
        }
    
        4 {
            Write-Host "Начинаем выгрузку коллекции 'text'. Дождитесь сообщения о завершении."
            get_collection_item -text
            Write-Host "Выгрузка завершена. Файл расположен тут - 'C:\temp\call_id_text'. " -ForegroundColor Green
            start-sleep -Seconds 10
            Write-Host "Начинаем выгрузку коллекции 'attributes'.. Дождитесь сообщения о завершении."
            get_collection_item -attributes
            Write-Host "Выгрузка завершена. Файл расположен тут - 'C:\temp\call_id_attributes'." -ForegroundColor Green
            start-sleep -Seconds 10
            get_started 
        }
    
        5 { break }
    
        default { Write-Host "Введите корректное значение" -ForegroundColor Red; get_started }
    }
    
    
}
    
    
get_started