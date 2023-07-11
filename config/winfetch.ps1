# https://github.com/JaMo42/winfetch

# Settings
# Text colors
$normalcolor = "Gray"
$usercolor = "Blue"
$labelcolor = "Blue"
$infocolor = "Gray"
# Logo colors
$red = "Red"
$green = "Green"
$blue = "Blue"
$yellow = "Yellow"

function get-uptime {
  # Subtract time of last boot from current time
  $uptime = (
    (Get-CimInstance -ClassName Win32_OperatingSystem).LocalDateTime - 
    (Get-CimInstance -ClassName Win32_OperatingSystem).LastBootUpTime
  );
  # Format
  $formatted = ""
  if ($uptime.Days -ne 0) {
    $formatted += $uptime.Days.ToString() + "d ";
  }
  if ($uptime.Hours -ne 0) {
    $formatted += $uptime.Hours.ToString() + "h ";
  }
  $formatted += $uptime.Minutes.ToString() + "m";
  return $formatted;
}

function get-packages {
"$($(choco list --local-only -r).Count) (choco)"
"$($((scoop list).Count)) (scoop)"
}

[string]$user = $env:UserName;
[string]$hostname = $env:ComputerName;
[string]$os = (Get-CimInstance -ClassName Win32_OperatingSystem).Caption.Replace("Microsoft ", "")
[string]$kernel = (Get-CimInstance -ClassName  Win32_OperatingSystem).BuildNumber;
[string]$uptime = get-uptime;
[string]$packages = get-packages;
[string]$shell = "Powershell $($PSVersionTable.PSVersion.ToString())";

# Output:
#       _.-;;-._    user@host
#'-..-'|   ||   |   OS: ...
#'-..-'|_.-;;-._|   Kernel: ...
#'-..-'|   ||   |   Uptime: ...
#'-..-'|_.-''-._|   Packages: ... (choco)
#                   Shell: Powershell ...
[string[][]]$text =
  ("        _.-;", ";-._    ",         $user, "@", $hostname),
  (" '-..-'|   |", "|   |   ",         "os      💾 ", $os),
  (" '-..-'|_.-", ",", ",", "-._|   ", "kernel  📀 ", $kernel),
  (" '-..-'|   |", "|   |   ",         "uptime  ⌛ ", $uptime),
  (" '-..-'|_.-'", "'-._|   ",         "pkg     📦 ", $packages),
  ("                    ",             "shell   💻 ", $shell);
[string[][]]$colors =
  ($red, $green,                 $usercolor, $normalcolor, $usercolor),
  ($red, $green,                 $labelcolor, $infocolor),
  ($red, $blue, $yellow, $green, $labelcolor, $infocolor),
  ($blue, $yellow,               $labelcolor, $infocolor),
  ($blue, $yellow,               $labelcolor, $infocolor),
  ($normalcolor,                 $labelcolor, $infocolor);

Write-Host;
for ($line=0; $line -lt $text.Count; $line++) {
  for ($element=0; $element -lt $text[$line].Count; $element++) {
    Write-Host $text[$line][$element] -ForegroundColor $colors[$line][$element] -NoNewline;
  }
  Write-Host;
}
Write-Host;