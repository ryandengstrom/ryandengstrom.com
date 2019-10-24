$OS = "Win10"

$HPModelsTable= @(
        @{ ProdCode = '1998'; Model = "HP EliteDesk 800 G1 SFF"; OSVER = 1803 }
        @{ ProdCode = '829A'; Model = "HP EliteDesk 800 G3 DM 35W"; OSVER = 1803 }
        @{ ProdCode = '8299'; Model = "HP EliteDesk 800 G3 SFF"; OSVER = 1803 }
        @{ ProdCode = '837B'; Model = "HP ProBook 440 G5"; OSVER = 1803 }
        @{ ProdCode = '2101'; Model = "HP ProBook 640 G1"; OSVER = 1803 }
        @{ ProdCode = '80FD'; Model = "HP ProBook 640 G2"; OSVER = 1803 }
        @{ ProdCode = '818F'; Model = "HP ProBook 11 G2"; OSVER = 1803 }
        @{ ProdCode = '8537'; Model = "HP ProBook 440 G6"; OSVER = 1803 }
        @{ ProdCode = '8521'; Model = "HP ProBook x360 11 G3 EE"; OSVER = 1803 }
        )

foreach ($Model in $HPModelsTable) {
$CurrentBIOSRevision = Get-SoftpaqList -os $OS -osver $($Model.OSVER) -category BIOS -platform $($Model.ProdCode) | select Version
Write-Output "Model: $($Model.Model) Current BIOS Revision: $CurrentBIOSRevision"
}