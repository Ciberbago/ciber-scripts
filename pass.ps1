$usuario = Read-Host "Escribe el nombre de usuario"
Set-MsolUserPassword -UserPrincipalName $usuario"@distribucionessantacruz.com" -NewPassword "INICIO123!"