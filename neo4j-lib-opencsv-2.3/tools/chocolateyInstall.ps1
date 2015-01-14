$PackageName = 'neo4j-lib-opencsv'
$TempDir = "$($Env:Temp)\opencsvtemp"
try {
  # Get the NeoHome Dir
  #   Try the local environment
  $neoHome = [string] (Get-EnvironmentVariable -Name 'NEO4J_HOME' -Scope 'Machine')  
  # Failing that, try a registry hack
  if ($neoHome -eq '')
  {
    $neoHome = [string] ( (Get-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Environment' -ErrorAction Ignore).'NEO4J_HOME' )
  }
  if ($neoHome -eq '') { throw "Could not find the Neo4jHome directory" }

  $InstallDir = "$($neoHome)\lib"
  
  $TempDir = "$($Env:Temp)\opencsvtemp"
  if (Test-Path -Path $TempDir) {
    Remove-Item -Path $TempDir -Force -Recurse -Confirm:$false | Out-Null
  }

  # Check if we should restart Neo
  $packageParameters = ([string]($env:chocolateyPackageParameters)).Trim()
  $DoServiceRestart = ($packageParameters.ToUpper() -eq "RESTARTSERVICE")
  if ($DoServiceRestart) { Write-Debug 'Found RestartService package parameter.  Neo4j service will be restarted at the end of the installation' }

  # Extract jar file
  Install-ChocolateyZipPackage -PackageName $PackageName -URL 'http://www.java2s.com/Code/JarDownload/opencsv/opencsv-2.3.jar.zip' -UnzipLocation $TempDir `
                               -CheckSum 'b2f00efd9b91c1d6f69d982bbc661554' -CheckSumType 'md5'

  $jarFile = "opencsv-2.3.jar"
  if (!(Test-Path -Path "$($TempDir)\$($jarFile)")) { Throw "Could not find the jar file within the zip archive" }
  
  Copy-Item -Path "$($TempDir)\$($jarFile)" -Destination "$($InstallDir)\$($jarFile)" -Confirm:$false -Force | Out-Null
  
  # Cleanup
  Remove-Item -Path $TempDir -Force -Recurse -Confirm:$false -ErrorAction Ignore | Out-Null
  
  # Restart Neo
  if ($DoServiceRestart) 
  {
    Write-Debug "Restarting Neo4j..."
    Get-Service 'Neo4j-Server' -ErrorAction Ignore | Restart-Service -Force -ErrorAction Ignore | Out-Null
  }

  Write-ChocolateySuccess $PackageName
} catch {
  Write-ChocolateyFailure $PackageName "$($_.Exception.Message)"

  Remove-Item -Path $TempDir -Force -Recurse -Confirm:$false -ErrorAction Ignore | Out-Null
  throw
}

