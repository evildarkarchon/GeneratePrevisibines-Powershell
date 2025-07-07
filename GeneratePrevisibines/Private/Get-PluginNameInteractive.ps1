function Get-PluginNameInteractive {
    <#
    .SYNOPSIS
    Interactively gets a plugin name from the user with validation.
    
    .DESCRIPTION
    Prompts the user for a plugin name, validates the format, and checks for reserved names.
    Provides helpful guidance and suggestions based on the build mode.
    
    .PARAMETER BuildMode
    The build mode to provide context-appropriate guidance.
    
    .EXAMPLE
    $pluginName = Get-PluginNameInteractive -BuildMode "Clean"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('Clean', 'Filtered', 'Xbox')]
        [string] $BuildMode
    )
    
    Write-Host ""
    Write-Host "Plugin Selection" -ForegroundColor Cyan
    Write-Host "================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Enter the name of the plugin (.esp/.esm/.esl) to process." -ForegroundColor White
    Write-Host "This should be a mod plugin that adds new worldspaces or modifies existing ones." -ForegroundColor White
    Write-Host ""
    
    if ($BuildMode -eq 'Clean') {
        Write-Host "Build Mode: Clean - This will generate both precombines and previs data." -ForegroundColor Green
    }
    elseif ($BuildMode -eq 'Filtered') {
        Write-Host "Build Mode: Filtered - This will skip some optimization steps." -ForegroundColor Yellow
    }
    else {
        Write-Host "Build Mode: Xbox - This will create Xbox-compatible archives." -ForegroundColor Cyan
    }
    
    Write-Host ""
    
    # Reserved plugin names that should not be used
    $reservedNames = @('Fallout4.esm', 'DLCRobot.esm', 'DLCworkshop01.esm', 'DLCCoast.esm', 'DLCworkshop02.esm', 'DLCworkshop03.esm', 'DLCNukaWorld.esm', 'ccBGSFO4001-PipBoy(Black).esl', 'ccBGSFO4002-PipBoy(Blue).esl', 'ccBGSFO4003-PipBoy(Camo01).esl', 'ccBGSFO4004-PipBoy(Camo02).esl', 'ccBGSFO4006-PipBoy(Chrome).esl', 'ccBGSFO4012-PipBoy(Red).esl', 'ccBGSFO4014-PipBoy(White).esl', 'ccBGSFO4016-Prey.esl', 'ccBGSFO4017-Mauler.esl', 'ccBGSFO4018-GaussRiflePrototype.esl', 'ccBGSFO4019-ChineseStealthArmor.esl', 'ccBGSFO4020-PowerArmorSkin(Black).esl', 'ccBGSFO4022-PowerArmorSkin(Camo01).esl', 'ccBGSFO4023-PowerArmorSkin(Camo02).esl', 'ccBGSFO4025-PowerArmorSkin(Chrome).esl', 'ccBGSFO4038-HorseArmor.esl', 'ccBGSFO4039-TunnelSnakes.esl', 'ccBGSFO4041-DoomMarineArmor.esl', 'ccBGSFO4042-BFG.esl', 'ccBGSFO4043-DoomChainsaw.esl', 'ccBGSFO4044-HellfirePowerArmor.esl', 'ccFSVFO4001-ModularMilitaryBackpack.esl', 'ccFSVFO4002-MidCenturyModern.esl', 'ccEEJFO4001-DecorationPack.esl', 'ccBGSFO4045-AdditionalHairColors1.esl', 'ccBGSFO4046-TesMod.esl', 'ccBGSFO4110-WS_Enclave.esl', 'ccBGSFO4115-X02.esl', 'ccBGSFO4116-HeavyFlamer.esl', 'ccBGSFO4124-SchoolAndOfficeKit.esl', 'ccQDRFO4001-CryoGrenade.esl', 'ccQDRFO4002-TeslaCannon.esl', 'ccSBJFO4003-Grenade(Perk).esl', 'ccBGSFO4118-GunRunner.esl', 'ccBGSFO4007-PipBoy(Concrete).esl', 'ccBGSFO4009-PipBoy(FO1).esl', 'ccBGSFO4013-PipBoy(Red-Rocket).esl', 'ccBGSFO4026-PowerArmorSkin(Desert).esl', 'ccBGSFO4024-PowerArmorSkin(Corvega).esl', 'ccBGSFO4027-PowerArmorSkin(Flores).esl', 'ccBGSFO4029-PowerArmorSkin(Shark).esl', 'ccBGSFO4030-PowerArmorSkin(Sprite).esl', 'ccOTMFO4001-Picket Fences.esl', 'ccBGSFO4031-BrahminVariant.esl', 'ccBGSFO4032-DogVariant.esl', 'ccBGSFO4033-MoleratVariant.esl', 'ccBGSFO4034-RadroachVariant.esl', 'ccBGSFO4035-StingwingVariant.esl', 'ccBGSFO4036-BloatflyVariant.esl', 'ccBGSFO4037-RadstagVariant.esl', 'ccBGSFO4040-VaultBoyPerk.esl', 'ccBGSFO4047-QThunderBolt.esl', 'ccBGSFO4048-QArmor.esl', 'ccBGSFO4049-QShock.esl', 'ccBGSFO4050-QCryolator.esl', 'ccBGSFO4051-QGaussRifle.esl', 'ccBGSFO4052-QMinigun.esl', 'ccBGSFO4053-QPlasmaGun.esl', 'ccBGSFO4054-QPlasmaRifle.esl', 'ccBGSFO4055-QGammaGun.esl', 'ccBGSFO4056-QPistol.esl', 'ccBGSFO4057-QAssaultRifle.esl', 'ccBGSFO4058-QCombatRifle.esl', 'ccBGSFO4059-QCombatShotgun.esl', 'ccBGSFO4060-QDoubleBarrel.esl', 'ccBGSFO4061-QFatMan.esl', 'ccBGSFO4062-QFlamer.esl', 'ccBGSFO4063-QHuntingRifle.esl', 'ccBGSFO4064-QLaser.esl', 'ccBGSFO4065-QMissiles.esl', 'ccBGSFO4066-QSubmachine.esl', 'ccBGSFO4067-QSuperSledge.esl', 'ccBGSFO4068-QRadium.esl', 'ccBGSFO4069-QSalvaged.esl', 'ccBGSFO4070-QRailway.esl', 'ccBGSFO4071-QDoorDamage.esl', 'ccBGSFO4072-QAlienBlaster.esl', 'ccBGSFO4073-QHandmadeRifle.esl', 'ccBGSFO4074-QBroadsider.esl', 'ccBGSFO4075-QHarpoon.esl', 'ccBGSFO4076-QJunk.esl', 'ccBGSFO4077-QMelee.esl', 'ccBGSFO4078-QShishkebab.esl', 'ccBGSFO4079-QDeathclaw.esl', 'ccBGSFO4080-QUnarmed.esl', 'ccBGSFO4081-QGrognak.esl', 'ccBGSFO4082-QRecon.esl', 'ccBGSFO4083-QMarine.esl', 'ccBGSFO4084-QT45.esl', 'ccBGSFO4085-QX01.esl', 'ccBGSFO4086-QExcavator.esl', 'ccBGSFO4087-QT51.esl', 'ccBGSFO4088-QRaider.esl', 'ccBGSFO4089-QX02.esl', 'ccBGSFO4090-QFactionCCBoS.esl', 'ccBGSFO4091-QFactionCCInstitute.esl', 'ccBGSFO4092-QFactionCCRailroad.esl', 'ccBGSFO4093-QFactionCCMinutemen.esl', 'ccBGSFO4100-SimSettlements.esl', 'ccBGSFO4101-CamoCombat.esl', 'ccBGSFO4102-ForestCamo.esl', 'ccBGSFO4103-StraightJacket.esl', 'ccBGSFO4104-DiscoFever.esl', 'ccBGSFO4105-WastelandWorkshop.esl', 'ccBGSFO4106-ExtraGuardPosts.esl', 'ccBGSFO4107-SportsFan.esl', 'ccBGSFO4108-TransferSettlements.esl', 'ccBGSFO4109-VaultTecTools.esl', 'ccBGSFO4111-PipCoa.esl', 'ccBGSFO4112-PipQua.esl', 'ccBGSFO4113-PipVal.esl', 'ccBGSFO4114-PipVault.esl', 'ccBGSFO4117-CapCollectorsSuit.esl', 'ccSWKFO4001-AstronautPowerArmor.esl', 'ccSWKFO4002-PipPAD.esl', 'ccKGJFO4001-BasementLiving.esl', 'ccRZRFO4001-TunnelSnakesOutfit.esl', 'ccRZRFO4002-ElianorsOutfit.esl', 'ccRZRFO4003-PotteryWorkshop.esl', 'ccAWNFO4001-brandedattire.esl', 'ccGCJFO4002-Cafe&Diner.esl', 'ccBGSFO4119-ClubsWorkshop.esl', 'ccBGSFO4120-NeonFlames.esl', 'ccTOSFO4001-NeoSkyline.esl', 'ccFRSFO4001-HandmadeShotgun.esl', 'ccGRCFO4001-PipGutsAndGears.esl', 'ccGRCFO4002-PipFantasy.esl', 'ccHRKFO4001-Akuma.esl', 'ccJVDFO4001-Holiday.esl', 'ccKAMFO4001-Noir.esl', 'ccTEMFO4001-WastelandWorkshop.esl', 'ccYESFO4001-AnxietyJacket.esl')
    
    do {
        $pluginName = Read-Host "Plugin name (e.g., MyMod.esp)"
        
        if ([string]::IsNullOrWhiteSpace($pluginName)) {
            Write-Host "Plugin name cannot be empty. Please enter a valid plugin name." -ForegroundColor Red
            continue
        }
        
        # Check format
        if (-not ($pluginName -match '\.(esp|esm|esl)$')) {
            Write-Host "Plugin name must end with .esp, .esm, or .esl extension." -ForegroundColor Red
            continue
        }
        
        # Check for reserved names
        if ($pluginName -in $reservedNames) {
            Write-Host "Cannot use reserved plugin name: $pluginName" -ForegroundColor Red
            Write-Host "Please specify a custom mod plugin, not a base game file." -ForegroundColor Yellow
            continue
        }
        
        # Check for special names
        if ($pluginName -like "*precombine*" -or $pluginName -like "*previs*") {
            $useSpecialName = Show-ConfirmationMenu -Message "Plugin name contains 'precombine' or 'previs'. Are you sure this is correct?" -DefaultOption 'N'
            if (-not $useSpecialName) {
                continue
            }
        }
        
        # Valid plugin name
        Write-Host "Selected plugin: $pluginName" -ForegroundColor Green
        return $pluginName
        
    } while ($true)
}

function Get-InteractiveBuildMode {
    <#
    .SYNOPSIS
    Interactively gets the build mode from the user.
    
    .DESCRIPTION
    Presents build mode options to the user and returns their selection.
    
    .EXAMPLE
    $buildMode = Get-InteractiveBuildMode
    #>
    [CmdletBinding()]
    param()
    
    $buildModeOptions = @(
        @{Key='1'; Description='Clean - Full clean build with all steps (recommended)'},
        @{Key='2'; Description='Filtered - Skip some optimization steps (faster)'},
        @{Key='3'; Description='Xbox - Xbox-compatible build mode'}
    )
    
    $buildModeChoice = Show-InteractiveMenu -Title "Build Mode Selection" -Message "Select build mode" -Options $buildModeOptions -DefaultOption '1'
    
    switch ($buildModeChoice) {
        '1' { return 'Clean' }
        '2' { return 'Filtered' }
        '3' { return 'Xbox' }
    }
}
