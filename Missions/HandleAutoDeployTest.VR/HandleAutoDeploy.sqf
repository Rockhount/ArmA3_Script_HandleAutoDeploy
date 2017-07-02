/*
	Made by Rockhount - HandleAutoDeploy Script v1.1 (SP/MP & HC compatible)
	Errors will be written into the rpt and starts with "HandleAutoDeploy Error:"
	Call:
	[["B_HMG_01_A_weapon_F","B_GMG_01_high_F"],["O_HMG_01_high_weapon_F","O_GMG_01_high_F"]] execVM "HandleAutoDeploy.sqf";
	"B_HMG_01_A_weapon_F" = Classname of the backpack
	"B_GMG_01_high_F" = Classname of the static weapon
	
	The backpacks of all existing units get scanned 10 seconds after this script has been called. If the backpack can be
	find in the script parameters, then the unit gets a loop as long as he lives. The unit gets queried wheter or not he
	is in a "COMBAT" Modus. If he is, then he builds automaticly the static weapon with an animation. The static weapon
	will get undeployed only, if the unit is no longer in a "COMBAT" Modus or 10 minutes have elapsed.
	-------------------------------------------------------------------------------------------------------------------------
	Gemacht von Rockhount - HandleAutoDeploy Skript v1.1 (SP/MP & HC Kompatibel)
	Fehler werden in die RPT geschrieben und starten mit "HandleAutoDeploy Error:"
	Aufruf:
	[["B_HMG_01_A_weapon_F","B_GMG_01_high_F"],["O_HMG_01_high_weapon_F","O_GMG_01_high_F"]] execVM "HandleAutoDeploy.sqf";
	"B_HMG_01_A_weapon_F" = Klassenname des des Rucksacks
	"B_GMG_01_high_F" = Klassenname der statischen Waffe
	
	10 Sekunden nachdem der Skript aufgerufen wurde, werden alle Einheiten, die existieren, nach ihrem Rucksack abgefragt.
	Wenn der Rucksack in eines der Skriptparameter zu finden ist, dann bekommt diese Einheit solange sie lebt eine Schleife.
	In der Schleife wird abgefragt, ob sich die Einheit im Kampf befindet. Wenn sie sich im "COMBAT" Modus befindet, dann baut
	sie automatisch mit einer Animation die statische Waffe auf. Die statische Waffe wird erst dann wieder abgebaut, wenn sie sich
	nicht mehr im "COMBAT" Modus befindet oder mindestens 10 Minuten seit dem Aufbau vergangen sind.
*/
if (isServer) then
{
	private _Local_var_Exit = false;
	private _Local_var_Classnames = if ((!isNil "_this") && {typeName _this == "ARRAY"}) then {_this} else {_Local_var_Exit = true;false};
	if (_Local_var_Exit) exitWith
	{
		diag_log "HandleAutoDeploy Error: Wrong parameter";
	};
	if (!canSuspend) exitWith 
	{
		diag_log "HandleAutoDeploy Error: This script does not work in an unscheduled environment";
	};
	sleep 10;
	{
		private _Local_var_Soldier = _x;
		{
			if ((backpack _Local_var_Soldier) == (_x select 0)) exitWith
			{
				[_Local_var_Soldier, _x select 0, _x select 1] spawn
				{
					Params ["_Local_var_Soldier", "_Local_var_BackpackClassname","_Local_var_VehicleClassName"];
					while	{!(isNull _Local_var_Soldier) && {alive _Local_var_Soldier}} do
					{
						waitUntil{sleep 5;!(isNull _Local_var_Soldier) && {alive _Local_var_Soldier} && {(behaviour _Local_var_Soldier) == "COMBAT"}};
						removeBackpackGlobal _Local_var_Soldier;
						[_Local_var_Soldier,"Acts_TerminalOpen"] remoteExec ["switchMove", 0, false];
						sleep 10;
						private _Local_var_Vehicle = createVehicle [_Local_var_VehicleClassName, getPos _Local_var_Soldier, [], 0, "NONE"];
						_Local_var_Vehicle setDir (getDir _Local_var_Soldier);
						_Local_var_Soldier assignAsGunner _Local_var_Vehicle;
						[_Local_var_Soldier,_Local_var_Vehicle] remoteExec ["moveInGunner", _Local_var_Soldier, false];
						_Local_var_Vehicle lock true;
						private _Local_var_Time = time + 600;
						waitUntil{sleep 5; !(isNull _Local_var_Soldier) && {alive _Local_var_Soldier} && {((behaviour _Local_var_Soldier) != "COMBAT") || {time > _Local_var_Time}}};
						if (!(isNull _Local_var_Soldier) && {alive _Local_var_Soldier} && {!isNil "_Local_var_Vehicle"} && {!isNull _Local_var_Vehicle} && {alive _Local_var_Vehicle}) then
						{
							_Local_var_Vehicle lock false;
							private _Local_var_CurDir = getdir _Local_var_Vehicle;
							moveOut _Local_var_Soldier;
							_Local_var_Vehicle lock true;
							[_Local_var_Soldier,"MOVE"] remoteExec ["disableAI", _Local_var_Soldier, false];
							[_Local_var_Soldier,"Acts_TerminalOpen"] remoteExec ["switchMove", 0, false];
							sleep 10;
							[_Local_var_Soldier,_Local_var_BackpackClassname] remoteExec ["addBackpack", _Local_var_Soldier, false];
							deleteVehicle _Local_var_Vehicle;
							[_Local_var_Soldier,""] remoteExec ["switchMove", 0, false];
							[_Local_var_Soldier,"MOVE"] remoteExec ["enableAI", _Local_var_Soldier, false];
						};
					};
				};
			};
		} forEach _Local_var_Classnames;
	} forEach (allUnits - allPlayers - allDeadMen);
};