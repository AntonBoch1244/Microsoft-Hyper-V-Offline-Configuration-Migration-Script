<# 
.LICENSE
    Microsoft-Hyper-V-Offline-Configuration-Migration-Script
    Copyright (C) 2025  Anton Bochkarev

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <https://www.gnu.org/licenses/>.
#>

Get-VM | ForEach-Object {
    $VIRTUALMACHINE = $_
    "New-VM -Name ""$($VIRTUALMACHINE.Name)"" -MemoryStartupBytes $($VIRTUALMACHINE.MemoryStartup) -Generation $($VIRTUALMACHINE.Generation) -NoVHD -Path ""$($VIRTUALMACHINE.Path)"" -SourceGuestStatePath ""$($VIRTUALMACHINE.GuestStatePath)"" -GuestStateIsolationType $($VIRTUALMACHINE.GuestStateIsolationType)"
    $VMM=Get-VMMemory -VM $VIRTUALMACHINE
    if ($VMM.DynamicMemoryEnabled) {
        "Set-VMMemory -VMName ""$($VIRTUALMACHINE.VMName)"" -DynamicMemoryEnabled $"+$VMM.DynamicMemoryEnabled.ToString().ToLower()+" -HugePagesEnabled $"+$VMM.HugePagesEnabled.ToString().ToLower()+" -StartupBytes $($VMM.Startup) -MaximumBytes $($VMM.Maximum) -MinimumBytes $($VMM.Minimum)"
    } else {
        "Set-VMMemory -VMName ""$($VIRTUALMACHINE.VMName)"" -DynamicMemoryEnabled $"+$VMM.DynamicMemoryEnabled.ToString().ToLower()+" -HugePagesEnabled $"+$VMM.HugePagesEnabled.ToString().ToLower()+" -StartupBytes $($VMM.Startup)"
    }
    $VMCPU=Get-VMProcessor -VM $VIRTUALMACHINE
    "Set-VMProcessor -VMName ""$($VIRTUALMACHINE.VMName)"" -Count $($VMCPU.Count) -Maximum $($VMCPU.Maximum) -Reserve $($VMCPU.Reserve)" 
    "Remove-VMNetworkAdapter -VMName ""$($VIRTUALMACHINE.VMName)"""
    $VIRTUALMACHINE.NetworkAdapters | ForEach-Object {
        $VIRTUALMACHINENETWORKADAPTER = $_
        if ($VIRTUALMACHINENETWORKADAPTER.DynamicMacAddressEnabled) {
            "Add-VMNetworkAdapter -VMName ""$($VIRTUALMACHINE.VMName)"" -IsLegacy "+"$"+"$($VIRTUALMACHINENETWORKADAPTER.IsLegacy.ToString().ToLower()) -Name ""$($VIRTUALMACHINENETWORKADAPTER.Name)"" -NumaAwarePlacement "+"$"+"$($VIRTUALMACHINENETWORKADAPTER.NumaAwarePlacement.ToString().ToLower()) -ResourcePoolName ""$($VIRTUALMACHINENETWORKADAPTER.PoolName)"" -SwitchName ""$($VIRTUALMACHINENETWORKADAPTER.SwitchName)"" -DynamicMacAddress"
        } else {
            "Add-VMNetworkAdapter -VMName ""$($VIRTUALMACHINE.VMName)"" -IsLegacy "+"$"+"$($VIRTUALMACHINENETWORKADAPTER.IsLegacy.ToString().ToLower()) -Name ""$($VIRTUALMACHINENETWORKADAPTER.Name)"" -NumaAwarePlacement "+"$"+"$($VIRTUALMACHINENETWORKADAPTER.NumaAwarePlacement.ToString().ToLower()) -ResourcePoolName ""$($VIRTUALMACHINENETWORKADAPTER.PoolName)"" -StaticMacAddress ""$($VIRTUALMACHINENETWORKADAPTER.MacAddress)"" -SwitchName ""$($VIRTUALMACHINENETWORKADAPTER.SwitchName)"""
        }
        "$"+"NA=(Get-VMNetworkAdapter -VMName ""$($VIRTUALMACHINE.VMName)"")[-1]"
        if ($VIRTUALMACHINENETWORKADAPTER.VlanSetting.OperationMode -eq [Microsoft.HyperV.PowerShell.VMNetworkAdapterVlanMode]::Untagged) {
            "Set-VMNetworkAdapterVlan -VMNetworkAdapter $"+"NA -Untagged"
        } else {
            "Set-VMNetworkAdapterVlan -VMNetworkAdapter $"+"NA -VlanId $($VIRTUALMACHINENETWORKADAPTER.VlanSetting.AccessVlanId) -Access"
        }
    }
    if ($VIRTUALMACHINE.Generation -eq 1) {
        "Remove-VMDvdDrive -VMName ""$($VIRTUALMACHINE.VMName)"" -ControllerLocation 0 -ControllerNumber 1"
    }
    "Remove-VMScsiController -ControllerNumber 0 -VMName ""$($VIRTUALMACHINE.VMName)"""
    Get-VMScsiController -VM $VIRTUALMACHINE | ForEach-Object {
        "Add-VMScsiController -VMName ""$($VIRTUALMACHINE.VMName)"""
    }
    Get-VMDvdDrive -VM $VIRTUALMACHINE | ForEach-Object {
        $VMDVDDRIVE = $_
        "Add-VMDvdDrive -VMName ""$($VIRTUALMACHINE.VMName)"" -ControllerLocation $($VMDVDDRIVE.ControllerLocation) -ControllerNumber $($VMDVDDRIVE.ControllerNumber)"
    }
    Get-VMHardDiskDrive -VM $VIRTUALMACHINE | ForEach-Object {
        $VMHDD = $_
        "Add-VMHardDiskDrive -VMName ""$($VIRTUALMACHINE.VMName)"" -ControllerLocation $($VMHDD.ControllerLocation) -ControllerNumber $($VMHDD.ControllerNumber) -Path ""$($VMHDD.Path)"""
    }
    if ($VIRTUALMACHINE.Generation -eq 2) {
        $VMF = Get-VMFirmware -VM $VIRTUALMACHINE
        "Set-VMFirmware -VMName ""$($VIRTUALMACHINE.VMName)"" -EnableSecureBoot "+$VMF.SecureBoot.ToString().ToLower()+" -SecureBootTemplate ""$($VMF.SecureBootTemplate)"""
    }
} | Out-File -FilePath "C:\migrate.ps1"
